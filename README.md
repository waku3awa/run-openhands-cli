# OpenHands CLI Mode with Docker Compose

This repository contains a Docker Compose configuration for running OpenHands in CLI mode with enhanced model selection and local LLM support.

## File Structure

- `compose.yaml` - Docker Compose configuration file
- `run-openhands-cli.sh` - Startup script with interactive model selection
- `models.conf` - Available LLM models configuration
- `config.toml` - OpenHands configuration file
- `local_llm_setting.md` - Detailed local LLM setup instructions

## Prerequisites

- Docker and Docker Compose installed on your system
- An API key for your chosen LLM provider (not required for local LLMs)
- Docker socket accessible to the user running the compose command

## Setup

### API Key Configuration (Optional)

To avoid entering API keys every time, you can create a `.env` file to store your API keys:

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your API keys:
   ```bash
   # Uncomment and set the API keys you need
   ANTHROPIC_API_KEY=your_anthropic_api_key_here
   GOOGLE_API_KEY=your_google_api_key_here
   OPENAI_API_KEY=your_openai_api_key_here
   KLUSTER_API_KEY=your_kluster_api_key_here
   OPENROUTER_API_KEY=your_openrouter_api_key_here
   ```

3. The script will automatically use the appropriate API key based on the selected model.

### Using Helper Scripts (Recommended)

#### Linux/macOS
```bash
./run-openhands-cli.sh
```

#### [This does not work. Use WSL2] Windows (PowerShell)
```powershell
.\run-openhands-cli.ps1
```

The script will guide you through the following configuration steps:

1. **Environment Variables Loading**
   - Automatically loads API keys from `.env` file if present

2. **Workspace Directory Selection**
   - Specify the directory OpenHands should access
   - Default: current directory

3. **LLM Model Selection**
   - Choose from models defined in `models.conf`
   - Supports both cloud and local LLMs

4. **API Key Input**
   - If API key is found in `.env`: Uses it automatically
   - If not found: Prompts for manual input
   - Local LLMs: Automatically sets "dummy" key

5. **Container Version Selection**
   - Default: 0.39

These scripts will prompt you for the necessary configuration if environment variables are not already set.

### Manual Setup

You can skip the interactive prompts by setting environment variables beforehand:

#### Linux/macOS
```bash
# Directory you want OpenHands to access
export SANDBOX_VOLUMES="/path/to/your/workspace"

# Your user ID (to ensure correct file permissions)
export SANDBOX_USER_ID=$(id -u)

# LLM configuration
export LLM_MODEL="anthropic/claude-3-5-sonnet-20241022"  # Or your preferred model
export LLM_API_KEY="your_api_key_here"
export LLM_BASE_URL="http://localhost:8000"  # Only for local LLMs
export CONTAINER_VERSION="0.39"

./run-openhands-cli.sh
```

#### [This does not work. Use WSL2] Windows (PowerShell)
```powershell
# Directory you want OpenHands to access
$env:SANDBOX_VOLUMES="C:\path\to\your\workspace"

# User ID (use 1000 as default for Windows)
$env:SANDBOX_USER_ID=1000

# LLM configuration
$env:LLM_MODEL="anthropic/claude-3-5-sonnet-20241022"  # Or your preferred model
$env:LLM_API_KEY="your_api_key_here"
$env:LLM_BASE_URL="http://localhost:8000"  # Only for local LLMs
$env:CONTAINER_VERSION="0.39"

.\run-openhands-cli.ps1
```

Alternatively, run OpenHands CLI directly using Docker Compose:

```bash
docker compose up
```

## Model Configuration

### models.conf Format

The `models.conf` file defines available LLM models in the following format:

```
MODEL_NAME|DISPLAY_NAME|BASE_URL|API_KEY_ENV|DESCRIPTION
```

- `MODEL_NAME`: Model name used by OpenHands
- `DISPLAY_NAME`: Name displayed in the selection menu
- `BASE_URL`: Base URL for OpenAI API-compatible local LLMs (empty for standard APIs)
- `API_KEY_ENV`: Environment variable name for the API key (empty for manual input or local LLMs)
- `DESCRIPTION`: Model description

### Adding New Models

Edit the `models.conf` file to add new models:

```bash
# Cloud LLM with API key from environment
openai/gpt-4-turbo|GPT-4 Turbo||OPENAI_API_KEY|OpenAI GPT-4 Turbo

# Cloud LLM with manual API key input
custom/model|Custom Model|||Custom model requiring manual API key

# Local LLM (no API key needed)
openai/my-local-model|My Local Model|http://localhost:8000||Custom local model
```

## Local LLM Setup

### Using LMStudio

1. Load a model in LMStudio and start the server (port 1234)
2. Add the following configuration to `models.conf`:

```
lm_studio/your-model|Your Model (LMStudio)|http://host.docker.internal:1234/v1|Model via LMStudio
```

### Using SGLang/vLLM

1. Start SGLang or vLLM server (port 8000)
2. Add the following configuration to `models.conf`:

```
openai/your-model|Your Model (SGLang)|http://host.docker.internal:8000|Model via SGLang
```

For detailed local LLM setup instructions, see `local_llm_setting.md`.

## Troubleshooting

### Docker Permission Errors

```bash
sudo usermod -aG docker $USER
# Logout and login required
```

### Cannot Connect to Local LLM

1. Verify the local LLM server is running
2. Check the port number is correct
3. If `host.docker.internal` doesn't work, use the actual IP address

### Model Configuration File Not Found

Ensure the `models.conf` file is in the same directory as the script.

### Exit OpenHands CLI

Press `Ctrl+C` while OpenHands CLI is running to execute cleanup and exit.

## Windows-Specific Notes

- When using Windows, you may need to adjust the volume mount paths in the Docker Compose file
- Windows paths (like `C:\Users\username\project`) need to be converted to the format Docker expects
- The PowerShell script automatically uses the current directory, but for custom paths:
  - Use forward slashes: `C:/Users/username/project`
  - Or escaped backslashes: `C:\\Users\\username\\project`
- If you encounter path-related errors, try using the WSL 2 backend for Docker Desktop
