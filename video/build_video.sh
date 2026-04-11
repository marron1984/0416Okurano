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

FONT_MINCHO_LIGHT=$(find_font "明朝細" \
  "${SCRIPT_DIR}/assets/fonts/NotoSerifJP-Light.otf" \
  "${SCRIPT_DIR}/assets/fonts/NotoSerifJP-Regular.otf" \
  "/usr/share/fonts/opentype/ipafont-mincho/ipam.ttf")

FONT_MINCHO=$(find_font "明朝" \
  "${SCRIPT_DIR}/assets/fonts/NotoSerifJP-Regular.otf" \
  "/usr/share/fonts/opentype/ipafont-mincho/ipam.ttf" \
  "/usr/share/fonts/truetype/fonts-japanese-mincho.ttf" \
  "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc" \
  "/Library/Fonts/YuMincho.ttc" \
  "C:/Windows/Fonts/yumin.ttf")

FONT_MINCHO_BOLD=$(find_font "明朝太字" \
  "${SCRIPT_DIR}/assets/fonts/NotoSerifJP-SemiBold.otf" \
  "${SCRIPT_DIR}/assets/fonts/NotoSerifJP-Regular.otf" \
  "/usr/share/fonts/opentype/ipafont-mincho/ipam.ttf")

FONT_GOTHIC_LIGHT=$(find_font "ゴシック細" \
  "${SCRIPT_DIR}/assets/fonts/NotoSansJP-Light.otf" \
  "${SCRIPT_DIR}/assets/fonts/NotoSansJP-Regular.otf" \
  "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf")

FONT_GOTHIC=$(find_font "ゴシック" \
  "${SCRIPT_DIR}/assets/fonts/NotoSansJP-Regular.otf" \
  "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf" \
  "/usr/share/fonts/truetype/fonts-japanese-gothic.ttf" \
  "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc" \
  "/Library/Fonts/YuGothic.ttc" \
  "C:/Windows/Fonts/YuGothR.ttc")

FONT_GOTHIC_MEDIUM=$(find_font "ゴシック中太" \
  "${SCRIPT_DIR}/assets/fonts/NotoSansJP-Medium.otf" \
  "${SCRIPT_DIR}/assets/fonts/NotoSansJP-Regular.otf" \
  "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf")

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
  "INFO|7.0||寂-jaku-7C1A1614.JPG"
)

