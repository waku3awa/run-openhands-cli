# OpenHands CLI with Post-Command Script

このプロジェクトは、OpenHands CLIの実行後に自動的にランタイムコンテナの情報を表示し、ユーザー入力待ちに入る機能を追加したものです。

## ファイル構成

- `compose.yaml`: Docker Composeの設定ファイル
- `post-command.sh`: OpenHands CLI実行後に実行されるスクリプト
- `config.toml`: OpenHandsの設定ファイル（別途作成が必要）

## 機能

1. **OpenHands CLI実行**: 通常のOpenHands CLIが実行されます
2. **コンテナ情報表示**: 実行後に`openhands-runtime-${WORKSPACE_DIR}`コンテナの情報を検索・表示します
3. **コンテナ削除確認**: コンテナが見つかった場合、削除するかユーザーに確認します
4. **自動クリーンアップ**: コンテナ削除時に関連するセッションディレクトリも自動削除します
5. **柔軟なWORKSPACE_DIR指定**: 環境変数または引数でWORKSPACE_DIRを指定可能

## 使用方法

### 1. 環境変数の設定

以下の環境変数を設定してください：

```bash
export CONTAINER_VERSION="0.8.2"  # または適切なバージョン
export WORKSPACE_DIR="your-workspace-name"
export LLM_API_KEY="your-api-key"
export LLM_MODEL="your-model"
export LLM_BASE_URL="your-base-url"  # 必要に応じて
export SANDBOX_VOLUMES="/path/to/your/workspace"
```

### 2. 実行

```bash
docker-compose up
```

### 3. WORKSPACE_DIRの指定方法

WORKSPACE_DIRは以下の優先順位で決定されます：

1. **引数として指定**（最優先）
2. **環境変数として指定**
3. **未指定**（すべてのopenhands-runtime-で始まるコンテナを検索）

Docker Composeでは、環境変数`${WORKSPACE_DIR}`が引数として`post-command.sh`に渡されます。

### 4. 実行後の動作

OpenHands CLIが終了すると、以下の処理が実行されます：

1. **コンテナ情報の表示**:
   - WORKSPACE_DIRの取得方法（引数/環境変数）
   - コンテナの検索結果
   - 見つかったコンテナの基本情報（名前、ステータス、ポート、イメージ）
   - 詳細情報（コンテナID、作成日時、ステータス、IPアドレス）

2. **削除確認**:
   - コンテナが見つかった場合、削除するかユーザーに確認
   - デフォルトは「Y」（削除する）
   - 「Y」を選択した場合：コンテナとセッションディレクトリを削除
   - 「n」を選択した場合：削除をキャンセルし、操作コマンドを表示

### 5. 表示される情報

#### コンテナが見つかった場合
```
=== OpenHands CLI実行完了 ===

WORKSPACE_DIR（引数から取得）: your-workspace-name

=== コンテナ情報の検索 ===
検索対象: openhands-runtime-your-workspace-name

✅ 見つかったコンテナ：
NAMES                               STATUS    PORTS    IMAGE
openhands-runtime-your-workspace    Up        8000/tcp runtime:0.8.2-nikolaik

=== 詳細情報 ===
コンテナID: abc123def456
作成日時: 2025-06-03T14:00:00.000000000Z
ステータス: running
IPアドレス: 172.17.0.3

=== コンテナの削除確認 ===
見つかったコンテナ 'openhands-runtime-your-workspace-name' を削除しますか？
削除すると以下も同時に削除されます：
- セッションディレクトリ: /.openhands-state/sessions/your-workspace-name*

削除しますか？ [Y/n]: 
```

#### 削除を実行した場合
```
=== コンテナとセッションデータを削除中 ===
コンテナを停止中...
コンテナを削除中...
セッションディレクトリを削除中...
セッションディレクトリを削除しました: /.openhands-state/sessions/your-workspace-name*

✅ 削除が完了しました
```

#### コンテナが見つからない場合
```
❌ 該当するコンテナが見つかりませんでした

すべてのopenhands関連コンテナを表示します：
NAMES                    STATUS    PORTS    IMAGE
openhands-cli           Up        -        openhands:0.8.2
```

### 6. 削除をキャンセルした場合の操作

削除確認で「n」を選択した場合、以下のコマンド例が表示されます：

```bash
# ログを表示
docker logs openhands-runtime-your-workspace-name

# コンテナに接続
docker exec -it openhands-runtime-your-workspace-name /bin/bash

# コンテナを停止
docker stop openhands-runtime-your-workspace-name

# コンテナを削除
docker rm openhands-runtime-your-workspace-name
```

## カスタマイズ

`post-command.sh`スクリプトを編集することで、表示内容や動作をカスタマイズできます。

## 注意事項

- `WORKSPACE_DIR`が引数にも環境変数にも設定されていない場合、警告が表示され、すべてのopenhands-runtime-で始まるコンテナが検索されます
- Docker Composeの実行には、Dockerデーモンが起動している必要があります
- 引数として渡されたWORKSPACE_DIRは環境変数よりも優先されます
- **削除確認のデフォルトは「Y」（削除する）です**。Enterキーを押すだけでコンテナとセッションデータが削除されます
- セッションディレクトリの削除は`/.openhands-state/sessions/${WORKSPACE_DIR}*`パターンで実行されます
- 削除処理は元に戻せないため、重要なデータがある場合は事前にバックアップを取ってください