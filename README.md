# OpenHands CLI Mode with Docker Compose

This repository contains a Docker Compose configuration for running OpenHands in CLI mode.

## Prerequisites

- Docker and Docker Compose installed on your system
- An API key for your chosen LLM provider
- Docker socket accessible to the user running the compose command

## Setup

### Using Helper Scripts (Recommended)

#### Linux/macOS
```bash
./run-openhands-cli.sh
```

#### [This does not work. Use WSL2] Windows (PowerShell)
```powershell
.\run-openhands-cli.ps1
```

These scripts will prompt you for the necessary configuration if environment variables are not already set.

### Manual Setup

1. Set the required environment variables:

#### Linux/macOS
```bash
# Directory you want OpenHands to access
export SANDBOX_VOLUMES="/path/to/your/workspace"

# Your user ID (to ensure correct file permissions)
export SANDBOX_USER_ID=$(id -u)

# LLM configuration
export LLM_MODEL="anthropic/claude-sonnet-4-20250514"  # Or your preferred model
export LLM_API_KEY="your_api_key_here"
```

#### [This does not work. Use WSL2] Windows (PowerShell)
```powershell
# Directory you want OpenHands to access
$env:SANDBOX_VOLUMES="C:\path\to\your\workspace"

# User ID (use 1000 as default for Windows)
$env:SANDBOX_USER_ID=1000

# LLM configuration
$env:LLM_MODEL="anthropic/claude-sonnet-4-20250514"  # Or your preferred model
$env:LLM_API_KEY="your_api_key_here"
```

2. Run OpenHands CLI using Docker Compose:

```bash
docker compose up
```

## Windows-Specific Notes

- When using Windows, you may need to adjust the volume mount paths in the Docker Compose file
- Windows paths (like `C:\Users\username\project`) need to be converted to the format Docker expects
- The PowerShell script automatically uses the current directory, but for custom paths:
  - Use forward slashes: `C:/Users/username/project`
  - Or escaped backslashes: `C:\\Users\\username\\project`
- If you encounter path-related errors, try using the WSL 2 backend for Docker Desktop
