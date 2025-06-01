#!/bin/bash

# ヘルプ表示関数
show_help() {
    cat << EOF
take_screenshot.sh - ウィンドウスクリーンショット撮影ツール

使用方法:
    ./take_screenshot.sh [オプション] <ウィンドウタイトル>

説明:
    指定されたウィンドウタイトルのスクリーンショットを撮影し、
    タイムスタンプ付きのファイル名で保存します。

引数:
    <ウィンドウタイトル>    撮影対象のウィンドウタイトル（完全一致）

オプション:
    -h, --help             このヘルプメッセージを表示

出力:
    スクリーンショットは ./.window_screenshots/ ディレクトリに保存されます。
    ファイル名形式: screenshot_YYYYMMDD_HHMMSS_XXXXXX.png
    
    成功時: 保存されたファイルパスを標準出力に表示
    失敗時: エラーメッセージを標準エラー出力に表示（終了コード1）

使用例:
    ./take_screenshot.sh "Python Turtle Graphics"
    ./take_screenshot.sh "Firefox"
    ./take_screenshot.sh --help

必要なツール:
    - xwininfo (X11ウィンドウ情報取得)
    - import (ImageMagickスクリーンショット撮影)

注意事項:
    - ウィンドウタイトルは完全一致で検索されます
    - 同名のウィンドウが複数ある場合、最初に見つかったものが対象になります
    - DISPLAY環境変数が適切に設定されている必要があります

EOF
}

# 引数チェック
if [ $# -eq 0 ]; then
    echo "Error: ウィンドウタイトルが指定されていません。" >&2
    echo "使用方法については './take_screenshot.sh --help' を実行してください。" >&2
    exit 1
fi

# ヘルプオプションのチェック
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
esac

# 引数: ウィンドウタイトル（完全一致）
TARGET_NAME="$1"

# スクリーンショット出力先ディレクトリ
OUTPUT_DIR="./.window_screenshots"
mkdir -p "$OUTPUT_DIR"

# ランダム6桁の数字を生成（先頭0を保つ）
RAND_DIGITS=$(printf "%06d" $(( RANDOM % 1000000 )))

# 日時＋ランダム数字でファイル名作成
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")_"${RAND_DIGITS}"
FILENAME="screenshot_${TIMESTAMP}.png"
OUTPUT_PATH="${OUTPUT_DIR}/${FILENAME}"

# ウィンドウIDを取得
WIN_ID=$(xwininfo -root -tree | awk -v title="$TARGET_NAME" '
    $0 ~ title {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^0x/) {
                print $i;
                exit;
            }
        }
    }')

# ウィンドウIDが見つからない場合はエラー
if [ -z "$WIN_ID" ]; then
    echo "Error: ウィンドウ名 \"$TARGET_NAME\" が見つかりません。" >&2
    exit 1
fi

# importでスクリーンショットを撮影
import -window "$WIN_ID" "$OUTPUT_PATH"

# 結果のファイルパスを標準出力
echo "$OUTPUT_PATH"
