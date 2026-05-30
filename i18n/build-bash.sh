#!/usr/bin/env bash
# ============================================================
#  i18n/build-bash.sh
#  يحوّل i18n/{ar,en}.json إلى lib/i18n-{ar,en}.sh
#  حتى لا نعتمد على jq وقت التشغيل — فقط أثناء التطوير.
#
#  شغّل هذا السكربت بعد أي تعديل على ملفات JSON.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$PROJECT_DIR/lib"

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required (sudo apt install jq / sudo dnf install jq)" >&2
    exit 1
fi

mkdir -p "$LIB_DIR"

for lang in ar en; do
    src="$SCRIPT_DIR/${lang}.json"
    dst="$LIB_DIR/i18n-${lang}.sh"

    [[ -f "$src" ]] || { echo "Missing: $src" >&2; exit 1; }
    jq empty "$src" || { echo "Invalid JSON: $src" >&2; exit 1; }

    {
        echo "#!/usr/bin/env bash"
        echo "# AUTO-GENERATED from i18n/${lang}.json — DO NOT EDIT MANUALLY"
        echo "# Regenerate with: i18n/build-bash.sh"
        echo ""
        # @sh يقتبس القيم بأمان للـ shell (يهرّب علامات الاقتباس)
        jq -r 'to_entries | .[] | "T[\(.key|@sh)]=\(.value|@sh)"' "$src"
    } > "$dst"

    echo "Generated: $dst ($(wc -l < "$dst") lines)"
done

echo "Done. ${#@}"
