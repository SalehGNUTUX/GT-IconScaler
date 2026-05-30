#!/usr/bin/env bash
# ============================================================
#  GT-IconScaler v2.2 — CLI
#  توليد أيقونات شاملة لـ 8 منصات (38 مقاساً)
#  Generate comprehensive icons for 8 platforms (38 sizes)
#
#  © 2025-2026 GNUtux — GPLv3 or later
# ============================================================

set -euo pipefail
IFS=$'\n\t'

VERSION="2.2.0"

# ────────────────────────────────────────────────────────────
#  تحميل المكتبات (lib/) — السكربت يجد نفسه عبر BASH_SOURCE
# ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

if [[ ! -f "$LIB_DIR/gt-iconscaler-core.sh" ]]; then
    # عند التثبيت إلى ~/.local/bin أو /usr/local/bin يكون LIB_DIR في share/
    for candidate in \
        "$HOME/.local/share/gt-iconscaler/lib" \
        "/usr/local/share/gt-iconscaler/lib" \
        "/usr/share/gt-iconscaler/lib"; do
        if [[ -f "$candidate/gt-iconscaler-core.sh" ]]; then
            LIB_DIR="$candidate"
            break
        fi
    done
fi

if [[ ! -f "$LIB_DIR/gt-iconscaler-core.sh" ]]; then
    echo "Error: GT-IconScaler libraries not found." >&2
    echo "Looked in: $SCRIPT_DIR/lib and standard install paths." >&2
    exit 1
fi

# shellcheck source=lib/gt-iconscaler-i18n.sh
source "$LIB_DIR/gt-iconscaler-i18n.sh"
# shellcheck source=lib/gt-iconscaler-core.sh
source "$LIB_DIR/gt-iconscaler-core.sh"
# shellcheck source=lib/gt-iconscaler-formats.sh
source "$LIB_DIR/gt-iconscaler-formats.sh"

# ────────────────────────────────────────────────────────────
#  معالجة وسائط سطر الأوامر (تشمل علامات batch v3.0)
# ────────────────────────────────────────────────────────────
LANG_OVERRIDE=""
ACTION="run"
BATCH_ICON=""
BATCH_OUTPUT=""
BATCH_NAME=""
BATCH_PLATFORMS=""
BATCH_COMPRESS=""
JSON_MODE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)         ACTION="help" ;;
        -v|--version)      ACTION="version" ;;
        --lang=*)          LANG_OVERRIDE="${1#--lang=}" ;;
        --lang)            shift; LANG_OVERRIDE="${1:-}" ;;
        --icon=*)          BATCH_ICON="${1#--icon=}" ;;
        --icon)            shift; BATCH_ICON="${1:-}" ;;
        --output=*)        BATCH_OUTPUT="${1#--output=}" ;;
        --output)          shift; BATCH_OUTPUT="${1:-}" ;;
        --name=*)          BATCH_NAME="${1#--name=}" ;;
        --name)            shift; BATCH_NAME="${1:-}" ;;
        --platforms=*)     BATCH_PLATFORMS="${1#--platforms=}" ;;
        --platforms)       shift; BATCH_PLATFORMS="${1:-}" ;;
        --compress=*)      BATCH_COMPRESS="${1#--compress=}" ;;
        --compress)        shift; BATCH_COMPRESS="${1:-}" ;;
        --json)            JSON_MODE=1 ;;
        *) echo "Unknown option: $1" >&2; ACTION="help"; ;;
    esac
    shift
done

gt_i18n_init "$LANG_OVERRIDE"

# ────────────────────────────────────────────────────────────
#  الألوان والطباعة (تُكتم في JSON_MODE عدا الأخطاء)
# ────────────────────────────────────────────────────────────
RED='\033[0;31m'; YEL='\033[1;33m'; GRN='\033[0;32m'
CYN='\033[0;36m'; BLD='\033[1m'; RST='\033[0m'
if (( JSON_MODE )); then
    info()    { :; }
    success() { :; }
    warn()    { echo "WARN: $*" >&2; }
    err()     { echo "ERROR: $*" >&2; }
    header()  { :; }
