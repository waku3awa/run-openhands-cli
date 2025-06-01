# GUI環境セットアップガイド

このドキュメントでは、GUIアプリケーション（TkinterやTurtleグラフィックスなど）を実行するための環境設定手順を説明します。

## 概要

GUIアプリケーションを実行しようとすると、以下のようなエラーが発生することがあります：

```
_tkinter.TclError: no display name and no $DISPLAY environment variable
```

この問題を解決するために、以下の2つの方法があります：

1. **DISPLAY環境変数の設定**（推奨）: 既存のディスプレイサーバーを利用
2. **仮想ディスプレイの作成**: Xvfb（X Virtual Framebuffer）を使用して仮想ディスプレイを作成

まず方法1を試し、それが利用できない場合に方法2を使用することを推奨します。

## 方法1: DISPLAY環境変数の設定（推奨）

多くの環境では、既存のディスプレイサーバー（WSLg、X11など）が利用可能です。この場合、DISPLAY環境変数を適切に設定するだけでGUIアプリケーションを実行できます。

### Step 1: ディスプレイサーバーの確認

```bash
# 利用可能なディスプレイの確認
echo $DISPLAY

# X11サーバーの情報確認（利用可能な場合）
xdpyinfo 2>/dev/null | head -5
```

### Step 2: DISPLAY環境変数の設定

```bash
# 一般的なディスプレイ設定（WSL環境など）
export DISPLAY=:0
```

### Step 3: GUIアプリケーションの実行

```bash
# 例：Pythonのturtleグラフィックス
export DISPLAY=:0 && python main.py
```

### 動作確認

```bash
# ウィンドウ情報の確認（X11ツールが利用可能な場合）
export DISPLAY=:0 && xwininfo -root -tree 2>/dev/null
```

**この方法が成功した場合、以下の「方法2」は不要です。**

---

## 方法2: 仮想ディスプレイのセットアップ

方法1でGUIが表示されない場合、または完全にヘッドレス環境の場合は、Xvfb（X Virtual Framebuffer）を使用して仮想ディスプレイを作成します。

## 必要なツール

### 1. Xvfb（X Virtual Framebuffer）
仮想ディスプレイサーバーを提供するツール

### 2. X11関連ツール
- `xwininfo`: ウィンドウ情報を取得
- `import`: ImageMagickのスクリーンショット撮影ツール

## セットアップ手順

### Step 1: 必要なツールの確認

```bash
# Xvfbの存在確認
which Xvfb

# X11ツールの確認
which xwininfo && which import
```

### Step 2: 仮想ディスプレイの起動

```bash
# 仮想ディスプレイを起動（ディスプレイ番号:99、解像度1024x768、色深度24bit）
Xvfb :99 -screen 0 1024x768x24 &
```

**パラメータ説明:**
- `:99`: ディスプレイ番号（通常は99を使用）
- `-screen 0 1024x768x24`: スクリーン0に1024x768解像度、24bit色深度を設定

### Step 3: DISPLAY環境変数の設定

```bash
# 環境変数を設定して仮想ディスプレイを使用
export DISPLAY=:99
```

### Step 4: GUIアプリケーションの実行

```bash
# 例：Pythonのturtleグラフィックス
export DISPLAY=:99 && python main.py &
```

## 動作確認

### ウィンドウの確認

```bash
# 開いているウィンドウの一覧を表示
export DISPLAY=:99 && xwininfo -root -tree
```

### スクリーンショットの撮影

```bash
# 特定のウィンドウのスクリーンショットを撮影
export DISPLAY=:99 && ./take_screenshot.sh "ウィンドウタイトル"
```

## クリーンアップ

### プロセスの終了

```bash
# GUIアプリケーションの終了
export DISPLAY=:99 && pkill -f "python main.py"

# Xvfbプロセスの終了
pkill Xvfb
```

## トラブルシューティング

### よくあるエラーと対処法

#### 1. ソケット作成エラー
```
_XSERVTransSocketCreateListener: failed to bind listener
```

**対処法:** 
- 既存のXvfbプロセスを終了してから再起動
- 異なるディスプレイ番号を使用（例：:98、:100など）

#### 2. 権限エラー
```
_XSERVTransmkdir: Mode of /tmp/.X11-unix should be set to 1777
```

**対処法:**
- 通常は警告のみで動作に影響なし
- 必要に応じて`/tmp/.X11-unix`の権限を確認

#### 3. ウィンドウが見つからない
```
Error: ウィンドウ名 "ウィンドウタイトル" が見つかりません。
```

**対処法:**
- `xwininfo -root -tree`でウィンドウタイトルを確認
- 完全一致が必要なため、正確なタイトルを指定

## 使用例

### 方法1を使用した場合（推奨）

```bash
# 1. DISPLAY環境変数の設定とGUIアプリ起動
export DISPLAY=:0 && python main.py &

# 2. ウィンドウ確認（X11ツールが利用可能な場合）
export DISPLAY=:0 && sleep 3 && xwininfo -root -tree 2>/dev/null

# 3. アプリケーション終了
export DISPLAY=:0 && pkill -f "python main.py"
```

### 方法2を使用した場合（仮想ディスプレイ）

```bash
# 1. 仮想ディスプレイ起動
Xvfb :99 -screen 0 1024x768x24 &

# 2. 環境変数設定とGUIアプリ起動
export DISPLAY=:99 && python main.py &

# 3. ウィンドウ確認
export DISPLAY=:99 && sleep 3 && xwininfo -root -tree

# 4. スクリーンショット撮影
export DISPLAY=:99 && ./take_screenshot.sh "Python Turtle Graphics"

# 5. クリーンアップ
export DISPLAY=:99 && pkill -f "python main.py" && pkill Xvfb
```

## 注意事項

### 方法1（DISPLAY環境変数設定）の場合
- WSL環境などでは、GUIがWindows側に表示される場合があります
- 環境によってはX11転送が必要な場合があります

### 方法2（仮想ディスプレイ）の場合
- 仮想ディスプレイは物理的な表示を行わないため、実際の画面には何も表示されません
- スクリーンショット撮影により、GUIの状態を確認できます
- 複数の仮想ディスプレイを同時に使用する場合は、異なるディスプレイ番号を使用してください
- プロセス終了時は適切にクリーンアップを行ってください

## 参考情報

- Xvfb: X Virtual Framebuffer
- ImageMagick: スクリーンショット撮影ツール
- X11: Unix系OSのウィンドウシステム