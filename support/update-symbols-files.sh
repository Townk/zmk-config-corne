#!/usr/bin/env bash

CONFIG_ROOT="$(git rev-parse --show-toplevel)"

export_layer() {
  local KEYMAP_NAME=$1
  local LAYER_NAME=$2
  local LAYOUR_FILE=$3
  echo "- Exporting layout map image for layer '$LAYER_NAME'"
  keymap -c "${CONFIG_ROOT}/support/keymap-config.yaml" draw \
    -s "$LAYER_NAME" \
    -o "${CONFIG_ROOT}/docs/images/$LAYOUR_FILE" \
    "$KEYMAP_NAME"
}

export_layout_map() {
  local SHIELD_NAME="$1"
  local KEYS_COUNT="$2"
  local EXPORT_BUTTONS="$3"
  local KEYMAP_NAME="$(echo "${SHIELD_NAME}" | tr "[:upper:]" "[:lower:]")"
  local KD_KEYMAP="$(mktemp).yaml"

  echo "Generating layout map images for the ${SHIELD_NAME} keyboard..."
  echo "- Generating Keymap-Drawer YAML file"

  # The first part of the temp keymap contains the layout map with keys showing
  # their "Shift" symbol, and it include all base keymaps.
  keymap -c "${CONFIG_ROOT}/support/keymap-config.yaml" parse -z "${CONFIG_ROOT}/config/${KEYMAP_NAME}.keymap" \
    | sed -n '1,/Numbers:/p' \
    | sed -e '$ d' > "$KD_KEYMAP"

  # We need to create a special configuration for Keyboard Drawer that will be
  # the normal configuration, merged with the "no symbols" diff that we have on
  # the repository.
  KD_CONFIG_NO_SYMBOLS="$(mktemp).yaml"
  yq ". * load(\"${CONFIG_ROOT}/support/keymap-config-no-shift-symbols.yaml\")" "${CONFIG_ROOT}/support/keymap-config.yaml" > "$KD_CONFIG_NO_SYMBOLS"

  # The second part of the file contains the rest of the layout map with keys NOT
  # shoing their "Shift" symbol.
  keymap -c "$KD_CONFIG_NO_SYMBOLS" parse -z "${CONFIG_ROOT}/config/${KEYMAP_NAME}.keymap" \
    | sed -n '/Numbers:/,$ p' \
    | sed 's/RGB COLOR HSB(0 0 60)/{t: "$$mdi:palette-outline$$", h: reset}/' >> "$KD_KEYMAP"

  export_layer "$KD_KEYMAP" "QWERTY" "${KEYMAP_NAME}${KEYS_COUNT}-layer0-main.svg"
  export_layer "$KD_KEYMAP" "Numbers" "${KEYMAP_NAME}${KEYS_COUNT}-layer1-numbers.svg"
  export_layer "$KD_KEYMAP" "Symbols" "${KEYMAP_NAME}${KEYS_COUNT}-layer2-symbols.svg"
  export_layer "$KD_KEYMAP" "Navigation" "${KEYMAP_NAME}${KEYS_COUNT}-layer3-navigation.svg"
  export_layer "$KD_KEYMAP" "Media" "${KEYMAP_NAME}${KEYS_COUNT}-layer4-media.svg"
  if [[ -n "$EXPORT_BUTTONS" ]]; then
    export_layer "$KD_KEYMAP" "Buttons" "${KEYMAP_NAME}${KEYS_COUNT}-layer5-buttons.svg"
  fi
  export_layer "$KD_KEYMAP" "System" "${KEYMAP_NAME}${KEYS_COUNT}-layer6-system.svg"
  export_layer "$KD_KEYMAP" "COLEMAK" "${KEYMAP_NAME}${KEYS_COUNT}-layer7-colemak.svg"

  rm -rf "$KD_KEYMAP"
  rm -rf "$KD_CONFIG_NO_SYMBOLS"

  echo "Done!"
  echo ""
}

export_layout_map Corne 42
export_layout_map Lily58 "" 1

echo "Exporting layers Glyphs..."

# I need to copy the cached symbols from Keymap Drawer into my repository so
# the table of key symbols I have on the README file can render correctly.
for g in ~/Library/Caches/keymap-drawer/glyphs/*; do
  # I'm using `sed` to copy the file because I need to add `height`, `width`,
  # and `color` to the SVG, since GitHub does not allow me to have all the CSS
  # styles I want... I think :)
  sed 's/viewBox="0 0 24 24"/viewBox="0 0 24 24" height="20px" width="20px" fill="#e8eaed"/' "$g" > "${CONFIG_ROOT}/docs/glyphs/${g#*mdi:}"
done

echo "Done!"