else
    info()    { echo -e "${CYN}ℹ ${RST}$*"; }
    success() { echo -e "${GRN}✅ ${RST}$*"; }
    warn()    { echo -e "${YEL}⚠️  ${RST}$*"; }
    err()     { echo -e "${RED}❌ ${RST}$*" >&2; }
    header()  { echo -e "\n${BLD}${CYN}══ $* ══${RST}"; }
fi

# ────────────────────────────────────────────────────────────
#  --help / --version
# ────────────────────────────────────────────────────────────
show_help() {
    t help.usage "$(basename "$0")"
    echo ""
    t help.options
    t help.opt.help
    t help.opt.version
    t help.opt.lang
    t help.opt.icon
    t help.opt.output
    t help.opt.name
    t help.opt.platforms
    t help.opt.compress
    t help.opt.json
    echo ""
    t help.batch_note
    echo ""
    t help.env
    t help.env.gt_lang
    t help.env.lang
    exit 0
}

show_version() {
    t version.line "$VERSION"
    exit 0
}

[[ "$ACTION" == "help" ]]    && show_help
[[ "$ACTION" == "version" ]] && show_version

# ────────────────────────────────────────────────────────────
#  فحص ImageMagick
# ────────────────────────────────────────────────────────────
if ! gt_im_cmd &>/dev/null; then
    err "$(t error.no_imagemagick)"
    t error.no_imagemagick.debian
    t error.no_imagemagick.fedora
    t error.no_imagemagick.arch
    exit 1
fi

# ────────────────────────────────────────────────────────────
#  أدوات اختيار الملفات (CLI مع تراجع zenity/kdialog/yad)
# ────────────────────────────────────────────────────────────
file_picker() {
    local title="$1"
    local filter
    filter=$(t gui.filter.images)
    if command -v zenity &>/dev/null; then
        zenity --file-selection --file-filter="$filter" --title="$title" 2>/dev/null
    elif command -v kdialog &>/dev/null; then
        kdialog --getopenfilename . "*.png *.svg *.jpg *.jpeg *.webp" 2>/dev/null
    elif command -v yad &>/dev/null; then
        yad --file-selection --file-filter="$filter" --title="$title" 2>/dev/null
    else
        warn "$(t error.no_picker)"
        read -rp "$(t prompt.manual_icon)" manual_path
        echo "$manual_path"
    fi
}

dir_picker() {
    local title="$1"
    if command -v zenity &>/dev/null; then
        zenity --file-selection --directory --title="$title" 2>/dev/null
    elif command -v kdialog &>/dev/null; then
        kdialog --getexistingdirectory . 2>/dev/null
    elif command -v yad &>/dev/null; then
        yad --file-selection --directory --title="$title" 2>/dev/null
    else
        read -rp "$(t prompt.manual_dir)" manual_dir
        echo "$manual_dir"
    fi
}

# ────────────────────────────────────────────────────────────
#  واجهة المستخدم
# ────────────────────────────────────────────────────────────
if (( ! JSON_MODE )); then
    clear
    echo -e "${BLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    printf "  ║    %-42s║\n" "$(t banner.title)"
    printf "  ║    %-42s║\n" "$(t banner.subtitle)"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RST}"
fi

# ── 1. اختيار الأيقونة ─────────────────────────────────────
header "$(t step.1.header)"
if [[ -n "$BATCH_ICON" ]]; then
    ICON_FILE="$BATCH_ICON"
    [[ -f "$ICON_FILE" ]] || { err "$(t error.bad_icon_path "$ICON_FILE")"; exit 1; }
else
    info "$(t info.opening_picker)"
    ICON_FILE=$(file_picker "$(t step.1.title)")
    [[ -f "$ICON_FILE" ]] || { err "$(t error.no_file)"; exit 1; }
fi
success "$(t success.icon "$ICON_FILE")"

