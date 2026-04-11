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
# 素材写真が縦位置中心 (3840x5760) なので、
# Reels / TikTok / Shorts / Stories 向けの 1080x1920 を既定とする。
# 横長で書き出したい場合は WIDTH/HEIGHT を 1920/1080 に変更すれば
# 同じスクリプトで再生成できます。
WIDTH=1080
HEIGHT=1920
FPS=30

# ==== カラー (料亭・高級和食を想起させる配色) ====
BG_COLOR="0d0d10"          # 漆黒に近い
MAIN_COLOR="f5f1e8"        # 温白（コピー本文）
ACCENT_COLOR="c9a871"      # 金茶（サブコピー・強調）

# ==== パス ====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
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
# フォーマット: duration(秒)|メインコピー|サブコピー|画像ファイル|main_fontsize
#
# main_fontsize は省略可 (省略時 76)。短いブランドコピー等で大きくしたい時に使用。
#
# 画像ファイルは下記の順で検索されます:
#   1) 絶対パスで指定されていればそのまま
#   2) ${IMAGES_DIR}/<指定> (video/assets/images 配下)
#   3) ${REPO_ROOT}/<指定> (リポジトリ直下)
#   4) 見つからなければ黒背景でテキストのみ
#
# 合計 約18秒 (Reels / Shorts / Stories / 比較検討フェーズ向け)
#
# 企画メモ:
#   目的       : 実際の利用シーンを想起させる
#   訴求軸     : 接待・会食・顔合わせ／個室 (寂・清)／席間・導線／静かな会話
#   ターゲット : 30〜50代経営者の接待、40代以上の会食
#   最重要価値 : 失敗しない安心感
SCENES=(
  "3.0|その一席が、関係を決める。|—— 接待・会食・顔合わせ|イメージ_お食事シーン0097.JPG|"
  "3.0|粛然たる、二〜四名の間。|—— 寂 jaku ／ 煉瓦色の壁に、ゆるやかな時|寂-jaku-7C1A1614.JPG|"
  "3.0|美意識で、賓客をもてなす。|—— 清 sei ／ 金泥のやまと絵と雪結晶の床|清-sei-7C1A1622.JPG|"
  "3.0|一献の支度にも、品格を。|—— 選び抜いた、酒と器と|切子グラス0006.JPG|"
  "3.0|献立は、静かに運ばれる。|—— 会話を遮らない、間合い|イメージ_お食事シーン0099.JPG|"
  "3.0|語らう人の、呼吸を遮らない。|—— ゆとりの席間、静かな導線|イメージ_お食事シーン0052.JPG|"
  "3.2|大切な夜に、ふさわしい一軒。|—— 失敗しない、接待・会食の支度|イメージ_お食事シーン0046.JPG|"
  "INFO|5.0||寂-jaku-7C1A1614.JPG"
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
  local spec="$1"
  # 1) 絶対パス
  if [[ "$spec" == /* && -f "$spec" ]]; then
    printf '%s' "$spec"
    return 0
  fi
  # 2) IMAGES_DIR 配下
  if [[ -f "${IMAGES_DIR}/${spec}" ]]; then
    printf '%s' "${IMAGES_DIR}/${spec}"
    return 0
  fi
  # 3) リポジトリ直下
  if [[ -f "${REPO_ROOT}/${spec}" ]]; then
    printf '%s' "${REPO_ROOT}/${spec}"
    return 0
  fi
  # 4) IMAGES_DIR 配下でベース名一致 (拡張子自動補完)
  local ext
  for ext in jpg jpeg png webp JPG JPEG PNG WEBP; do
    if [[ -f "${IMAGES_DIR}/${spec}.${ext}" ]]; then
      printf '%s' "${IMAGES_DIR}/${spec}.${ext}"
      return 0
    fi
  done
  return 1
}

# ==== シーン単体ビルド ====
build_scene() {
  local idx="$1" duration="$2" main="$3" sub="$4" img_spec="$5" main_fs="${6:-}"
  local out="${TMP_DIR}/scene_${idx}.mp4"

  local main_fontsize="${main_fs:-76}"

  local main_esc sub_esc
  main_esc=$(escape_drawtext "$main")
  sub_esc=$(escape_drawtext "$sub")

  local fade_out_start
  fade_out_start=$(awk -v d="$duration" 'BEGIN{printf "%.3f", d-0.6}')

  local input_args=()
  local base_filter
  local img_path
  if img_path=$(find_image "$img_spec"); then
    input_args=(-loop 1 -t "$duration" -i "$img_path")
    # カバーにクロップしシネマ調のグレーディング
    base_filter="scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT},setsar=1"
    base_filter+=",eq=brightness=-0.08:saturation=0.90:contrast=1.06"
    base_filter+=",format=yuv420p"
  else
    # 画像が無ければ黒背景
    input_args=(-f lavfi -t "$duration" -i "color=c=#${BG_COLOR}:s=${WIDTH}x${HEIGHT}:r=${FPS}")
    base_filter="format=yuv420p"
  fi

  local vf="$base_filter"

  # メインコピー (明朝) ― 外枠+ドロップシャドウで可読性を確保 (drawboxは使わない)
  vf+=",drawtext=fontfile='${FONT_MINCHO}':text='${main_esc}'"
  vf+=":fontsize=${main_fontsize}:fontcolor=#${MAIN_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.76-(text_h/2)"
  vf+=":borderw=3:bordercolor=black@0.9"
  vf+=":shadowcolor=black@0.95:shadowx=4:shadowy=4"

  # サブコピー (ゴシック)
  vf+=",drawtext=fontfile='${FONT_GOTHIC}':text='${sub_esc}'"
  vf+=":fontsize=34:fontcolor=#${ACCENT_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.86"
  vf+=":borderw=2:bordercolor=black@0.9"
  vf+=":shadowcolor=black@0.95:shadowx=3:shadowy=3"

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

# ==== 店舗情報シーン (最終ページ) ====
# 大倉山の店舗情報を載せる専用レイアウト。
# 住所・電話・営業時間等は「要入稿」として ○ 表記のプレースホルダ。
# 実情報が確定したら下記の STORE_* を書き換えてください。
STORE_NAME="大嵓埜"
STORE_AREA="横浜・大倉山"
STORE_ADDRESS="神奈川県横浜市港北区大倉山 ○-○-○"
STORE_TEL="045-○○○-○○○○"
STORE_ACCESS="東急東横線 大倉山駅 徒歩○分"
STORE_HOURS="○○:○○ – ○○:○○ (L.O. ○○:○○)"
STORE_CLOSED="○曜日"
STORE_CTA="ご予約はお電話または公式サイトより"

build_info_scene() {
  local idx="$1" duration="$2" img_spec="$3"
  local out="${TMP_DIR}/scene_${idx}.mp4"

  local fade_out_start
  fade_out_start=$(awk -v d="$duration" 'BEGIN{printf "%.3f", d-0.8}')

  local input_args=()
  local base_filter
  local img_path
  if img_path=$(find_image "$img_spec"); then
    input_args=(-loop 1 -t "$duration" -i "$img_path")
    # 画像を背景として残しつつ、強めのぼかし+減光で文字が主役になるよう調整
    base_filter="scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT},setsar=1"
    base_filter+=",boxblur=22:1"
    base_filter+=",eq=brightness=-0.28:saturation=0.55:contrast=1.02"
    base_filter+=",format=yuv420p"
  else
    input_args=(-f lavfi -t "$duration" -i "color=c=#${BG_COLOR}:s=${WIDTH}x${HEIGHT}:r=${FPS}")
    base_filter="format=yuv420p"
  fi

  local vf="$base_filter"

  # 共通 drawtext (外枠+シャドウ付き) ヘルパ
  local shadow=":borderw=2:bordercolor=black@0.9:shadowcolor=black@0.95:shadowx=3:shadowy=3"
  local shadow_thick=":borderw=3:bordercolor=black@0.9:shadowcolor=black@0.95:shadowx=4:shadowy=4"

  # 店舗名 (大嵓埜)
  vf+=",drawtext=fontfile='${FONT_MINCHO}':text='$(escape_drawtext "$STORE_NAME")'"
  vf+=":fontsize=170:fontcolor=#${MAIN_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.12"
  vf+="${shadow_thick}"

  # エリア (横浜・大倉山)
  vf+=",drawtext=fontfile='${FONT_GOTHIC}':text='$(escape_drawtext "$STORE_AREA")'"
  vf+=":fontsize=46:fontcolor=#${ACCENT_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.28"
  vf+="${shadow}"

  # 区切り線
  vf+=",drawtext=fontfile='${FONT_GOTHIC}':text='— — — — — — — — —'"
  vf+=":fontsize=26:fontcolor=#${ACCENT_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.36"
  vf+="${shadow}"

  # 情報ブロック (各行を個別の drawtext で)
  # ラベルと値を分けず、全角スペースで視認性を上げて 1行で描画
  local info_font=32
  local y_start=0.44
  local y_step=0.055
  local lines=(
    "住所　　$STORE_ADDRESS"
    "電話　　$STORE_TEL"
    "アクセス　$STORE_ACCESS"
    "営業　　$STORE_HOURS"
    "定休日　$STORE_CLOSED"
  )
  local i=0
  for line in "${lines[@]}"; do
    local y_expr
    y_expr=$(awk -v s="$y_start" -v st="$y_step" -v i="$i" 'BEGIN{printf "%.4f", s + st*i}')
    vf+=",drawtext=fontfile='${FONT_GOTHIC}':text='$(escape_drawtext "$line")'"
    vf+=":fontsize=${info_font}:fontcolor=#${MAIN_COLOR}"
    vf+=":x=(w-text_w)/2:y=h*${y_expr}"
    vf+="${shadow}"
    i=$((i+1))
  done

  # CTA (フッター)
  vf+=",drawtext=fontfile='${FONT_GOTHIC}':text='$(escape_drawtext "$STORE_CTA")'"
  vf+=":fontsize=32:fontcolor=#${ACCENT_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.85"
  vf+="${shadow}"

  # フェードイン・アウト (少し長めに)
  vf+=",fade=t=in:st=0:d=0.8,fade=t=out:st=${fade_out_start}:d=0.8"

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
  IFS='|' read -r f1 f2 f3 f4 f5 <<< "$scene"
  if [[ "$f1" == "INFO" ]]; then
    # INFO|duration||image
    printf '[%d/%d] scene_%02d  [INFO] %s\n' "$idx" "$total" "$idx" "$STORE_NAME"
    build_info_scene "$(printf '%02d' "$idx")" "$f2" "$f4"
  else
    # duration|main|sub|image|main_fs
    printf '[%d/%d] scene_%02d  %s\n' "$idx" "$total" "$idx" "$f2"
    build_scene "$(printf '%02d' "$idx")" "$f1" "$f2" "$f3" "$f4" "$f5"
  fi
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
