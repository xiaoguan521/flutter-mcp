[CmdletBinding()]
param(
    [ValidateSet('debug', 'release')]
    [string]$BuildMode = 'debug',

    [ValidateSet('android-arm64', 'android-arm', 'android-x64')]
    [string]$TargetPlatform = 'android-arm64',

    [string]$JavaHome = 'C:\Users\xiaochen\.sdkman\candidates\java\17.0.9-tem',
    [string]$FlutterHome = 'E:\flutter',
    [string]$PubCache = 'E:\pub-cache',
    [string]$AndroidHome = 'E:\Android\sdk',
    [string]$AndroidSdkRoot = 'E:\Android\sdk',
    [string]$GradleUserHome = 'D:\program\Java\repository\gradle-flutter-mcp-studio',

    [switch]$SkipClean,
    [switch]$SkipPubGet
)

$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectDir

$env:JAVA_HOME = $JavaHome
$env:FLUTTER_HOME = $FlutterHome
$env:PUB_CACHE = $PubCache
$env:ANDROID_HOME = $AndroidHome
$env:ANDROID_SDK_ROOT = $AndroidSdkRoot
$env:GRADLE_USER_HOME = $GradleUserHome

function Assert-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Label directory not found: $Path"
    }
}

Assert-Directory -Path $env:JAVA_HOME -Label 'JAVA_HOME'
Assert-Directory -Path $env:FLUTTER_HOME -Label 'FLUTTER_HOME'
Assert-Directory -Path $env:PUB_CACHE -Label 'PUB_CACHE'
Assert-Directory -Path $env:ANDROID_HOME -Label 'ANDROID_HOME'
Assert-Directory -Path $env:ANDROID_SDK_ROOT -Label 'ANDROID_SDK_ROOT'
Assert-Directory -Path $env:GRADLE_USER_HOME -Label 'GRADLE_USER_HOME'

$extraPaths = @(
    (Join-Path $env:JAVA_HOME 'bin'),
    (Join-Path $env:FLUTTER_HOME 'bin'),
    (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools'),
    (Join-Path $env:ANDROID_SDK_ROOT 'cmdline-tools\latest\bin')
)

$env:Path = (($extraPaths + ($env:Path -split ';')) | Select-Object -Unique | Where-Object { $_ }) -join ';'

$processNames = @('cmd.exe', 'java.exe', 'dart.exe', 'dartaotruntime.exe', 'dartvm.exe')
$commandLinePatterns = @(
    '*flutter_mcp_studio*',
    '*gradle-flutter-mcp-studio*',
    '*gradle-wrapper.jar*',
    '*flutter_tools.snapshot*',
    '*frontend_server_aot*'
)

$staleProcesses = Get-CimInstance Win32_Process | Where-Object {
    $process = $_
    if ($process.Name -notin $processNames) {
        return $false
    }

    foreach ($pattern in $commandLinePatterns) {
        if ($process.CommandLine -like $pattern) {
            return $true
        }
    }

    return $false
}

if ($staleProcesses) {
    $staleProcesses | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "ProjectDir      : $projectDir"
Write-Host "BuildMode       : $BuildMode"
Write-Host "TargetPlatform  : $TargetPlatform"
Write-Host "JAVA_HOME       : $env:JAVA_HOME"
Write-Host "FLUTTER_HOME    : $env:FLUTTER_HOME"
Write-Host "ANDROID_SDK_ROOT: $env:ANDROID_SDK_ROOT"
Write-Host "GRADLE_USER_HOME: $env:GRADLE_USER_HOME"

& (Join-Path $env:JAVA_HOME 'bin\java.exe') -version
flutter --version

if (-not $SkipClean) {
    flutter clean
}

if (-not $SkipPubGet) {
    flutter pub get
}

$buildArgs = @(
    'build',
    'apk',
    "--$BuildMode",
    '--target-platform',
    $TargetPlatform,
    '-v'
)

flutter @buildArgs

$apkFileName = if ($BuildMode -eq 'release') { 'app-release.apk' } else { 'app-debug.apk' }
$apkPath = Join-Path $projectDir "build\app\outputs\flutter-apk\$apkFileName"

if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
    throw "APK not found after build: $apkPath"
}

$apk = Get-Item -LiteralPath $apkPath
Write-Host ''
Write-Host 'APK build completed successfully.'
Write-Host "APK Path        : $($apk.FullName)"
Write-Host "APK Size (bytes): $($apk.Length)"
Write-Host "LastWriteTime   : $($apk.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
