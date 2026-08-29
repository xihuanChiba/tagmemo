$ErrorActionPreference = "Stop"
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = Join-Path $env:LOCALAPPDATA "TagMemo"

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Copy-Item -Path (Join-Path $SourceDir "*") -Destination $InstallDir -Recurse -Force

$ExePath = Join-Path $InstallDir "tagmemo.exe"
$ProtocolRoot = "HKCU:\Software\Classes\tagmemo"
New-Item -Path $ProtocolRoot -Force | Out-Null
Set-ItemProperty -Path $ProtocolRoot -Name "(Default)" -Value "URL:TagMemo Protocol"
Set-ItemProperty -Path $ProtocolRoot -Name "URL Protocol" -Value ""
New-Item -Path "$ProtocolRoot\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$ProtocolRoot\shell\open\command" -Name "(Default)" -Value ('"' + $ExePath + '" "%1"')

Write-Host "TagMemo installed at $InstallDir"
