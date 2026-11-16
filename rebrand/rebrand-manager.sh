#!/usr/bin/env bash
# Rebrand a SukiSU Nova `main` checkout into SUKISU (manager app). Run from CI after checkout.
#   usage: rebrand-manager.sh <nova-checkout-dir>
# What it does (and does NOT do):
#   * app label comes from -PKSU_NAME, applicationId from -PKSU_PACKAGE_NAME (set by the workflow);
#   * user-visible "SukiSU Nova" / "SukiSU Ultra" strings in res/values*/strings.xml -> $APP_NAME;
#   * REPLACES every launcher/splash icon with our own original artwork. Nova's launcher icons are anime
#     artwork under a limited licence (LICENSE_icon_English) that does not grant redistribution of the
#     artists' / brand owner's IP, so they must not ship in our releases;
#   * builds arm64-v8a only (OnePlus 15R) and does not touch the internal `com.sukisu.nova` class namespace.
set -euo pipefail
NOVA="${1:?nova checkout dir}"
. "$(dirname "$0")/../branding.env"
RES="$NOVA/manager/app/src/main/res"
[ -d "$RES" ] || { echo "rebrand: $RES not found" >&2; exit 1; }

# ---- 1. visible strings ------------------------------------------------------------------------------
n=0
while IFS= read -r -d '' f; do
  if grep -qE 'SukiSU Nova|SukiSU Ultra' "$f"; then
    sed -i -E "s/SukiSU Nova/${APP_NAME}/g; s/SukiSU Ultra/${APP_NAME}/g" "$f"; n=$((n+1))
  fi
done < <(find "$RES" -path '*/values*/strings*.xml' -print0)
echo "rebrand: visible strings rewritten in $n files"

# ---- 2. ABI: arm64 only ------------------------------------------------------------------------------
G="$NOVA/manager/app/build.gradle.kts"
[ "$(grep -c 'abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64", "riscv64")' "$G")" = "1" ] \
  || { echo "rebrand: abiFilters anchor not found" >&2; exit 1; }
sed -i 's/abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64", "riscv64")/abiFilters += listOf("arm64-v8a")/' "$G"

# ---- 3. icons: delete every covered file, write our own under the same resource names ------------------
find "$RES" -type f \( -name 'ic_launcher*' \) -print -delete | sed 's|^|rebrand: removed |'
mkdir -p "$RES/drawable" "$RES/mipmap-anydpi-v26" "$RES/mipmap-anydpi" "$RES/values"

# Original mark: a rounded shield with a stylised "S" cut-out (drawn on a 108x108 adaptive-icon canvas,
# artwork kept inside the 66dp safe zone).
cat > "$RES/drawable/ic_launcher_foreground.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <!-- shield -->
    <path android:fillColor="#FFFFFFFF"
        android:pathData="M54,24 L78,32 L78,54 C78,68 68,78 54,84 C40,78 30,68 30,54 L30,32 Z"/>
    <!-- "S" drawn as one rounded stroke -->
    <path android:strokeColor="#FF14181F" android:strokeWidth="5.5"
        android:strokeLineCap="round" android:strokeLineJoin="round" android:fillColor="#00000000"
        android:pathData="M62,44 C62,40 58,38 54,38 C49,38 46,41 46,45 C46,49 50,50.5 54,51.5 C58,52.5 62,54 62,58.5 C62,62.5 59,65 54,65 C49,65 46,62 46,59"/>
</vector>
XML
cat > "$RES/drawable/ic_launcher_monochrome.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <!-- shield outline + the same "S" stroke, single colour (themed icon) -->
    <path android:strokeColor="#FF000000" android:strokeWidth="3"
        android:strokeLineJoin="round" android:fillColor="#00000000"
        android:pathData="M54,24 L78,32 L78,54 C78,68 68,78 54,84 C40,78 30,68 30,54 L30,32 Z"/>
    <path android:strokeColor="#FF000000" android:strokeWidth="5.5"
        android:strokeLineCap="round" android:strokeLineJoin="round" android:fillColor="#00000000"
        android:pathData="M62,44 C62,40 58,38 54,38 C49,38 46,41 46,45 C46,49 50,50.5 54,51.5 C58,52.5 62,54 62,58.5 C62,62.5 59,65 54,65 C49,65 46,62 46,59"/>
</vector>
XML
# splash animation target (referenced by themes.xml) = plain foreground
cat > "$RES/drawable/ic_launcher_splash.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@drawable/ic_launcher_foreground"/>
</layer-list>
XML

# our colours (the upstream ic_launcher_background colour lives in values/colors.xml and is kept)
cat > "$RES/values/sukisu_icon_colors.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="sukisu_icon_bg">#FF1F6FEB</color>
</resources>
XML

# Every alias the manifest / BuiltinAppIcons.kt refers to resolves to the same artwork.
drawables=(ic_launcher_foreground_alt ic_launcher_foreground_logo ic_launcher_foreground_zako
           ic_launcher_monochrome_alt ic_launcher_monochrome_logo)
for d in "${drawables[@]}"; do
  case "$d" in
    *monochrome*) cp "$RES/drawable/ic_launcher_monochrome.xml" "$RES/drawable/$d.xml" ;;
    *)            cp "$RES/drawable/ic_launcher_foreground.xml" "$RES/drawable/$d.xml" ;;
  esac
done
for m in ic_launcher ic_launcher_round ic_launcher_static ic_launcher_alt ic_launcher_alt_round ic_launcher_alt_static \
         ic_launcher_logo ic_launcher_logo_round ic_launcher_logo_static ic_launcher_zako ic_launcher_zako_round ic_launcher_zako_static; do
  cat > "$RES/mipmap-anydpi-v26/$m.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/sukisu_icon_bg"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
XML
  # pre-26 fallback (minSdk is 24): flat layer list
  cat > "$RES/mipmap-anydpi/$m.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/sukisu_icon_bg"/>
    <item android:drawable="@drawable/ic_launcher_foreground"/>
</layer-list>
XML
done

# ---- 4. nothing covered may remain ----------------------------------------------------------------------
if find "$RES" -type f \( -name 'ic_launcher*.webp' -o -name 'ic_launcher*.png' \) | grep -q .; then
  echo "rebrand: covered bitmap icons still present" >&2; exit 1
fi
# `ic_launcher_foreground_zako` etc. are now our own copies; the colour resources they used must still exist
grep -q 'name="ic_launcher_zako_foreground"' "$RES/values/colors.xml" || true
echo "rebrand: icons replaced, app label will be '${APP_NAME}', package '${PACKAGE_NAME}'"
