<#
.SYNOPSIS
  Build dist\TheSeventhShadow.deskthemepack (double-click to install the theme and wallpapers) and
  dist\TheSeventhShadow-Windows.zip (the pack plus install.ps1 and the extras).

.PARAMETER From
  Path to a checkout of c0ze/omarchy-the-seventh-shadow-theme. When given, the stills are copied fresh from its
  backgrounds/ folder first, so the two themes stay in step.

.EXAMPLE
  .\build.ps1 -From ..\omarchy-the-seventh-shadow-theme
#>
[CmdletBinding()]
param([string]$From)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
Push-Location $here
try {
  if ($From) {
    Get-ChildItem (Join-Path $From 'backgrounds') -Filter *.jpg | Copy-Item -Destination 'DesktopBackground' -Force
  }
  $stills = Get-ChildItem 'DesktopBackground' -Filter *.jpg | Sort-Object Name
  if ($stills.Count -ne 7) { throw "expected 7 pictures in DesktopBackground, found $($stills.Count)" }

  $dist = Join-Path $here 'dist'
  New-Item -ItemType Directory -Force -Path $dist | Out-Null
  Remove-Item (Join-Path $dist '*') -Recurse -Force -ErrorAction SilentlyContinue

  # A .deskthemepack is a cabinet: the .theme at the root, the pictures under DesktopBackground\. Windows unpacks
  # it to %LOCALAPPDATA%\Microsoft\Windows\Themes\<file name>, so the file name must stay TheSeventhShadow.
  $ddf = Join-Path $env:TEMP 'seventh-shadow.ddf'
  $lines = @(
    '.OPTION EXPLICIT'
    '.Set CabinetNameTemplate=TheSeventhShadow.deskthemepack'
    ".Set DiskDirectoryTemplate=`"$dist`""
    '.Set Cabinet=on'
    '.Set Compress=on'
    '.Set CompressionType=MSZIP'
    '.Set MaxDiskSize=0'
    '.Set RptFileName=nul'
    '.Set InfFileName=nul'
    ".Set DestinationDir="
    "`"$(Join-Path $here 'TheSeventhShadow.theme')`" `"TheSeventhShadow.theme`""
    '.Set DestinationDir=DesktopBackground'
  ) + ($stills | ForEach-Object { "`"$($_.FullName)`" `"$($_.Name)`"" })
  Set-Content -Path $ddf -Value $lines -Encoding ASCII
  & makecab.exe /F $ddf | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "makecab failed ($LASTEXITCODE)" }
  Remove-Item $ddf

  $zip = Join-Path $dist 'TheSeventhShadow-Windows.zip'
  Compress-Archive -Force -DestinationPath $zip -Path @(
    'TheSeventhShadow.theme', 'DesktopBackground', 'terminal', 'fastfetch',
    'install.ps1', 'uninstall.ps1', 'README.md', (Join-Path $dist 'TheSeventhShadow.deskthemepack'))
  Get-ChildItem $dist | ForEach-Object { '{0,-36} {1,8:N1} MB' -f $_.Name, ($_.Length / 1MB) }
} finally {
  Pop-Location
}
