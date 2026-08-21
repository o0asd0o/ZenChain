#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "ZenChain"),
    [string]$RepoUrl = "https://github.com/o0asd0o/ZenChain.git",
    [string]$Ref = "main",
    [switch]$SkipPathUpdate
)

$ErrorActionPreference = "Stop"

function Find-Git {
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "Git for Windows is required. Install it from https://git-scm.com/download/win and run this installer again."
    }
    return $command.Source
}

function Find-GitBash {
    $candidates = @(
        (Join-Path ${env:ProgramFiles} "Git\bin\bash.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Git\bin\bash.exe")
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    $command = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }
    throw "Git Bash is required. Install Git for Windows and run this installer again."
}

$git = Find-Git
$bash = Find-GitBash
$parent = Split-Path -Parent $InstallRoot
New-Item -ItemType Directory -Force -Path $parent | Out-Null

if (Test-Path (Join-Path $InstallRoot ".git")) {
    Write-Host "Updating ZenChain in $InstallRoot"
    & $git -C $InstallRoot pull --ff-only origin $Ref
    if ($LASTEXITCODE -ne 0) {
        throw "The existing ZenChain checkout could not be updated automatically. Resolve it in $InstallRoot and rerun this installer."
    }
} elseif (Test-Path $InstallRoot) {
    throw "$InstallRoot exists but is not a Git checkout. Choose another -InstallRoot or remove that directory."
} else {
    Write-Host "Downloading ZenChain"
    & $git clone --depth 1 --branch $Ref $RepoUrl $InstallRoot
    if ($LASTEXITCODE -ne 0) {
        throw "ZenChain could not be downloaded from $RepoUrl."
    }
}

$zen = Join-Path $InstallRoot "zen"
if (-not (Test-Path $zen)) {
    throw "The ZenChain checkout is missing its zen entry point: $zen"
}

$bin = Join-Path $env:USERPROFILE "bin"
New-Item -ItemType Directory -Force -Path $bin | Out-Null

$cmdPath = Join-Path $bin "zen.cmd"
$cmdLines = @(
    "@echo off",
    ('"{0}" "{1}" %*' -f $bash, $zen),
    "exit /b %ERRORLEVEL%"
)
Set-Content -Path $cmdPath -Value ($cmdLines -join [Environment]::NewLine) -Encoding ASCII

$psPath = Join-Path $bin "zen.ps1"
$bashLiteral = $bash.Replace("'", "''")
$zenLiteral = $zen.Replace("'", "''")
$psLines = @(
    "& '$bashLiteral' '$zenLiteral' @args",
    "exit `$LASTEXITCODE"
)
Set-Content -Path $psPath -Value ($psLines -join [Environment]::NewLine) -Encoding UTF8

if (-not $SkipPathUpdate) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @($userPath -split ';' | Where-Object { $_ })
    if ($parts -notcontains $bin) {
        [Environment]::SetEnvironmentVariable("Path", (($parts + $bin) -join ';'), "User")
        Write-Host "Added $bin to your user PATH. Open a new terminal before running zen."
    }
}

Write-Host "ZenChain installed. Open a new PowerShell or Command Prompt, then run:"
Write-Host "  zen doctor"
