<#
.SYNOPSIS
  Take The Seventh Shadow's extras out again. Pick another theme in Settings > Personalization > Themes first;
  Windows will not delete the theme that is in use.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
#>
[CmdletBinding()]
param([switch]$KeepTitleBarAccent)
$ErrorActionPreference = 'Stop'

$fragDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\TheSeventhShadow'
if (Test-Path $fragDir) { Remove-Item $fragDir -Recurse -Force; Write-Host 'terminal    fragment removed' }

$ffDir = Join-Path $HOME '.config\fastfetch'
$cfg = Join-Path $ffDir 'config.jsonc'
if ((Test-Path $cfg) -and (Select-String -Path $cfg -SimpleMatch 'The Seventh Shadow' -Quiet)) {
  if (Test-Path "$cfg.bak") { Move-Item "$cfg.bak" $cfg -Force; Write-Host 'fastfetch   previous config restored' }
  else { Remove-Item $cfg; Write-Host 'fastfetch   config removed' }
  Remove-Item (Join-Path $ffDir 'seventh-shadow-crest.txt') -ErrorAction SilentlyContinue
}

if (-not $KeepTitleBarAccent) {
  Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name ColorPrevalence -Value 0 -Type DWord
  Write-Host 'title bars  accent off'
}

$themeDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Themes\TheSeventhShadow'
$current = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes' -ErrorAction SilentlyContinue).CurrentTheme
if ($current -and $current -like "$themeDir*") {
  Write-Host 'theme       still in use: choose another theme in Settings, then run this again to delete the pictures'
} elseif (Test-Path $themeDir) {
  Remove-Item $themeDir -Recurse -Force
  Write-Host 'theme       pictures and theme file removed'
}
Write-Host 'The lock screen picture stays until you choose another one in Settings > Personalization > Lock screen.'
