#!/bin/bash

# OpenHands CLI実行後のスクリプト
echo "=== OpenHands CLI実行完了 ==="
echo ""

# 引数または環境変数からWORKSPACE_DIRを取得
if [ ! -z "$1" ]; then
    WORKSPACE_DIR="$1"
    echo "WORKSPACE_DIR（引数から取得）: $WORKSPACE_DIR"
elif [ ! -z "$WORKSPACE_DIR" ]; then
    echo "WORKSPACE_DIR（環境変数から取得）: $WORKSPACE_DIR"
else
    echo "警告: WORKSPACE_DIRが引数にも環境変数にも設定されていません"
    WORKSPACE_DIR=""
fi

# コンテナ名の設定
if [ -z "$WORKSPACE_DIR" ]; then
    CONTAINER_NAME="openhands-runtime-*"
else
    CONTAINER_NAME="openhands-runtime-${WORKSPACE_DIR}"
fi

echo "=== コンテナ情報の検索 ==="
echo "検索対象: $CONTAINER_NAME"
echo ""

# コンテナの存在確認と情報表示
if [ -z "$WORKSPACE_DIR" ]; then
    # WORKSPACE_DIRが未設定の場合は、openhands-runtime-で始まるコンテナを検索
    CONTAINERS=$(docker ps -a --filter "name=openhands-runtime-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}")
else
    # WORKSPACE_DIRが設定されている場合は、特定のコンテナを検索
    CONTAINERS=$(docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}")
fi

if [ -z "$CONTAINERS" ] || [ "$CONTAINERS" = "NAMES	STATUS	PORTS	IMAGE" ]; then
    echo "❌ 該当するコンテナが見つかりませんでした"
    echo ""
    echo "すべてのopenhands関連コンテナを表示します："
    docker ps -a --filter "name=openhands" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
else
    echo "✅ 見つかったコンテナ："
    echo "$CONTAINERS"
    echo ""
    
    # 詳細情報の表示
    if [ ! -z "$WORKSPACE_DIR" ]; then
        echo "=== 詳細情報 ==="
        CONTAINER_ID=$(docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.ID}}" | head -1)
        if [ ! -z "$CONTAINER_ID" ]; then
            echo "コンテナID: $CONTAINER_ID"
            echo "作成日時: $(docker inspect --format='{{.Created}}' $CONTAINER_ID)"
            echo "ステータス: $(docker inspect --format='{{.State.Status}}' $CONTAINER_ID)"
            echo "IPアドレス: $(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_ID)"
        fi
    fi
fi

echo ""
echo "=== コンテナの削除確認 ==="

# コンテナが見つかった場合のみ削除確認を行う
if [ ! -z "$CONTAINERS" ] && [ "$CONTAINERS" != "NAMES	STATUS	PORTS	IMAGE" ]; then
    if [ ! -z "$WORKSPACE_DIR" ]; then
        # 実際に見つかったコンテナ名を取得
        ACTUAL_CONTAINER_NAMES=$(docker ps -a --filter "name=openhands-runtime-${WORKSPACE_DIR}" --format "{{.Names}}")
        
        echo "見つかったコンテナを削除しますか？"
        echo "削除対象コンテナ："
        echo "$ACTUAL_CONTAINER_NAMES" | while read container; do
            echo "  - $container"
        done
        echo ""
        echo "削除すると以下も同時に削除されます："
        echo "- セッションディレクトリ: /.openhands-state/sessions/${WORKSPACE_DIR}*"
        echo ""
        read -p "削除しますか？ [Y/n]: " -r
        REPLY=${REPLY:-Y}  # デフォルトをYに設定
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo "=== コンテナとセッションデータを削除中 ==="
            
            # 見つかったすべてのコンテナを停止して削除
            DELETION_SUCCESS=true
            for container in $ACTUAL_CONTAINER_NAMES; do
                if [ ! -z "$container" ]; then
                    echo "コンテナを停止中: $container"
                    if docker stop "$container" 2>/dev/null; then
                        echo "  ✅ 停止成功: $container"
                    else
                        echo "  ⚠️  停止失敗（既に停止している可能性があります）: $container"
                    fi
                    
                    echo "コンテナを削除中: $container"
                    if docker rm "$container" 2>/dev/null; then
                        echo "  ✅ 削除成功: $container"
                    else
                        echo "  ❌ 削除失敗: $container"
                        DELETION_SUCCESS=false
                    fi
                fi
            done
            
            # セッションディレクトリを削除
            echo ""
            echo "セッションディレクトリを削除中..."
            SESSION_DIRS="/.openhands-state/sessions/${WORKSPACE_DIR}*"
            if ls $SESSION_DIRS 1> /dev/null 2>&1; then
                if rm -rf $SESSION_DIRS 2>/dev/null; then
                    echo "  ✅ セッションディレクトリを削除しました: $SESSION_DIRS"
                else
                    echo "  ❌ セッションディレクトリの削除に失敗しました: $SESSION_DIRS"
                    DELETION_SUCCESS=false
                fi
            else
                echo "  ⚠️  セッションディレクトリが見つかりませんでした: $SESSION_DIRS"
            fi
            
            echo ""
            if [ "$DELETION_SUCCESS" = true ]; then
                echo "✅ すべての削除が完了しました"
            else
                echo "⚠️  一部の削除に失敗しました。手動で確認してください。"
            fi
        else
            echo ""
            echo "削除をキャンセルしました"
            echo ""
            echo "Enterキーを押すと終了します..."
            read dummy
        fi
    else
        echo "WORKSPACE_DIRが設定されていないため、削除確認をスキップします"
        echo ""
        echo "Enterキーを押すと終了します..."
        read dummy
    fi
else
    echo "削除対象のコンテナが見つからないため、削除確認をスキップします"
    echo ""
    echo "Enterキーを押すと終了します..."
    read dummy
fi