ICON_BASENAME=$(basename "${ICON_FILE%.*}")
DIMS=$(gt_get_image_dimensions "$ICON_FILE")
info "$(t info.original_dims "$DIMS")"
if [[ "$DIMS" != "?x?" ]]; then
    W=$(echo "$DIMS" | cut -dx -f1)
    if [[ "$W" =~ ^[0-9]+$ ]] && (( W < 512 )); then
        warn "$(t warn.small_icon)"
        warn "$(t warn.recommend_1024)"
    fi
fi

# ── 2. اختيار مجلد التصدير ─────────────────────────────────
header "$(t step.2.header)"
if [[ -n "$BATCH_OUTPUT" ]]; then
    EXPORT_DIR="$BATCH_OUTPUT"
    [[ -d "$EXPORT_DIR" ]] || { err "$(t error.bad_output_path "$EXPORT_DIR")"; exit 1; }
else
    EXPORT_DIR=$(dir_picker "$(t step.2.title)")
    [[ -d "$EXPORT_DIR" ]] || { err "$(t error.no_dir)"; exit 1; }
fi
success "$(t success.export_to "$EXPORT_DIR")"

# ── 3. اسم الحزمة ──────────────────────────────────────────
header "$(t step.3.header)"
if [[ -n "$BATCH_NAME" ]]; then
    ICON_SET_NAME="$BATCH_NAME"
else
    t step.3.opt1 "$ICON_BASENAME"
    t step.3.opt2 "${EXPORT_DIR##*/}"
    t step.3.opt3
    read -rp "$(t step.3.prompt)" NAME_CHOICE
    NAME_CHOICE="${NAME_CHOICE:-1}"
    case "$NAME_CHOICE" in
        2) ICON_SET_NAME="${EXPORT_DIR##*/}-icons" ;;
        3) read -rp "$(t step.3.custom_prompt)" CUSTOM_NAME
           ICON_SET_NAME="${CUSTOM_NAME:-iconset}" ;;
        *) ICON_SET_NAME="${ICON_BASENAME}-icons" ;;
    esac
fi
success "$(t success.package_name "$ICON_SET_NAME")"

# ── 4. اختيار المنصات ──────────────────────────────────────
header "$(t step.4.header)"
if [[ -n "$BATCH_PLATFORMS" ]]; then
    case "$BATCH_PLATFORMS" in
        all|linux-pwa|linux-pwa-android|linux-electron|mobile|windows)
            ENABLED_PLATFORMS=$(gt_resolve_platforms "$BATCH_PLATFORMS") ;;
        *) err "$(t error.bad_platforms "$BATCH_PLATFORMS")"; exit 2 ;;
    esac
else
    t step.4.opt1 "${#GT_ALL_SIZES[@]}"
    t step.4.opt2
    t step.4.opt3
    t step.4.opt4
    t step.4.opt5
    t step.4.opt6
    read -rp "$(t step.4.prompt)" PLAT_CHOICE
    PLAT_CHOICE="${PLAT_CHOICE:-1}"
    case "$PLAT_CHOICE" in
        2) ENABLED_PLATFORMS=$(gt_resolve_platforms linux-pwa) ;;
        3) ENABLED_PLATFORMS=$(gt_resolve_platforms linux-pwa-android) ;;
        4) ENABLED_PLATFORMS=$(gt_resolve_platforms linux-electron) ;;
        5) ENABLED_PLATFORMS=$(gt_resolve_platforms mobile) ;;
        6) ENABLED_PLATFORMS=$(gt_resolve_platforms windows) ;;
        *) ENABLED_PLATFORMS=$(gt_resolve_platforms all) ;;
    esac
