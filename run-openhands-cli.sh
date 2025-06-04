#!/bin/bash

cd "$(dirname "$0")"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Set default values
DEFAULT_WORKSPACE="$(pwd)"
DEFAULT_CONTAINER_VERSION="0.39"
MODELS_CONFIG_FILE="./models.conf"
ENV_FILE="./.env"

# Function to load environment variables from .env file
load_env_file() {
    if [ -f "$ENV_FILE" ]; then
        echo "Loading environment variables from $ENV_FILE"
        # Export variables from .env file, ignoring comments and empty lines
        while IFS= read -r line; do
            # Skip comments and empty lines
            if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
                continue
            fi
            # Export the variable
            export "$line"
        done < "$ENV_FILE"
    fi
}

# Function to load models from config file
load_models() {
    if [ ! -f "$MODELS_CONFIG_FILE" ]; then
        echo "Error: Models configuration file '$MODELS_CONFIG_FILE' not found."
        exit 1
    fi
    
    # Read models from config file (skip comments and empty lines)
    models=()
    display_names=()
    base_urls=()
    api_key_envs=()
    descriptions=()
    
    while IFS='|' read -r model_name display_name base_url api_key_env description; do
        # Skip comments and empty lines
        if [[ "$model_name" =~ ^#.*$ ]] || [[ -z "$model_name" ]]; then
            continue
        fi
        models+=("$model_name")
        display_names+=("$display_name")
        base_urls+=("$base_url")
        api_key_envs+=("$api_key_env")
        descriptions+=("$description")
    done < "$MODELS_CONFIG_FILE"
}

# Function to display model list with cursor selection
display_models() {
    local selected_index=$1
    
    # Clear screen and move cursor to top
    printf "\033[2J\033[H"
    
    echo "Available LLM models:"
    echo "====================="
    echo "Use ↑/↓ arrow keys (or j/k) to navigate, 1-9 for quick select, Enter to confirm, Esc to exit"
    echo ""
    
    for i in "${!models[@]}"; do
        # Build the display line with model name, description, and base URL
        local display_line="%d) %s"
        local line_args=($((i+1)) "${display_names[i]}")
        
        if [ -n "${descriptions[i]}" ]; then
            display_line="$display_line - %s"
            line_args+=("${descriptions[i]}")
        fi
        
        if [ -n "${base_urls[i]}" ]; then
            display_line="$display_line [%s]"
            line_args+=("${base_urls[i]}")
        fi
        
        if [ $i -eq $selected_index ]; then
            # Highlight selected item with background color and arrow
            printf "\033[7m> $display_line\033[0m\n" "${line_args[@]}"
        else
            printf "  $display_line\n" "${line_args[@]}"
        fi
    done
}

# Function to display existing containers with cursor selection
display_containers() {
    local selected_index=$1
    local containers=("${@:2}")
    
    # Clear screen and move cursor to top
    printf "\033[2J\033[H"
    
    echo "Existing OpenHands Runtime Containers:"
    echo "====================================="
    echo "Use ↑/↓ arrow keys (or j/k) to navigate, 1-9 for quick select, Enter to confirm, Esc to exit"
    echo ""
    
    for i in "${!containers[@]}"; do
        local container_info="${containers[i]}"
        local container_name=$(echo "$container_info" | cut -d'|' -f1)
        local container_status=$(echo "$container_info" | cut -d'|' -f2)
        local container_created=$(echo "$container_info" | cut -d'|' -f3)
        
        if [ $i -eq $selected_index ]; then
            # Highlight selected item with background color and arrow
            printf "\033[7m> %d) %s [%s] (Created: %s)\033[0m\n" $((i+1)) "$container_name" "$container_status" "$container_created"
        else
            printf "  %d) %s [%s] (Created: %s)\n" $((i+1)) "$container_name" "$container_status" "$container_created"
        fi
    done
}

# Function to select existing container with cursor navigation
select_existing_container() {
    # Get existing openhands-runtime containers
    local container_data=()
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            container_data+=("$line")
        fi
    done < <(docker ps -a --filter "name=openhands-runtime-" --format "{{.Names}}|{{.Status}}|{{.CreatedAt}}")
    
    if [ ${#container_data[@]} -eq 0 ]; then
        echo "既存のOpenHands Runtimeコンテナが見つかりませんでした。"
        echo "新規作成に進みます..."
        echo ""
        return 1
    fi
    
    local selected_index=0
    local key
    
    # Hide cursor
    printf "\033[?25l"
    
    # Display initial list
    display_containers $selected_index "${container_data[@]}"
    
    while true; do
        # Read a single character
        read -rsn1 key
        
        # Handle escape sequences (arrow keys) and escape key
        if [[ $key == $'\x1b' ]]; then
            # Read next characters to determine if it's an arrow key or just escape
            read -rsn1 -t 0.1 next_key
            if [[ $next_key == '[' ]]; then
                read -rsn1 arrow_key
                case $arrow_key in
                    'A') # Up arrow
                        if [ $selected_index -gt 0 ]; then
                            selected_index=$((selected_index - 1))
                            display_containers $selected_index "${container_data[@]}"
                        fi
                        ;;
                    'B') # Down arrow
                        if [ $selected_index -lt $((${#container_data[@]} - 1)) ]; then
                            selected_index=$((selected_index + 1))
                            display_containers $selected_index "${container_data[@]}"
                        fi
                        ;;
                esac
            else
                # Pure escape key pressed
                printf "\033[?25h" # Show cursor
                printf "\033[2J\033[H" # Clear screen
                echo "Selection cancelled."
                exit 0
            fi
        elif [[ $key == $'\n' ]] || [[ $key == $'\r' ]] || [[ $key == '' ]]; then
            # Enter key pressed
            break
        elif [[ $key == 'j' ]] || [[ $key == 'J' ]]; then
            # j key (vim-style down)
            if [ $selected_index -lt $((${#container_data[@]} - 1)) ]; then
                selected_index=$((selected_index + 1))
                display_containers $selected_index "${container_data[@]}"
            fi
        elif [[ $key == 'k' ]] || [[ $key == 'K' ]]; then
            # k key (vim-style up)
            if [ $selected_index -gt 0 ]; then
                selected_index=$((selected_index - 1))
                display_containers $selected_index "${container_data[@]}"
            fi
        elif [[ $key =~ ^[0-9]$ ]]; then
            # Number key pressed - jump to that index (1-based)
            local num_selection=$((key - 1))
            if [ $num_selection -ge 0 ] && [ $num_selection -lt ${#container_data[@]} ]; then
                selected_index=$num_selection
                display_containers $selected_index "${container_data[@]}"
            fi
        fi
    done
    
    # Show cursor again
    printf "\033[?25h"
    
    # Get selected container name
    local selected_container_info="${container_data[selected_index]}"
    local selected_container_name=$(echo "$selected_container_info" | cut -d'|' -f1)
    
    # Extract WORKSPACE_DIR from container name
    # Container name format: openhands-runtime-{WORKSPACE_DIR}-{hash}
    local workspace_dir=$(echo "$selected_container_name" | sed 's/^openhands-runtime-\(.*\)-[a-f0-9]*$/\1/')
    
    # Clear screen and show final selection
    printf "\033[2J\033[H"
    echo "Selected container: $selected_container_name"
    echo "Extracted WORKSPACE_DIR: $workspace_dir"
    echo ""
    
    # Set WORKSPACE_DIR for existing container
    export WORKSPACE_DIR="$workspace_dir"
    export SANDBOX_VOLUMES="$workspace_dir"
    
    return 0
}

# Function to display runtime choice with cursor selection
display_runtime_choice() {
    local selected_index=$1
    
    # Clear screen and move cursor to top
    printf "\033[2J\033[H"
    
    echo "OpenHands Runtime選択"
    echo "==================="
    echo "Use ↑/↓ arrow keys (or j/k) to navigate, Enter to confirm, Esc to exit"
    echo ""
    
    local choices=("新規runtime(session)を作成" "既存runtime(session)を利用")
    
    for i in "${!choices[@]}"; do
        if [ $i -eq $selected_index ]; then
            # Highlight selected item with background color and arrow
            printf "\033[7m> %d) %s\033[0m\n" $((i+1)) "${choices[i]}"
        else
            printf "  %d) %s\n" $((i+1)) "${choices[i]}"
        fi
    done
}

# Function to ask user for new or existing runtime with cursor navigation
ask_runtime_choice() {
    local selected_index=0
    local key
    local choices=("新規runtime(session)を作成" "既存runtime(session)を利用")
    
    # Hide cursor
    printf "\033[?25l"
    
    # Display initial list
    display_runtime_choice $selected_index
    
    while true; do
        # Read a single character
        read -rsn1 key
        
        # Handle escape sequences (arrow keys) and escape key
        if [[ $key == $'\x1b' ]]; then
            # Read next characters to determine if it's an arrow key or just escape
            read -rsn1 -t 0.1 next_key
            if [[ $next_key == '[' ]]; then
                read -rsn1 arrow_key
                case $arrow_key in
                    'A') # Up arrow
                        if [ $selected_index -gt 0 ]; then
                            selected_index=$((selected_index - 1))
                            display_runtime_choice $selected_index
                        fi
                        ;;
                    'B') # Down arrow
                        if [ $selected_index -lt $((${#choices[@]} - 1)) ]; then
                            selected_index=$((selected_index + 1))
                            display_runtime_choice $selected_index
                        fi
                        ;;
                esac
            else
                # Pure escape key pressed
                printf "\033[?25h" # Show cursor
                printf "\033[2J\033[H" # Clear screen
                echo "Selection cancelled."
                exit 0
            fi
        elif [[ $key == $'\n' ]] || [[ $key == $'\r' ]] || [[ $key == '' ]]; then
            # Enter key pressed
            break
        elif [[ $key == 'j' ]] || [[ $key == 'J' ]]; then
            # j key (vim-style down)
            if [ $selected_index -lt $((${#choices[@]} - 1)) ]; then
                selected_index=$((selected_index + 1))
                display_runtime_choice $selected_index
            fi
        elif [[ $key == 'k' ]] || [[ $key == 'K' ]]; then
            # k key (vim-style up)
            if [ $selected_index -gt 0 ]; then
                selected_index=$((selected_index - 1))
                display_runtime_choice $selected_index
            fi
        elif [[ $key =~ ^[1-2]$ ]]; then
            # Number key pressed - jump to that index (1-based)
            local num_selection=$((key - 1))
            if [ $num_selection -ge 0 ] && [ $num_selection -lt ${#choices[@]} ]; then
                selected_index=$num_selection
                display_runtime_choice $selected_index
            fi
        fi
    done
    
    # Show cursor again
    printf "\033[?25h"
    
    # Clear screen and show final selection
    printf "\033[2J\033[H"
    
    case $selected_index in
        0)
            echo "選択: 新規runtime(session)を作成"
            echo ""
            return 0  # 新規作成
            ;;
        1)
            echo "選択: 既存runtime(session)を利用"
            echo "既存runtime(session)を検索します..."
            echo ""
            if select_existing_container; then
                return 1  # 既存利用
            else
                echo "既存コンテナが見つからないため、新規作成に進みます。"
                return 0  # 新規作成にフォールバック
            fi
            ;;
    esac
}

# Function to select model with cursor navigation
select_model() {
    load_models
    
    if [ ${#models[@]} -eq 0 ]; then
        echo "Error: No models found in configuration file."
        exit 1
    fi
    
    local selected_index=0
    local key
    
    # Hide cursor
    printf "\033[?25l"
    
    # Display initial list
    display_models $selected_index
    
    while true; do
        # Read a single character
        read -rsn1 key
        
        # Handle escape sequences (arrow keys) and escape key
        if [[ $key == $'\x1b' ]]; then
            # Read next characters to determine if it's an arrow key or just escape
            read -rsn1 -t 0.1 next_key
            if [[ $next_key == '[' ]]; then
                read -rsn1 arrow_key
                case $arrow_key in
                    'A') # Up arrow
                        if [ $selected_index -gt 0 ]; then
                            selected_index=$((selected_index - 1))
                            display_models $selected_index
                        fi
                        ;;
                    'B') # Down arrow
                        if [ $selected_index -lt $((${#models[@]} - 1)) ]; then
                            selected_index=$((selected_index + 1))
                            display_models $selected_index
                        fi
                        ;;
                esac
            else
                # Pure escape key pressed
                printf "\033[?25h" # Show cursor
                printf "\033[2J\033[H" # Clear screen
                echo "Selection cancelled."
                exit 0
            fi
        elif [[ $key == $'\n' ]] || [[ $key == $'\r' ]] || [[ $key == '' ]]; then
            # Enter key pressed
            break
        elif [[ $key == 'j' ]] || [[ $key == 'J' ]]; then
            # j key (vim-style down)
            if [ $selected_index -lt $((${#models[@]} - 1)) ]; then
                selected_index=$((selected_index + 1))
                display_models $selected_index
            fi
        elif [[ $key == 'k' ]] || [[ $key == 'K' ]]; then
            # k key (vim-style up)
            if [ $selected_index -gt 0 ]; then
                selected_index=$((selected_index - 1))
                display_models $selected_index
            fi
        elif [[ $key =~ ^[0-9]$ ]]; then
            # Number key pressed - jump to that index (1-based)
            local num_selection=$((key - 1))
            if [ $num_selection -ge 0 ] && [ $num_selection -lt ${#models[@]} ]; then
                selected_index=$num_selection
                display_models $selected_index
            fi
        fi
    done
    
    # Show cursor again
    printf "\033[?25h"
    
    # Set selected model
    export LLM_MODEL="${models[selected_index]}"
    export LLM_BASE_URL="${base_urls[selected_index]}"
    export SELECTED_API_KEY_ENV="${api_key_envs[selected_index]}"
    
    # Clear screen and show final selection
    printf "\033[2J\033[H"
    echo "Selected model: ${display_names[selected_index]}"
    if [ -n "$LLM_BASE_URL" ]; then
        echo "Base URL: $LLM_BASE_URL"
    fi
    if [ -n "$SELECTED_API_KEY_ENV" ]; then
        echo "API Key Environment Variable: $SELECTED_API_KEY_ENV"
    fi
    echo ""
}

# Load environment variables from .env file
load_env_file

# Ask user for new or existing runtime
if ask_runtime_choice; then
    # 新規作成の場合
    USE_EXISTING_RUNTIME=false
    
    # Prompt for environment variables if not set
    if [ -z "$SANDBOX_VOLUMES" ]; then
        read -p "Enter the directory you want OpenHands to access [default: $DEFAULT_WORKSPACE]: " SANDBOX_VOLUMES
        SANDBOX_VOLUMES=${SANDBOX_VOLUMES:-$DEFAULT_WORKSPACE}
        export SANDBOX_VOLUMES
    fi
    
    # Set WORKSPACE_DIR to the same value as SANDBOX_VOLUMES for use in compose.yaml
    export WORKSPACE_DIR="$SANDBOX_VOLUMES"
else
    # 既存利用の場合（WORKSPACE_DIRとSANDBOX_VOLUMESは既に設定済み）
    USE_EXISTING_RUNTIME=true
fi

if [ -z "$LLM_MODEL" ]; then
    select_model
fi

# Function to check if URL is local
is_local_url() {
    local url="$1"
    if [[ "$url" =~ ^https?://(localhost|127\.0\.0\.1|host\.docker\.internal|0\.0\.0\.0)(:[0-9]+)?(/.*)?$ ]]; then
        return 0  # true - is local
    else
        return 1  # false - is not local
    fi
}

# Handle API key based on model type
if [ -z "$LLM_API_KEY" ]; then
    # Check if this is a local LLM (has local base_url set)
    if [ -n "$LLM_BASE_URL" ] && is_local_url "$LLM_BASE_URL"; then
        echo "Local LLM detected. Using dummy API key."
        export LLM_API_KEY="dummy"
    else
        # Try to get API key from environment variable specified in model config
        if [ -n "$SELECTED_API_KEY_ENV" ]; then
            # Use indirect variable expansion to get the value of the environment variable
            api_key_value="${!SELECTED_API_KEY_ENV}"
            if [ -n "$api_key_value" ]; then
                echo "Using API key from environment variable: $SELECTED_API_KEY_ENV"
                export LLM_API_KEY="$api_key_value"
            else
                echo "Environment variable $SELECTED_API_KEY_ENV is not set or empty."
                read -p "Enter your LLM API key: " LLM_API_KEY
                if [ -z "$LLM_API_KEY" ]; then
                    echo "API key is required. Exiting."
                    exit 1
                fi
                export LLM_API_KEY
            fi
        else
            # No API key environment variable specified, ask user for input
            read -p "Enter your LLM API key: " LLM_API_KEY
            if [ -z "$LLM_API_KEY" ]; then
                echo "API key is required. Exiting."
                exit 1
            fi
            export LLM_API_KEY
        fi
    fi
fi

if [ -z "$CONTAINER_VERSION" ]; then
    read -p "Enter the container version to use [default: $DEFAULT_CONTAINER_VERSION]: " CONTAINER_VERSION
    CONTAINER_VERSION=${CONTAINER_VERSION:-$DEFAULT_CONTAINER_VERSION}
    export CONTAINER_VERSION
fi

# 新規作成の場合のみDockerイメージの確認とディレクトリ作成を行う
if [ "$USE_EXISTING_RUNTIME" = false ]; then
    # 必要なDockerイメージがローカルに存在するか確認し、なければpullする
    CONTAINER_IMAGE="docker.all-hands.dev/all-hands-ai/runtime:${CONTAINER_VERSION}-nikolaik"
    if ! docker image inspect "$CONTAINER_IMAGE" > /dev/null 2>&1; then
        echo "Docker image $CONTAINER_IMAGE does not exsists in local. pull..."
        if docker pull "$CONTAINER_IMAGE"; then
            echo "Docker image $CONTAINER_IMAGE pull success."
        else
            echo "Docker image $CONTAINER_IMAGE pull failed. Exit."
            exit 1
        fi
    else
        echo "Docker image $CONTAINER_IMAGE already exsists in local."
    fi
    
    # 相対パスを絶対パスに変換
    if [[ ! "$SANDBOX_VOLUMES" = /* ]]; then
        ABSOLUTE_PATH="$(pwd)/$SANDBOX_VOLUMES"
        echo "Converting relative path to absolute path: $SANDBOX_VOLUMES -> $ABSOLUTE_PATH"
        SANDBOX_VOLUMES="$ABSOLUTE_PATH"
        export SANDBOX_VOLUMES
    fi
    
    # ディレクトリが存在しない場合は作成
    if [ ! -d "$SANDBOX_VOLUMES" ]; then
        echo "Directory '$SANDBOX_VOLUMES' does not exist. Creating it now..."
        mkdir -p "$SANDBOX_VOLUMES"
        if [ $? -eq 0 ]; then
            echo "Directory created successfully."
        else
            echo "Failed to create directory. Exiting."
            exit 1
        fi
    fi
else
    echo "既存runtimeを利用するため、ディレクトリ作成とDockerイメージの確認をスキップします。"
fi

# Set user ID for correct file permissions
export SANDBOX_USER_ID=$(id -u)

echo "Starting OpenHands CLI mode with the following configuration:"
if [ "$USE_EXISTING_RUNTIME" = true ]; then
    echo "Mode: 既存runtime利用"
    echo "Selected WORKSPACE_DIR: $WORKSPACE_DIR"
else
    echo "Mode: 新規runtime作成"
    echo "Workspace: $SANDBOX_VOLUMES"
fi
echo "LLM Model: $LLM_MODEL"
if [ -n "$LLM_BASE_URL" ]; then
    echo "LLM Base URL: $LLM_BASE_URL"
fi
echo "User ID: $SANDBOX_USER_ID"

# クリーンアップ関数を定義
cleanup() {
    echo -e "\nCleaning up resources..."
    docker compose down
    echo "Cleanup complete. Thank you for using OpenHands CLI!"
}

# Ctrl+Cが押された場合のハンドラを設定
trap cleanup EXIT

# Run Docker Compose with terminal attachment
echo "Press Ctrl+C to exit"
docker compose run --rm openhands-cli