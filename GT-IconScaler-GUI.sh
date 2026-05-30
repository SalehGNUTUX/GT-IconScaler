#!/usr/bin/env bash
# ============================================================
#  GT-IconScaler v2.2 GUI — Zenity Interface
#  واجهة رسومية لتوليد الأيقونات (ar/en)
#
#  © 2025-2026 GNUtux — GPLv3 or later
# ============================================================

set -euo pipefail

VERSION="2.2.0"

# ────────────────────────────────────────────────────────────
#  تحميل المكتبات
# ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

if [[ ! -f "$LIB_DIR/gt-iconscaler-core.sh" ]]; then
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
    exit 1
fi

# shellcheck source=lib/gt-iconscaler-i18n.sh
source "$LIB_DIR/gt-iconscaler-i18n.sh"
# shellcheck source=lib/gt-iconscaler-core.sh
source "$LIB_DIR/gt-iconscaler-core.sh"
# shellcheck source=lib/gt-iconscaler-formats.sh
source "$LIB_DIR/gt-iconscaler-formats.sh"

# ────────────────────────────────────────────────────────────
#  وسائط سطر الأوامر
# ────────────────────────────────────────────────────────────
LANG_OVERRIDE=""
ACTION="run"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    ACTION="help" ;;
        -v|--version) ACTION="version" ;;
        --lang=*)     LANG_OVERRIDE="${1#--lang=}" ;;
        --lang)       shift; LANG_OVERRIDE="${1:-}" ;;
    esac
    shift
done

gt_i18n_init "$LANG_OVERRIDE"

case "$ACTION" in
    help)
        t help.usage "$(basename "$0")"
        echo ""
        t help.options
        t help.opt.help
        t help.opt.version
        t help.opt.lang
        exit 0 ;;
    version)
        t version.line "$VERSION"
        exit 0 ;;
esac

# ────────────────────────────────────────────────────────────
#  فحص المتطلبات
# ────────────────────────────────────────────────────────────
missing=()
gt_im_cmd &>/dev/null || missing+=("ImageMagick")
command -v zenity &>/dev/null || missing+=("zenity")

if [[ ${#missing[@]} -gt 0 ]]; then
    msg="$(t error.missing_tools)"$'\n\n'"$(printf '%s\n' "${missing[@]}")"
    if command -v zenity &>/dev/null; then
        zenity --error --no-wrap --text="$msg" 2>/dev/null || true
    else
        echo "$msg" >&2
    fi
    exit 1
fi

# ────────────────────────────────────────────────────────────
#  حوارات Zenity (مترجمة)
# ────────────────────────────────────────────────────────────
pick_icon() {
    zenity --file-selection \
        --file-filter="$(t gui.filter.images)" \
        --title="$(t gui.title.icon)" \
        2>/dev/null
}

pick_export_dir() {
    zenity --file-selection --directory \
        --title="$(t gui.title.export)" \
        2>/dev/null
}

prompt_package_name() {
    local default_name="$1"
    zenity --entry \
        --title="$(t gui.title.name)" \
        --text="$(t gui.entry.name)" \
        --entry-text="${default_name}-icons" \
        2>/dev/null
}

select_platforms_dialog() {
    zenity --list --radiolist \
        --column="$(t gui.column.choose)" \
        --column="$(t gui.column.platform)" \
        TRUE  "all" \
        FALSE "linux-pwa" \
        FALSE "linux-pwa-android" \
        FALSE "linux-electron" \
        FALSE "mobile" \
        FALSE "windows" \
        --width=650 --height=320 \
        --title="$(t gui.title.platforms)" \
        --hide-header \
        2>/dev/null
}

select_compression_dialog() {
    zenity --list --radiolist \
        --column="$(t gui.column.choose)" \
        --column="$(t gui.column.compression)" \
        TRUE  "both" \
        FALSE "zip" \
        FALSE "targz" \
        FALSE "none" \
        --width=500 --height=240 \
        --title="$(t gui.title.compression)" \
        --hide-header \
        2>/dev/null
}

# ────────────────────────────────────────────────────────────
#  البرنامج الرئيسي
# ────────────────────────────────────────────────────────────
main() {
    # 1) اختيار الأيقونة
    ICON_FILE=$(pick_icon) || exit 1
    [[ -f "$ICON_FILE" ]] || {
        zenity --error --text="$(t error.file_not_found "$ICON_FILE")" 2>/dev/null
        exit 1
    }

    # 2) مجلد التصدير
    EXPORT_DIR=$(pick_export_dir) || exit 1
    [[ -d "$EXPORT_DIR" ]] || {
        zenity --error --text="$(t error.dir_not_found "$EXPORT_DIR")" 2>/dev/null
        exit 1
    }

    # 3) المنصات
    PLAT_KEY=$(select_platforms_dialog) || exit 1
    ENABLED_PLATFORMS=$(gt_resolve_platforms "$PLAT_KEY")

    # 4) اسم الحزمة
    BASENAME=$(basename "${ICON_FILE%.*}")
    PKG_NAME=$(prompt_package_name "$BASENAME") || exit 1
    [[ -z "$PKG_NAME" ]] && PKG_NAME="${BASENAME}-icons"

    # 5) نوع الضغط
    COMP_KEY=$(select_compression_dialog) || exit 1

    # 6) التوليد (مع شريط تقدم)
    FINAL_DIR="$EXPORT_DIR/$PKG_NAME"
    mkdir -p "$FINAL_DIR"
    cp "$ICON_FILE" "$FINAL_DIR/${BASENAME}-original.${ICON_FILE##*.}" 2>/dev/null || true

    (
        echo "10" ; echo "# $(t info.phase_a)"
        gt_generate_all "$ICON_FILE" "$FINAL_DIR" "$BASENAME" >/dev/null 2>&1
        echo "50" ; echo "# $(t info.phase_b "$ENABLED_PLATFORMS")"
        gt_distribute "$FINAL_DIR" "$BASENAME" "$ENABLED_PLATFORMS"
        echo "70" ; echo "# .ico / favicon"
        gt_build_ico "$FINAL_DIR" "$BASENAME" >/dev/null 2>&1 || true
        gt_build_favicon "$FINAL_DIR" "$BASENAME"
        echo "85" ; echo "# .icns"
        gt_build_icns "$FINAL_DIR" "$BASENAME" >/dev/null 2>&1 || true
        echo "95" ; echo "# $(t step.9.header)"
        gt_compress_package "$EXPORT_DIR" "$PKG_NAME" "$COMP_KEY"
        echo "100"
    ) | zenity --progress \
        --title="GT-IconScaler" \
        --auto-close \
        --width=400 \
        2>/dev/null || true

    # 7) رسالة نجاح
    zenity --info \
        --title="$(t gui.title.success)" \
        --no-wrap \
        --text="$(t gui.success.text "$FINAL_DIR")" \
        2>/dev/null || true
}

main "$@"
