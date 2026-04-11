#!/usr/bin/env bash
#
# build_video.sh
#
# 大嵓埜 (Okurano) - 比較検討②週 プロモーション動画ジェネレーター
#
# 企画:
#   目的       : 実際の利用シーンを想起させる
#   訴求軸     : 接待・会食・顔合わせ／個室・席間・導線／静かな会話のしやすさ
#   ターゲット : 30〜50代経営者の接待、40代以上の会食
#   最重要価値 : 失敗しない安心感
#
# 必要なもの:
#   - ffmpeg (apt install ffmpeg / brew install ffmpeg)
#   - 日本語フォント (IPA明朝 / IPAゴシック など)
#       Ubuntu: apt install fonts-ipafont-mincho fonts-ipafont-gothic
#       macOS : /System/Library/Fonts 以下に標準搭載
#
# 使い方:
#   1) video/assets/images/ に下記ベース名の画像を配置 (任意・後から差替え可)
#        01_hero     … 店舗外観・暖簾など「掴み」
#        02_koshitsu … 個室の設え
#        03_seat     … 席間・導線がわかる引き
#        04_meal     … 料理・会食の雰囲気
#        05_logo     … ロゴ・サイン・締めの絵
#      拡張子は .jpg .jpeg .png .webp いずれでも可
#      画像が無いシーンは黒背景+テキストのみで生成されます
#
#   2) bash video/build_video.sh
#
#   3) 完成品: video/output/okurano_week3.mp4
#
set -euo pipefail

# ==== 出力設定 ====
WIDTH=1920
HEIGHT=1080
FPS=30

# ==== カラー (料亭・高級和食を想起させる配色) ====
BG_COLOR="0d0d10"          # 漆黒に近い
MAIN_COLOR="f5f1e8"        # 温白（コピー本文）
ACCENT_COLOR="c9a871"      # 金茶（サブコピー・強調）

# ==== パス ====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES_DIR="${SCRIPT_DIR}/assets/images"
OUT_DIR="${SCRIPT_DIR}/output"
TMP_DIR="${OUT_DIR}/.scenes"
OUT_FILE="${OUT_DIR}/okurano_week3.mp4"

mkdir -p "$IMAGES_DIR" "$OUT_DIR" "$TMP_DIR"

# ==== 日本語フォント自動検出 ====
find_font() {
  local name="$1"; shift
  local f
  for f in "$@"; do
    if [[ -f "$f" ]]; then
      printf '%s' "$f"
      return 0
    fi
  done
  echo "エラー: ${name}フォントが見つかりませんでした。" >&2
  echo "       build_video.sh 内の FONT_* を環境に合わせて指定してください。" >&2
  return 1
}

FONT_MINCHO=$(find_font "明朝" \
  "/usr/share/fonts/opentype/ipafont-mincho/ipam.ttf" \
  "/usr/share/fonts/truetype/fonts-japanese-mincho.ttf" \
  "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc" \
  "/Library/Fonts/YuMincho.ttc" \
  "C:/Windows/Fonts/yumin.ttf")

FONT_GOTHIC=$(find_font "ゴシック" \
  "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf" \
  "/usr/share/fonts/truetype/fonts-japanese-gothic.ttf" \
  "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc" \
  "/Library/Fonts/YuGothic.ttc" \
  "C:/Windows/Fonts/YuGothR.ttc")

# ==== シーン台本 ====
# フォーマット: duration(秒)|メインコピー|サブコピー|画像ベース名
# 合計 15 秒 (SNS フィード/リール/TrueViewバンパー前半に最適化)
SCENES=(
  "3.0|その一席が、関係を決める。|—— 接待・会食・顔合わせ|01_hero"
  "3.0|静けさは、もてなしになる。|—— 完全個室、声の通りまで設えの内に|02_koshitsu"
  "3.0|語らう人の、呼吸を遮らない。|—— ゆとりの席間、配慮の行き届いた導線|03_seat"
  "3.0|選ばれ続けた、大人の会食。|—— 30〜50代の経営者、40代からの顔合わせに|04_meal"
  "3.0|大嵓埜|—— 失敗しない、会食の一軒。|05_logo"
)