# ==== drawtext 用エスケープ ====
escape_drawtext() {
  # ffmpeg の filtergraph → drawtext の二重パース対策で、
  # % は '\\%' の 2 バックスラッシュ付きで埋め込む必要がある。
  # (filtergraph parser が \\ → \, さらに drawtext が \% → % と解釈)
  local s="$1"
  s=${s//\\/\\\\}     # backslash 先に倍化
  s=${s//%/\\\\%}     # % → \\%
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

  # メインコピー (明朝 Light) ― 縁取りは最小限、影で立体感を出す
  vf+=",drawtext=fontfile='${FONT_MINCHO_LIGHT}':text='${main_esc}'"
  vf+=":fontsize=${main_fontsize}:fontcolor=#${MAIN_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.76-(text_h/2)"
  vf+=":borderw=1:bordercolor=black@0.7"
  vf+=":shadowcolor=black@0.85:shadowx=3:shadowy=5"

  # サブコピー (ゴシック Light)
  vf+=",drawtext=fontfile='${FONT_GOTHIC_LIGHT}':text='${sub_esc}'"
  vf+=":fontsize=34:fontcolor=#${ACCENT_COLOR}"
  vf+=":x=(w-text_w)/2:y=h*0.86"
  vf+=":borderw=1:bordercolor=black@0.7"
  vf+=":shadowcolor=black@0.85:shadowx=2:shadowy=4"

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
# 実店舗情報 (提供データより)
STORE_NAME_LABEL="店名"
STORE_NAME="北新地･懐石料理 大嵓埜"
STORE_ADDR_LABEL="住所"
STORE_ADDR_ZIP="〒530-0012"
STORE_ADDR_LINE1="大阪府大阪市北区曽根崎新地1-3-23"
STORE_ADDR_LINE2="北新地FOODEARビル3階"
STORE_TEL_LABEL="電話番号"
STORE_TEL="06-6341-3535"
STORE_HOURS_LABEL="営業時間"
STORE_HOURS_DAY="【昼の部】11時半〜平日14時・土曜15時"
STORE_HOURS_NIGHT="【夜の部】17時半〜22時半"
STORE_CLOSED_LABEL="定休日"
STORE_CLOSED_LINE1="日曜・祝日"
STORE_CLOSED_LINE2="※年末年始他、臨時休業有り"
STORE_SERVICE_LABEL="サービス料"
STORE_SERVICE="10%"

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
    base_filter+=",boxblur=24:1"
    base_filter+=",eq=brightness=-0.32:saturation=0.50:contrast=1.02"
    base_filter+=",format=yuv420p"
  else
    input_args=(-f lavfi -t "$duration" -i "color=c=#${BG_COLOR}:s=${WIDTH}x${HEIGHT}:r=${FPS}")
    base_filter="format=yuv420p"
  fi

  local vf="$base_filter"

  # 共通 drawtext 装飾 ―― 情報カードは背景を大きくぼかしているので
  # 縁取りはごく薄く、シャドウだけで空気感を残す。
  local shadow=":borderw=1:bordercolor=black@0.55:shadowcolor=black@0.85:shadowx=2:shadowy=3"

  # 行を 1 本追加するヘルパ ――  drawtext を vf に連結する
  # $1 = font $2 = text $3 = fontsize $4 = color $5 = y 比率
  add_line() {
    local font="$1" text="$2" size="$3" color="$4" yratio="$5"
    vf+=",drawtext=fontfile='${font}':text='$(escape_drawtext "$text")'"
    vf+=":fontsize=${size}:fontcolor=#${color}"
    vf+=":x=(w-text_w)/2:y=h*${yratio}"
    vf+="${shadow}"
  }

  # ---- レイアウト (1080x1920) ----
  # ユーザー指定の体裁:
  #   [ラベル]  ← 小 ゴシック 金
  #   [値]      ← 大 明朝(店名のみ) / ゴシック(他)
  #   [空白]
  # これを 6 セクション縦積み。

  # セクション Y 位置 (比率)。各ラベルの基準位置
  local L1=0.08   # 店名
  local L2=0.19   # 住所
  local L3=0.36   # 電話番号
  local L4=0.44   # 営業時間
  local L5=0.58   # 定休日
  local L6=0.71   # サービス料

  # ラベルと値の相対オフセット
  local DL=0.035  # ラベル→値 の縦オフセット

  # ① 店名 (明朝 Regular / 重くなりすぎないように SemiBold は使わない)
  add_line "$FONT_GOTHIC_LIGHT" "$STORE_NAME_LABEL" 28 "$ACCENT_COLOR" "$L1"
  local l1_value
  l1_value=$(awk -v l="$L1" -v d="$DL" 'BEGIN{printf "%.4f", l+d}')
  add_line "$FONT_MINCHO" "$STORE_NAME" 56 "$MAIN_COLOR" "$l1_value"

  # ② 住所 (2行)
  add_line "$FONT_GOTHIC_LIGHT" "$STORE_ADDR_LABEL" 28 "$ACCENT_COLOR" "$L2"
  local l2_v1 l2_v2 l2_v3
  l2_v1=$(awk -v l="$L2" -v d="$DL" 'BEGIN{printf "%.4f", l+d}')
  l2_v2=$(awk -v l="$L2" -v d="$DL" 'BEGIN{printf "%.4f", l+d+0.035}')
  l2_v3=$(awk -v l="$L2" -v d="$DL" 'BEGIN{printf "%.4f", l+d+0.070}')
  add_line "$FONT_GOTHIC" "$STORE_ADDR_ZIP" 32 "$MAIN_COLOR" "$l2_v1"
  add_line "$FONT_GOTHIC" "$STORE_ADDR_LINE1" 32 "$MAIN_COLOR" "$l2_v2"
  add_line "$FONT_GOTHIC" "$STORE_ADDR_LINE2" 32 "$MAIN_COLOR" "$l2_v3"

  # ③ 電話番号
  add_line "$FONT_GOTHIC_LIGHT" "$STORE_TEL_LABEL" 28 "$ACCENT_COLOR" "$L3"
  local l3_v
  l3_v=$(awk -v l="$L3" -v d="$DL" 'BEGIN{printf "%.4f", l+d}')
  add_line "$FONT_GOTHIC" "$STORE_TEL" 42 "$MAIN_COLOR" "$l3_v"

  # ④ 営業時間 (2行)
  add_line "$FONT_GOTHIC_LIGHT" "$STORE_HOURS_LABEL" 28 "$ACCENT_COLOR" "$L4"
  local l4_v1 l4_v2
  l4_v1=$(awk -v l="$L4" -v d="$DL" 'BEGIN{printf "%.4f", l+d}')
  l4_v2=$(awk -v l="$L4" -v d="$DL" 'BEGIN{printf "%.4f", l+d+0.035}')
  add_line "$FONT_GOTHIC" "$STORE_HOURS_DAY" 30 "$MAIN_COLOR" "$l4_v1"
  add_line "$FONT_GOTHIC" "$STORE_HOURS_NIGHT" 30 "$MAIN_COLOR" "$l4_v2"

  # ⑤ 定休日 (2行)
  add_line "$FONT_GOTHIC_LIGHT" "$STORE_CLOSED_LABEL" 28 "$ACCENT_COLOR" "$L5"
  local l5_v1 l5_v2
  l5_v1=$(awk -v l="$L5" -v d="$DL" 'BEGIN{printf "%.4f", l+d}')
  l5_v2=$(awk -v l="$L5" -v d="$DL" 'BEGIN{printf "%.4f", l+d+0.030}')
  add_line "$FONT_GOTHIC" "$STORE_CLOSED_LINE1" 32 "$MAIN_COLOR" "$l5_v1"
  add_line "$FONT_GOTHIC_LIGHT" "$STORE_CLOSED_LINE2" 24 "$ACCENT_COLOR" "$l5_v2"

  # ⑥ サービス料
  add_line "$FONT_GOTHIC_LIGHT" "$STORE_SERVICE_LABEL" 28 "$ACCENT_COLOR" "$L6"
  local l6_v
  l6_v=$(awk -v l="$L6" -v d="$DL" 'BEGIN{printf "%.4f", l+d}')
  add_line "$FONT_GOTHIC" "$STORE_SERVICE" 32 "$MAIN_COLOR" "$l6_v"

  # 下部にブランドフット (区切り + 大嵓埜)
  add_line "$FONT_GOTHIC_LIGHT" "— — — — — — — — —" 22 "$ACCENT_COLOR" "0.84"
  add_line "$FONT_MINCHO" "大嵓埜" 66 "$MAIN_COLOR" "0.87"

  # フェードイン・アウト
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