fi
info "$(t step.4.platforms "$ENABLED_PLATFORMS")"
info "$(t info.total_sizes "${#GT_ALL_SIZES[@]}")"

# ── 5. توليد الأيقونات ────────────────────────────────────
header "$(t step.5.header)"
FINAL_DIR="$EXPORT_DIR/$ICON_SET_NAME"
mkdir -p "$FINAL_DIR"
ORIG_EXT="${ICON_FILE##*.}"
cp "$ICON_FILE" "$FINAL_DIR/${ICON_BASENAME}-original.${ORIG_EXT}" 2>/dev/null || true

progress_cb() {
    local size=$1 status=$2
    if [[ "$status" == "ok" ]]; then
        (( JSON_MODE )) || printf "  ${GRN}✓${RST} all/%spx\n" "$size"
    else
        warn "$(t warn.size_failed "$size")"
    fi
}

info "$(t info.phase_a)"
gt_generate_all "$ICON_FILE" "$FINAL_DIR" "$ICON_BASENAME" progress_cb

info "$(t info.phase_b "$ENABLED_PLATFORMS")"
gt_distribute "$FINAL_DIR" "$ICON_BASENAME" "$ENABLED_PLATFORMS"

# ── 6. توليد .ico ──────────────────────────────────────────
header "$(t step.6.header)"
if gt_build_ico "$FINAL_DIR" "$ICON_BASENAME"; then
    success "$(t success.ico_created 7 "${ICON_BASENAME}.ico")"
else
    rc=$?
    if [[ $rc -eq 2 ]]; then warn "$(t warn.few_ico_inputs)"
    else                     warn "$(t warn.ico_failed)"
    fi
fi
gt_build_favicon "$FINAL_DIR" "$ICON_BASENAME"

# ── 7. توليد .icns ────────────────────────────────────────
header "$(t step.7.header)"
if gt_build_icns "$FINAL_DIR" "$ICON_BASENAME"; then
    case "$GT_ICNS_METHOD" in
        iconutil)    success "$(t success.icns_iconutil)" ;;
        png2icns)    success "$(t success.icns_png2icns)" ;;
        imagemagick) warn    "$(t warn.icns_im_limited)" ;;
    esac
else
    warn "$(t warn.no_icns_tool)"
    info "$(t warn.install_icnsutils)"
fi

# ── 8. إنشاء README ────────────────────────────────────────
header "$(t step.8.header)"
cat > "$FINAL_DIR/README.md" << README
# ${ICON_SET_NAME}

Generated by **GT-IconScaler v${VERSION}** — $(date '+%Y-%m-%d %H:%M')

## Structure

