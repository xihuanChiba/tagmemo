$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectDir

$PlatformTemplateDir = Join-Path ([System.IO.Path]::GetTempPath()) ("tagmemo-" + [guid]::NewGuid())
try {
    flutter create --platforms=android,windows --org com.xihuanchiba --project-name tagmemo $PlatformTemplateDir
    Copy-Item -Path (Join-Path $PlatformTemplateDir "android") -Destination $ProjectDir -Recurse -Force
    Copy-Item -Path (Join-Path $PlatformTemplateDir "windows") -Destination $ProjectDir -Recurse -Force
    Copy-Item -Path "platform_overrides/android/*" -Destination "android" -Recurse -Force
    flutter pub get
}
finally {
    if (Test-Path $PlatformTemplateDir) {
        Remove-Item -Path $PlatformTemplateDir -Recurse -Force
    }
}

Write-Host "TagMemo platform files are ready."
