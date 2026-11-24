[CmdletBinding()]
param(
    [string]$Game,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# Check for .env beside the script first, then in the repo root
$EnvFile = if (Test-Path (Join-Path $PSScriptRoot ".env")) {
    Join-Path $PSScriptRoot ".env"
} elseif (Test-Path (Join-Path $RepoRoot ".env")) {
    Join-Path $RepoRoot ".env"
} else {
    $null
}

if ($EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $key, $val = $line.Split("=", 2)
            $key = $key.Trim()
            $val = $val.Trim()
            [Environment]::SetEnvironmentVariable($key, $val, 'Process')
        }
    }
}

$GamePath = if ($Game) { $Game } elseif ($env:GAME_PATH) { $env:GAME_PATH } else {
    Write-Host "Error: No game directory specified!" -ForegroundColor Red
    Write-Host "Please create a .env file (copy from .env.example) and set GAME_PATH=<path to game>." -ForegroundColor Yellow
    exit 1
}

$Target = if (Test-Path (Join-Path $GamePath "shaders.rpf")) {
    Join-Path $GamePath "shaders.rpf"
} else {
    $GamePath
}

$XclExe = Join-Path $RepoRoot "target\release\xcl.exe"

Write-Host "Precompiling shaders for game..." -ForegroundColor Cyan
Write-Host "Game: $GamePath" -ForegroundColor White
Write-Host "Target: $Target" -ForegroundColor White
if ($env:XCL_DXC_DIR) {
    Write-Host "DXC:  $env:XCL_DXC_DIR" -ForegroundColor Green
}

& $XclExe shaders $Target --precompile --pipelines $ExtraArgs
