# PowerShell script to run OpenHands CLI mode with Docker Compose

# Check if Docker is installed
try {
    $null = docker --version
}
catch {
    Write-Host "Docker is not installed. Please install Docker first." -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is installed
try {
    $null = docker compose version
}
catch {
    Write-Host "Docker Compose is not installed. Please install Docker Compose first." -ForegroundColor Red
    exit 1
}

# Set default values
$DEFAULT_WORKSPACE = (Get-Location).Path -replace '\\', '/'  # Convert to Docker-compatible path format
$DEFAULT_MODEL = "anthropic/claude-sonnet-4-20250514"
$DEFAULT_CONTAINER_VERSION = "0.39"

# Prompt for environment variables if not set
if (-not $env:SANDBOX_VOLUMES) {
    $userInput = Read-Host "Enter the directory you want OpenHands to access [default: $DEFAULT_WORKSPACE]"
    $workspacePath = if ($userInput) { $userInput } else { $DEFAULT_WORKSPACE }
    
    # Convert Windows path to Docker-compatible format (replace backslashes with forward slashes)
    $workspacePath = $workspacePath -replace '\\', '/'
    
    $env:SANDBOX_VOLUMES = $workspacePath
}

if (-not $env:LLM_MODEL) {
    $userInput = Read-Host "Enter the LLM model to use [default: $DEFAULT_MODEL]"
    $env:LLM_MODEL = if ($userInput) { $userInput } else { $DEFAULT_MODEL }
}

if (-not $env:LLM_API_KEY) {
    $env:LLM_API_KEY = Read-Host "Enter your LLM API key"
    if (-not $env:LLM_API_KEY) {
        Write-Host "API key is required. Exiting." -ForegroundColor Red
        exit 1
    }
}

if (-not $env:CONTAINER_VERSION) {
    $userInput = Read-Host "Enter the container version to use [default: $DEFAULT_CONTAINER_VERSION]"
    $env:CONTAINER_VERSION = if ($userInput) { $userInput } else { $DEFAULT_CONTAINER_VERSION }
}

# 必要なDockerイメージがローカルに存在するか確認し、なければpullする
$containerImage = "docker.all-hands.dev/all-hands-ai/runtime:$($env:CONTAINER_VERSION)-nikolaik"
try {
    docker image inspect $containerImage | Out-Null
    Write-Host "Docker image $containerImage already exsists in local." -ForegroundColor Green
} catch {
    Write-Host "Docker image $containerImage does not exsists in local. pull..." -ForegroundColor Yellow
    try {
        docker pull $containerImage
        Write-Host "Docker image $containerImage pull success." -ForegroundColor Green
    } catch {
        Write-Host "Docker image $containerImage pull failed. error: $_" -ForegroundColor Red
        exit 1
    }
}

# Set user ID for correct file permissions (use 1000 as default for Windows)
$env:SANDBOX_USER_ID = 1000

Write-Host "Starting OpenHands CLI mode with the following configuration:" -ForegroundColor Green
Write-Host "Workspace: $env:SANDBOX_VOLUMES" -ForegroundColor Cyan
Write-Host "LLM Model: $env:LLM_MODEL" -ForegroundColor Cyan
Write-Host "User ID: $env:SANDBOX_USER_ID" -ForegroundColor Cyan

# パスの処理
# 1. 相対パスを絶対パスに変換
if (-not [System.IO.Path]::IsPathRooted($env:SANDBOX_VOLUMES)) {
    # 相対パスを絶対パスに変換
    $absolutePath = Join-Path -Path (Get-Location) -ChildPath $env:SANDBOX_VOLUMES
    Write-Host "Converting relative path to absolute path: $env:SANDBOX_VOLUMES -> $absolutePath" -ForegroundColor Yellow
    $env:SANDBOX_VOLUMES = $absolutePath
}

Write-Host "Using workspace path: $env:SANDBOX_VOLUMES" -ForegroundColor Cyan

# Check if the path exists
if (-not (Test-Path $env:SANDBOX_VOLUMES)) {
    Write-Host "Directory '$env:SANDBOX_VOLUMES' does not exist. Creating it now..." -ForegroundColor Yellow
    try {
        New-Item -Path $env:SANDBOX_VOLUMES -ItemType Directory -Force | Out-Null
        Write-Host "Directory created successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to create directory. Error: $_" -ForegroundColor Red
        exit 1
    }
}

# # ドライブレターの変換（Docker用）
# $env:SANDBOX_VOLUMES = $env:SANDBOX_VOLUMES -replace 'C:', '/mnt/c'

# # スラッシュに変換
# $env:SANDBOX_VOLUMES = $env:SANDBOX_VOLUMES -replace '\\', '/'

# config.tomlファイルを更新
function Update-ConfigFile {
    $configPath = Join-Path -Path (Get-Location) -ChildPath "config.toml"
    $configContent = Get-Content -Path $configPath -Raw

    # 環境変数の値で置換
    $configContent = $configContent -replace '(?m)^\[llm\].*?(?=^\[|$)', "[llm]`nprovider = `"anthropic`"`nmodel = `"$env:LLM_MODEL`"`n"
    $configContent = $configContent -replace '(?m)^\[agent\].*?(?=^\[|$)', "[agent]`nworkspace_base = `"$env:SANDBOX_VOLUMES`"`nconfirmation_mode = false`n"

    # 更新した内容を書き込み
    Set-Content -Path $configPath -Value $configContent

    Write-Host "Updated config.toml with current settings" -ForegroundColor Green
}

# Update-ConfigFile

# クリーンアップ関数を定義
function Cleanup {
    Write-Host "`nCleaning up resources..." -ForegroundColor Yellow
    docker compose down
    Write-Host "Cleanup complete. Thank you for using OpenHands CLI!" -ForegroundColor Green
}

# Ctrl+Cが押された場合のハンドラを設定
try {
    # Run Docker Compose with terminal attachment
    Write-Host "Starting Docker Compose..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to exit" -ForegroundColor Cyan
    docker compose run --rm openhands-cli
}
finally {
    # 終了時にクリーンアップを実行
    Cleanup
}