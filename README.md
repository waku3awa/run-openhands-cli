# OpenHands CLI with Post-Command Script

このプロジェクトは、OpenHands CLIの実行後に自動的にランタイムコンテナの情報を表示し、ユーザー入力待ちに入る機能を追加したものです。

## ファイル構成

- `compose.yaml`: Docker Composeの設定ファイル
- `post-command.sh`: OpenHands CLI実行後に実行されるスクリプト
- `config.toml`: OpenHandsの設定ファイル（別途作成が必要）

## 機能

1. **Runtime選択**: 起動時に新規runtime作成か既存runtime利用かを選択可能
2. **既存Runtime検索**: 既存のopenhands-runtime-コンテナをリスト表示し、カーソルで選択
3. **OpenHands CLI実行**: 通常のOpenHands CLIが実行されます
4. **コンテナ情報表示**: 実行後に`openhands-runtime-${WORKSPACE_DIR}`コンテナの情報を検索・表示します
5. **コンテナ削除確認**: コンテナが見つかった場合、削除するかユーザーに確認します
6. **自動クリーンアップ**: コンテナ削除時に関連するセッションディレクトリも自動削除します
7. **柔軟なWORKSPACE_DIR指定**: 環境変数または引数でWORKSPACE_DIRを指定可能

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
# run-openhands-cli.shを使用（推奨）
./run-openhands-cli.sh

# または直接Docker Composeを使用
docker-compose up
```

### 3. Runtime選択

スクリプト実行時に以下の選択画面が表示されます：

```
OpenHands Runtime選択
===================
Use ↑/↓ arrow keys (or j/k) to navigate, Enter to confirm, Esc to exit

> 1) 新規runtime(session)を作成
  2) 既存runtime(session)を利用
```

#### 操作方法
- **↑/↓キー** または **j/k キー**: 選択項目の移動
- **1-2キー**: 直接選択（数字キー）
- **Enterキー**: 選択確定
- **Escキー**: キャンセル（スクリプト終了）

#### 新規runtime作成を選択した場合
- 従来通りのワークスペースディレクトリ入力に進みます
- 新しいコンテナとセッションが作成されます

#### 既存runtime利用を選択した場合
- 既存の`openhands-runtime-`で始まるコンテナを検索します
- 見つかった場合：カーソルキー（↑/↓またはj/k）でコンテナを選択
- 見つからない場合：新規作成に自動的に進みます

#### 既存コンテナ選択画面
```
Existing OpenHands Runtime Containers:
=====================================
Use ↑/↓ arrow keys (or j/k) to navigate, 1-9 for quick select, Enter to confirm, Esc to exit

> 1) openhands-runtime-project1-abc123 [Up 2 hours] (Created: 2025-06-03 10:30:00)
  2) openhands-runtime-project2-def456 [Exited (0) 1 hour ago] (Created: 2025-06-03 09:15:00)
```

### 4. WORKSPACE_DIRの指定方法

WORKSPACE_DIRは以下の方法で決定されます：

#### 新規runtime作成の場合
1. **環境変数として指定**
2. **ユーザー入力**（未設定の場合）

#### 既存runtime利用の場合
1. **選択されたコンテナ名から自動抽出**
   - コンテナ名形式：`openhands-runtime-{WORKSPACE_DIR}-{hash}`
   - 例：`openhands-runtime-project1-abc123` → `WORKSPACE_DIR=project1`

Docker Composeでは、環境変数`${WORKSPACE_DIR}`が引数として`post-command.sh`に渡されます。

### 5. 実行後の動作

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

### 6. 表示される情報

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
削除対象コンテナ：
  - openhands-runtime-your-workspace-name-3f82fcb915777f77

削除しますか？ [Y/n]: Y

=== コンテナとセッションデータを削除中 ===
コンテナを停止中: openhands-runtime-your-workspace-name-3f82fcb915777f77
  ⚠️  停止失敗（既に停止している可能性があります）: openhands-runtime-your-workspace-name-3f82fcb915777f77
コンテナを削除中: openhands-runtime-your-workspace-name-3f82fcb915777f77
  ✅ 削除成功: openhands-runtime-your-workspace-name-3f82fcb915777f77

セッションディレクトリを削除中...
  ✅ セッションディレクトリを削除しました: /.openhands-state/sessions/your-workspace-name*

✅ すべての削除が完了しました
```

#### コンテナが見つからない場合
```
❌ 該当するコンテナが見つかりませんでした

すべてのopenhands関連コンテナを表示します：
NAMES                    STATUS    PORTS    IMAGE
openhands-cli           Up        -        openhands:0.8.2
```

### 7. 削除をキャンセルした場合の操作

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
- 既存runtime利用時は、選択されたコンテナのWORKSPACE_DIRが自動的に設定されます
- 既存runtime利用時は、Dockerイメージのpullやディレクトリ作成はスキップされます