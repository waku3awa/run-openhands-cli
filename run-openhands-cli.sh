#!/bin/bash

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
DEFAULT_MODEL="anthropic/claude-sonnet-4-20250514"
# DEFAULT_MODEL="gemini/gemini-2.5-pro-exp-03-25"
DEFAULT_CONTAINER_VERSION="0.39"

# Prompt for environment variables if not set
if [ -z "$SANDBOX_VOLUMES" ]; then
    read -p "Enter the directory you want OpenHands to access [default: $DEFAULT_WORKSPACE]: " SANDBOX_VOLUMES
    SANDBOX_VOLUMES=${SANDBOX_VOLUMES:-$DEFAULT_WORKSPACE}
    export SANDBOX_VOLUMES
fi

if [ -z "$LLM_MODEL" ]; then
    read -p "Enter the LLM model to use [default: $DEFAULT_MODEL]: " LLM_MODEL
    LLM_MODEL=${LLM_MODEL:-$DEFAULT_MODEL}
    export LLM_MODEL
fi

if [ -z "$LLM_API_KEY" ]; then
    read -p "Enter your LLM API key: " LLM_API_KEY
    if [ -z "$LLM_API_KEY" ]; then
        echo "API key is required. Exiting."
        exit 1
    fi
    export LLM_API_KEY
fi

if [ -z "$CONTAINER_VERSION" ]; then
    read -p "Enter the container version to use [default: $DEFAULT_CONTAINER_VERSION]: " CONTAINER_VERSION
    CONTAINER_VERSION=${CONTAINER_VERSION:-$DEFAULT_CONTAINER_VERSION}
    export CONTAINER_VERSION
fi

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

# Set user ID for correct file permissions
export SANDBOX_USER_ID=$(id -u)

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

echo "Starting OpenHands CLI mode with the following configuration:"
echo "Workspace: $SANDBOX_VOLUMES"
echo "LLM Model: $LLM_MODEL"
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