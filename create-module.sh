#!/usr/bin/env bash
# =============================================================================
# create-module.sh — Generate a Magento 2 module from the SR template
#
# Usage:
#   ./create-module.sh --module-name=MyModule [--description="My description"]
#
# Placeholders replaced:
#   {ModuleName}   → PascalCase module name   (e.g. MyModule)
#   {module-name}  → kebab-case module name   (e.g. my-module)
#   {description}  → composer description
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage:
  $(basename "$0") --module-name=<PascalCaseName> [--description="<text>"]

Options:
  --module-name   Required. PascalCase name (e.g. MyModule).
  --description   Optional. Composer package description. Default: "SR_{ModuleName} Magento 2 module"
  --help          Show this help message.

Example:
  $(basename "$0") --module-name=ProductImport --description="Product import module"
EOF
}

to_kebab() {
  # PascalCase → kebab-case  (MyModule → my-module)
  echo "$1" | sed 's/\([A-Z]\)/-\1/g' | sed 's/^-//' | tr '[:upper:]' '[:lower:]'
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

MODULE_NAME=""
DESCRIPTION=""

for arg in "$@"; do
  case "$arg" in
    --module-name=*) MODULE_NAME="${arg#*=}" ;;
    --description=*) DESCRIPTION="${arg#*=}" ;;
    --help|-h)       usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate
# ---------------------------------------------------------------------------

if [[ -z "$MODULE_NAME" ]]; then
  echo "Error: --module-name is required." >&2
  usage
  exit 1
fi

if [[ ! "$MODULE_NAME" =~ ^[A-Z][A-Za-z0-9]+$ ]]; then
  echo "Error: --module-name must be PascalCase (e.g. MyModule)." >&2
  exit 1
fi

MODULE_NAME_KEBAB=$(to_kebab "$MODULE_NAME")
DESCRIPTION="${DESCRIPTION:-SR_${MODULE_NAME} Magento 2 module}"

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_SRC="$REPO_ROOT/src"
TEMPLATE_COMPOSER="$REPO_ROOT/composer.json"
OUTPUT_DIR="$REPO_ROOT/output/SR_${MODULE_NAME}"

if [[ ! -d "$TEMPLATE_SRC" ]]; then
  echo "Error: Template source directory not found: $TEMPLATE_SRC" >&2
  exit 1
fi

if [[ -d "$OUTPUT_DIR" ]]; then
  echo "Error: Output directory already exists: $OUTPUT_DIR" >&2
  echo "Remove it first or choose a different module name." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "Creating module SR_${MODULE_NAME}"
echo "  PascalCase : $MODULE_NAME"
echo "  kebab-case : $MODULE_NAME_KEBAB"
echo "  description: $DESCRIPTION"
echo "  Output dir : $OUTPUT_DIR"
echo ""

# ---------------------------------------------------------------------------
# Process a single file — replace all placeholders
# ---------------------------------------------------------------------------

process_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  sed \
    -e "s/{ModuleName}/${MODULE_NAME}/g" \
    -e "s/{module-name}/${MODULE_NAME_KEBAB}/g" \
    -e "s/{description}/${DESCRIPTION}/g" \
    "$src" > "$dst"

  echo "  Created: $dst"
}

# ---------------------------------------------------------------------------
# Walk the src/ directory tree
# ---------------------------------------------------------------------------

while IFS= read -r -d '' src_file; do
  relative="${src_file#"$TEMPLATE_SRC"/}"
  dst_file="$OUTPUT_DIR/$relative"
  process_file "$src_file" "$dst_file"
done < <(find "$TEMPLATE_SRC" -type f -print0)

# ---------------------------------------------------------------------------
# Process composer.json from repo root
# ---------------------------------------------------------------------------

if [[ -f "$TEMPLATE_COMPOSER" ]]; then
  process_file "$TEMPLATE_COMPOSER" "$OUTPUT_DIR/composer.json"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "Done! Module files written to:"
echo "  $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "  1. Review the generated files in $OUTPUT_DIR"
echo "  2. Copy to your Magento 2 installation:"
echo "       cp -r $OUTPUT_DIR <magento-root>/app/code/SR/${MODULE_NAME}"
echo "  3. bin/magento module:enable SR_${MODULE_NAME}"
echo "  4. bin/magento setup:upgrade"
echo ""