\`\`\`
${ICON_SET_NAME}/
├── all/            ← all sizes (${GT_DONE_COUNT})
├── linux/          ← hicolor XDG (16→512)
├── pwa/            ← Web Manifest + Apple Touch + Chrome Android
├── android/        ← mipmap-ldpi → mipmap-xxxhdpi
├── ios/            ← iPhone / iPad
├── watchos/        ← Apple Watch
├── windows/        ← MS Tiles (44, 70, 150, 310)
├── electron/       ← AppImage / Snap
├── favicon/        ← favicon.ico + PNG
├── ${ICON_BASENAME}.ico    ← Windows multi-size
└── ${ICON_BASENAME}.icns   ← macOS (if available)
\`\`\`
README
success "$(t success.readme_created)"

# ── 9. ضغط ────────────────────────────────────────────────
header "$(t step.9.header)"
if [[ -n "$BATCH_COMPRESS" ]]; then
    case "$BATCH_COMPRESS" in
        zip|targz|both|none) COMP_MODE="$BATCH_COMPRESS" ;;
        *) err "$(t error.bad_compress "$BATCH_COMPRESS")"; exit 2 ;;
    esac
else
    t step.9.opt1
    t step.9.opt2
    t step.9.opt3
    t step.9.opt4
    read -rp "$(t step.9.prompt)" COMP_CHOICE
    COMP_CHOICE="${COMP_CHOICE:-3}"
    case "$COMP_CHOICE" in
        1) COMP_MODE="zip"   ;;
        2) COMP_MODE="targz" ;;
        4) COMP_MODE="none"  ;;
        *) COMP_MODE="both"  ;;
    esac
fi
case "$COMP_MODE" in
    zip)   gt_compress_package "$EXPORT_DIR" "$ICON_SET_NAME" zip
           success "$(t success.zip_created "$ICON_SET_NAME")" ;;
    targz) gt_compress_package "$EXPORT_DIR" "$ICON_SET_NAME" targz
           success "$(t success.targz_created "$ICON_SET_NAME")" ;;
    both)  gt_compress_package "$EXPORT_DIR" "$ICON_SET_NAME" both
           success "$(t success.both_created "$ICON_SET_NAME" "$ICON_SET_NAME")" ;;
    none)  info "$(t info.skip_compression)" ;;
esac

# ── 10. الملخص النهائي ────────────────────────────────────
HAS_ICO=false; [[ -f "$FINAL_DIR/${ICON_BASENAME}.ico"  ]] && HAS_ICO=true
HAS_ICNS=false; [[ -f "$FINAL_DIR/${ICON_BASENAME}.icns" ]] && HAS_ICNS=true

ARCHIVES=()
case "$COMP_MODE" in
    zip)   [[ -f "$EXPORT_DIR/${ICON_SET_NAME}.zip"    ]] && ARCHIVES+=("${EXPORT_DIR}/${ICON_SET_NAME}.zip")    ;;
    targz) [[ -f "$EXPORT_DIR/${ICON_SET_NAME}.tar.gz" ]] && ARCHIVES+=("${EXPORT_DIR}/${ICON_SET_NAME}.tar.gz") ;;
    both)
        [[ -f "$EXPORT_DIR/${ICON_SET_NAME}.zip"    ]] && ARCHIVES+=("${EXPORT_DIR}/${ICON_SET_NAME}.zip")
        [[ -f "$EXPORT_DIR/${ICON_SET_NAME}.tar.gz" ]] && ARCHIVES+=("${EXPORT_DIR}/${ICON_SET_NAME}.tar.gz")
        ;;
esac

if (( JSON_MODE )); then
    # سطر JSON واحد على stdout — نبني يدوياً لتجنّب الاعتماد على jq وقت التشغيل
    json_escape() {
        local s=${1//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/\\n}; s=${s//$'\t'/\\t}
        printf '"%s"' "$s"
    }
    archives_json="["
    for i in "${!ARCHIVES[@]}"; do
        (( i > 0 )) && archives_json+=","
        archives_json+=$(json_escape "${ARCHIVES[$i]}")
    done
    archives_json+="]"
    printf '{"final_dir":%s,"done":%d,"failed":%d,"has_ico":%s,"has_icns":%s,"icns_method":%s,"compress":%s,"archives":%s}\n' \
        "$(json_escape "$FINAL_DIR")" \
        "${GT_DONE_COUNT:-0}" \
        "${GT_FAIL_COUNT:-0}" \
        "$HAS_ICO" \
        "$HAS_ICNS" \
        "$(json_escape "${GT_ICNS_METHOD:-none}")" \
        "$(json_escape "$COMP_MODE")" \
        "$archives_json"
else
    echo ""
    echo -e "${BLD}${GRN}"
    echo "  ╔══════════════════════════════════════════════╗"
    printf "  ║    %-42s║\n" "$(t banner.done)"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RST}"

    printf "  📁 %s : ${BLD}%s${RST}\n" "$(t summary.folder)" "$FINAL_DIR"
    printf "  ✅ %s : ${BLD}%s${RST} %s\n" "$(t summary.succeeded)" "$GT_DONE_COUNT" "$(t summary.sizes_unit)"
    [[ ${GT_FAIL_COUNT:-0} -gt 0 ]] && \
        printf "  ${YEL}⚠️  %s : %s${RST}\n" "$(t summary.failed)" "$GT_FAIL_COUNT"
    echo ""
    $HAS_ICO  && echo "     ✅ .ico (Windows)"
    $HAS_ICNS && echo "     ✅ .icns (macOS)"
    echo ""
fi