# ==== drawtext 用エスケープ ====
escape_drawtext() {
  # バックスラッシュ → コロン → カンマ → 単一引用符 の順で置換
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//:/\\:}
  s=${s//,/\\,}
  s=${s//\'/\\\'}
  printf '%s' "$s"
}

# ==== 画像検出 ====
find_image() {
  local base="$1" ext
  for ext in jpg jpeg png webp JPG JPEG PNG WEBP; do
    if [[ -f "${IMAGES_DIR}/${base}.${ext}" ]]; then
      printf '%s' "${IMAGES_DIR}/${base}.${ext}"
      return 0
    fi
  done
  return 1
}

# ==== シーン単体ビルド ====
build_scene() {
  local idx="$1" duration="$2" main="$3" sub="$4" img_base="$5"
  local out="${TMP_DIR}/scene_${idx}.mp4"

  local main_esc sub_esc
  main_esc=$(escape_drawtext "$main")
  sub_esc=$(escape_drawtext "$sub")

  local fade_out_start
  fade_out_start=$(awk -v d="$duration" 'BEGIN{printf "%.3f", d-0.6}')

  local input_args=()
  local base_filter
  if img_path=$(find_image "$img_base"); then
    input_args=(-loop 1 -t "$duration" -i "$img_path")
    # カバーにクロップし、シネマ調の軽いグレーディングと緩慢なズーム
    base_filter="scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT}"
    base_filter+=",eq=brightness=-0.08:saturation=0.88:contrast=1.05"
    base_filter+=",zoompan=z='min(pzoom+0.0008,1.08)':d=1:s=${WIDTH}x${HEIGHT}:fps=${FPS}"
  else
    # 画像が無ければ黒背景
    input_args=(-f lavfi -t "$duration" -i "color=c=#${BG_COLOR}:s=${WIDTH}x${HEIGHT}:r=${FPS}")
    base_filter="format=yuv420p"
  fi

  local vf="$base_filter"

  # 下半分に暗いグラデーションボックス（可読性担保）
  vf+=",drawbox=x=0:y=ih*0.52:w=iw:h=ih*0.48:color=black@0.45:t=fill"

  # メインコピー (明朝)
  vf+=",drawtext=fontfile='${FONT_MINCHO}':text='${main_esc}'"
  vf+=":fontsize=92:fontcolor=#${MAIN_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.62"
  vf+=":shadowcolor=black@0.85:shadowx=3:shadowy=3"

  # サブコピー (ゴシック)
  vf+=",drawtext=fontfile='${FONT_GOTHIC}':text='${sub_esc}'"
  vf+=":fontsize=40:fontcolor=#${ACCENT_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.62+130"
  vf+=":shadowcolor=black@0.85:shadowx=2:shadowy=2"

  # フェードイン・フェードアウト
  vf+=",fade=t=in:st=0:d=0.6,fade=t=out:st=${fade_out_start}:d=0.6"

  ffmpeg -y -hide_banner -loglevel error \
    "${input_args[@]}" \
    -vf "$vf" \
    -c:v libx264 -preset medium -crf 20 \
    -pix_fmt yuv420p -r "$FPS" \
    -an \
    "$out"
}

# ==== 全シーン生成 ====
: > "${TMP_DIR}/concat.txt"
total=${#SCENES[@]}
idx=0
for scene in "${SCENES[@]}"; do
  idx=$((idx + 1))
  IFS='|' read -r dur main sub img <<< "$scene"
  printf '[%d/%d] scene_%02d  %s\n' "$idx" "$total" "$idx" "$main"
  build_scene "$(printf '%02d' "$idx")" "$dur" "$main" "$sub" "$img"
  printf "file 'scene_%02d.mp4'\n" "$idx" >> "${TMP_DIR}/concat.txt"
done

# ==== 連結 ====
echo "連結中..."
ffmpeg -y -hide_banner -loglevel error \
  -f concat -safe 0 -i "${TMP_DIR}/concat.txt" \
  -c copy "$OUT_FILE"

# 中間ファイル掃除
rm -rf "$TMP_DIR"

echo "完成: $OUT_FILE"
ls -lh "$OUT_FILE"
