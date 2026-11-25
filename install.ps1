<#
.SYNOPSIS
  Install The Seventh Shadow on Windows 10/11 for the current user. No admin rights needed.

.DESCRIPTION
  - copies the seven 4K stills to %LOCALAPPDATA%\Microsoft\Windows\Themes\TheSeventhShadow\DesktopBackground
    (the same place Windows unpacks TheSeventhShadow.deskthemepack) and applies the theme: dark mode, vein cyan
    accent, the stills as a slideshow that moves on every ten minutes;
  - shows the accent on title bars and window borders, the Windows cousin of the vein-to-gold Hyprland border;
  - puts 1-storm on the lock screen;
  - adds a "The Seventh Shadow" colour scheme and profile to Windows Terminal (a fragment; settings.json is not
    touched);
  - with -Fastfetch, puts the crest and the band's fastfetch panel in ~/.config/fastfetch (an existing config is
    kept as config.jsonc.bak).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -NoLockScreen -NoTitleBarAccent -Fastfetch
#>
[CmdletBinding()]
param(
  [switch]$NoLockScreen,
  [switch]$NoTitleBarAccent,
  [switch]$NoTerminal,
  [switch]$Fastfetch,
  [string]$LockScreenImage = '1-storm.jpg'
)
$ErrorActionPreference = 'Stop'

# The lock screen goes through WinRT, which only Windows PowerShell 5.1 can call. Re-run there from pwsh.
if ($PSVersionTable.PSEdition -eq 'Core') {
  $argv = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)
  foreach ($p in $PSBoundParameters.GetEnumerator()) {
    if ($p.Value -is [System.Management.Automation.SwitchParameter]) { if ($p.Value) { $argv += "-$($p.Key)" } }
    else { $argv += "-$($p.Key)"; $argv += "$($p.Value)" }
  }
  & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" @argv
  exit $LASTEXITCODE
}

$here = Split-Path -Parent $PSCommandPath
$themeDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Themes\TheSeventhShadow'
$bgDir = Join-Path $themeDir 'DesktopBackground'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Say($what, $how) { Write-Host ('{0,-12}' -f $what) -ForegroundColor Cyan -NoNewline; Write-Host $how }

# 1. Pictures and theme -----------------------------------------------------------------------------------------
$stills = Get-ChildItem (Join-Path $here 'DesktopBackground') -Filter *.jpg
if ($stills.Count -ne 7) { throw "expected 7 pictures in $here\DesktopBackground, found $($stills.Count)" }
New-Item -ItemType Directory -Force -Path $bgDir | Out-Null
$stills | Copy-Item -Destination $bgDir -Force
$themeFile = Join-Path $themeDir 'TheSeventhShadow.theme'
Copy-Item (Join-Path $here 'TheSeventhShadow.theme') $themeFile -Force

# Opening a .theme file applies it (Settings opens on Personalization > Themes while it does).
Start-Process -FilePath $themeFile
Start-Sleep -Seconds 4
Say 'theme' 'applied: dark mode, vein accent, slideshow every 10 minutes'

# 2. Accent on title bars and window borders --------------------------------------------------------------------
if (-not $NoTitleBarAccent) {
  Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name ColorPrevalence -Value 1 -Type DWord
  Say 'title bars' 'vein accent on title bars and window borders'
}

# 3. Lock screen -----------------------------------------------------------------------------------------------
if (-not $NoLockScreen) {
  try {
    $img = Join-Path $bgDir $LockScreenImage
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    [void][Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
    [void][Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]
    $ext = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
      $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
    $asTaskOp = $ext | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } |
      Select-Object -First 1
    $asTaskAction = $ext | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } |
      Select-Object -First 1
    $op = [Windows.Storage.StorageFile]::GetFileFromPathAsync($img)
    $task = $asTaskOp.MakeGenericMethod([Windows.Storage.StorageFile]).Invoke($null, @($op))
    $task.Wait(-1) | Out-Null
    $set = $asTaskAction.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($task.Result)))
    $set.Wait(-1) | Out-Null
    Say 'lock screen' $LockScreenImage
  } catch {
    Say 'lock screen' "skipped ($($_.Exception.Message)); set it in Settings > Personalization > Lock screen"
  }
}

# 4. Windows Terminal ------------------------------------------------------------------------------------------
if (-not $NoTerminal) {
  $shell = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe -NoLogo' } else { 'powershell.exe -NoLogo' }
  $json = [IO.File]::ReadAllText((Join-Path $here 'terminal\seventh-shadow.json'), $utf8)
  # A Nerd Font if one is installed, so the fastfetch icons draw; Cascadia Mono otherwise.
  $font = 'Cascadia Mono'
  $fontFiles = @(Get-ChildItem "$env:WINDIR\Fonts", "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter *.ttf -ErrorAction SilentlyContinue)
  foreach ($nf in @('CaskaydiaCove Nerd Font', 'CaskaydiaMono Nerd Font', 'JetBrainsMono Nerd Font', 'FiraCode Nerd Font')) {
    if ($fontFiles | Where-Object { $_.Name -like "$($nf -replace ' ', '')*" }) { $font = $nf; break }
  }
  $json = $json.Replace('__FONT__', $font)
  $json = $json.Replace('__SHELL__', $shell).Replace('__BACKGROUND__', ((Join-Path $bgDir '6-portrait.jpg') -replace '\\', '/'))
  $fragDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\TheSeventhShadow'
  New-Item -ItemType Directory -Force -Path $fragDir | Out-Null
  [IO.File]::WriteAllText((Join-Path $fragDir 'seventh-shadow.json'), $json, $utf8)
  Say 'terminal' 'scheme and profile "The Seventh Shadow" (restart Windows Terminal to see them)'
}

# 5. fastfetch -------------------------------------------------------------------------------------------------
if ($Fastfetch) {
  $ffDir = Join-Path $HOME '.config\fastfetch'
  New-Item -ItemType Directory -Force -Path $ffDir | Out-Null
  $crest = Join-Path $ffDir 'seventh-shadow-crest.txt'
  Copy-Item (Join-Path $here 'fastfetch\crest.txt') $crest -Force
  $cfg = Join-Path $ffDir 'config.jsonc'
  if ((Test-Path $cfg) -and -not (Test-Path "$cfg.bak")) { Copy-Item $cfg "$cfg.bak" }
  $text = [IO.File]::ReadAllText((Join-Path $here 'fastfetch\config.jsonc'), $utf8)
  [IO.File]::WriteAllText($cfg, $text.Replace('__CREST__', ($crest -replace '\\', '/')), $utf8)
  $note = if (Get-Command fastfetch -ErrorAction SilentlyContinue) { 'run fastfetch' } else { 'install it: winget install fastfetch' }
  Say 'fastfetch' "crest panel in place; $note (needs a Nerd Font for the icons)"
}

Write-Host ''
Write-Host 'The Seventh Shadow is in. Alienation By Design.' -ForegroundColor DarkGray
