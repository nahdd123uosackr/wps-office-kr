# Maintainer: WPS Office Korean Patch Project
pkgbase=wps-office-kr
pkgname=('wps-office-kr' 'wps-office-kr-mime' 'wps-office-kr-fonts')
pkgver=12.1.2.28080
pkgrel=1
pkgdesc="WPS Office with Korean locale, default yyyy-MM-dd date format, fixed MIME types, and improved font rendering"
arch=('x86_64')
url="https://github.com/nahdd123uosackr/wps-office-kr"
license=('LicenseRef-WPS-EULA')
makedepends=('tar' 'xz' 'fontconfig' 'curl' 'jq' 'qt5-tools' 'python-pip' 'libarchive')
depends=(
  'fontconfig' 'libxrender' 'xdg-utils' 'glu'
  'libpulse' 'libxss' 'sqlite' 'libtool' 'libtiff'
  'libxslt' 'libjpeg-turbo' 'libpng' 'freetype2'
  'desktop-file-utils' 'shared-mime-info' 'hicolor-icon-theme'
  'sdl2' 'libglvnd')
optdepends=(
  'wps-office-kr-fonts: Korean fonts provided by WPS Office'
  'ttf-liberation: Metric-compatible fonts for MS Office compatibility (Liberation Sans/Serif/Mono)'
  'ttf-carlito: Metric-compatible font for Calibri'
  'ttf-caladea: Metric-compatible font for Cambria'
  'ttf-opensans: Helvetica/Arial alternative (Open Sans)'
  'noto-fonts: Full Unicode coverage fallback (Sans/Serif/Mono/CJK/Emoji/Math)'
  'noto-fonts-cjk: Korean/Chinese/Japanese font support'
  'noto-fonts-emoji: Color emoji support (Noto Color Emoji)'
  'noto-fonts-extra: Math fonts (STIX, Latin Modern, XITS)'
  'tex-gyre-fonts: Math fonts (XITS Math, Latin Modern Math, TeX Gyre)'
  'ttf-ms-fonts: Microsoft core fonts (AUR) for perfect compatibility'
  'cups: for printing support'
  'pango: for complex text layout support'
  'python-argostranslate: offline machine translation for Korean .qm generation')
conflicts=('wps-office' 'wps-office-365' 'wps-office-cn' 'wps-office-mime')
provides=('wps-office' 'wps-office-mime')
options=(!strip !zipman !debug !emptydirs)

# GitHub Release configuration
_gh_repo="nahdd123uosackr/wps-office-kr"
_gh_api="https://api.github.com/repos/${_gh_repo}"

# Upstream source
source_base="https://pubwps-wps365-obs.wpscdn.cn/download/Linux/${pkgver: -5}/wps-office_${pkgver}.AK.preread.sw.365"
source_x86_64=("${source_base}_765469_amd64.deb")
noextract=("wps-office_${pkgver}.AK.preread.sw.365_765469_amd64.deb")
sha256sums_x86_64=('df89257786787ba4d22511438d6061c991762a354a66c65903858facd6f2da90')

install=wps-office-kr.install

# Korean locale patches
source+=(
  'ko_KR_datetimeformat.patch'
  'ko_KR_controldatetimeformat.patch'
  'ko_KR_idstr.patch'
  '99-wps-office-font-rendering.conf'
  'wps-office-mime.xml'
  'wps-office-disable-mime-detection.sh'
  'translation_dict.json'
  'ko_qm_windows.tar.gz'
  'win_translations.tar.gz'
  'wps-office-kr.install'
  'wps-office-kr.hook'
)
sha256sums+=(
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
  'SKIP'
)

# Check for pre-built packages on GitHub Release
_check_prebuilt() {
  local tag="v${pkgver}"
  local api_url="${_gh_api}/releases/tags/${tag}"
  
  msg "Checking for pre-built packages at ${api_url}..."
  
  # Use curl with GitHub token if available
  local curl_args=(-sL)
  [[ -n "${GITHUB_TOKEN}" ]] && curl_args+=(-H "Authorization: token ${GITHUB_TOKEN}")
  
  local release_info
  release_info=$(curl "${curl_args[@]}" "${api_url}" 2>/dev/null) || return 1
  
  # Check if release exists
  echo "${release_info}" | jq -e '.assets | length > 0' >/dev/null 2>&1 || return 1
  
  # Extract asset URLs for our packages
  local assets
  assets=$(echo "${release_info}" | jq -r '.assets[] | select(.name | test("wps-office-kr.*\\.pkg\\.tar\\.zst$")) | "\(.name)|\(.browser_download_url)"')
  
  [[ -z "${assets}" ]] && return 1
  
  echo "${assets}"
  return 0
}

# Download and verify pre-built package
_download_prebuilt() {
  local assets="$1"
  local pkgname="$2"
  local pkgfile="${pkgname}-${pkgver}-${pkgrel}-${CARCH}.pkg.tar.zst"
  
  # For any arch packages
  [[ "${CARCH}" == "any" ]] && pkgfile="${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst"
  
  local url
  url=$(echo "${assets}" | grep "^${pkgfile}|" | cut -d'|' -f2)
  
  [[ -z "${url}" ]] && return 1
  
  msg "Downloading pre-built package: ${pkgfile}..."
  curl -sL "${url}" -o "${pkgfile}" || return 1
  
  # Verify it's a valid package
  bsdtar -tf "${pkgfile}" .PKGINFO >/dev/null 2>&1 || return 1
  
  # Copy to package directory
  install -Dm644 "${pkgfile}" "${PKGDEST}/${pkgfile}" 2>/dev/null || cp "${pkgfile}" "${PKGDEST}/"
  
  return 0
}

prepare() {
  # Skip source extraction if using pre-built packages
  if [[ -n "${USE_PREBUILT}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
    msg "Using pre-built packages, skipping source preparation"
    return 0
  fi
  
  msg "Preparing source from upstream..."
  
  # Extract .deb file explicitly (noextract prevents makepkg auto-extraction)
  if [[ ! -f data.tar.xz ]]; then
    for deb_file in *.deb; do
      [[ -f "$deb_file" ]] || continue
      msg "Extracting $deb_file..."
      ar x "$deb_file"
      break
    done
  fi
  
  xz -df data.tar.xz
  tar -xf data.tar
  
  # Copy scripts to build directory for translation pipeline
  local script_src="$(dirname "${BASH_SOURCE[0]}")/scripts"
  if [[ -d "${script_src}" ]]; then
    cp -r "${script_src}" "${srcdir}/"
  fi
}

_install() {
  bsdtar --no-same-owner -C "${pkgdir}" -xf data.tar "$@"
}

_apply_korean_patches() {
  # Create Korean locale directory structure
  mkdir -p "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/config"

  # Apply Korean locale patches
  cp "${srcdir}/ko_KR_datetimeformat.patch" \
    "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/config/datetimeformat.cfg"
  cp "${srcdir}/ko_KR_controldatetimeformat.patch" \
    "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/config/controldatetimeformat.cfg"
  cp "${srcdir}/ko_KR_idstr.patch" \
    "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/config/idstr.cfg"

  # Install lang.conf (required for WPS Office to recognize the locale)
  cat > "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/lang.conf" << 'LANDEOF'
[Language]
DisplayName=한국어
DisplayName[en_US]=Korean
DisplayName[zh_CN]=韩语
Icon=ko_KR.png
LANDEOF

  # Copy Korean number format config from default to ko_KR
  cp "${pkgdir}/opt/kingsoft/wps-office/office6/mui/default/config/numberformat/ko_KR.cfg" \
    "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/config/numberformat.cfg"

  # Copy essential config files from default to ko_KR (required for locale to work)
  for cfg_file in downloadIrmUrl.cfg envelopesproperties.cfg localizedfunctionname.cfg \
                  printpaper.cfg wpplist.cfg wpsfieldnumber.cfg wpslist.cfg; do
    if [[ -f "${pkgdir}/opt/kingsoft/wps-office/office6/mui/default/config/${cfg_file}" ]]; then
      cp "${pkgdir}/opt/kingsoft/wps-office/office6/mui/default/config/${cfg_file}" \
        "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/config/${cfg_file}"
    fi
  done

  # Copy essential resource files from default to ko_KR
  for res_file in DesignScience.png EULA_linux.html Privacy_Linux.html; do
    if [[ -f "${pkgdir}/opt/kingsoft/wps-office/office6/mui/default/${res_file}" ]]; then
      cp "${pkgdir}/opt/kingsoft/wps-office/office6/mui/default/${res_file}" \
        "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/${res_file}"
    fi
  done

  # Copy .rcc resource files from default
  for rcc_file in "${pkgdir}/opt/kingsoft/wps-office/office6/mui/default/"*.rcc; do
    if [[ -f "$rcc_file" ]]; then
      cp "$rcc_file" "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/"
    fi
  done

  # Create ko_KR.png locale icon (simple 32x32 PNG with Korean text indicator)
  python3 -c "
import struct, zlib
width, height = 32, 32
# Create a simple blue/white icon
raw_data = b''
for y in range(height):
    raw_data += b'\x00'  # filter byte
    for x in range(width):
        # Simple Korean flag-inspired design: blue background with white circle
        cx, cy = width//2, height//2
        dx, dy = x - cx, y - cy
        dist = (dx*dx + dy*dy) ** 0.5
        if dist < 10:
            raw_data += bytes([255, 255, 255, 255])  # white circle
        else:
            raw_data += bytes([66, 133, 244, 255])  # blue background
def make_chunk(chunk_type, data):
    chunk = chunk_type + data
    return struct.pack('>I', len(data)) + chunk + struct.pack('>I', zlib.crc32(chunk) & 0xffffffff)
png = b'\x89PNG\r\n\x1a\n'
png += make_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
png += make_chunk(b'IDAT', zlib.compress(raw_data))
png += make_chunk(b'IEND', b'')
with open('${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/ko_KR.png', 'wb') as f:
    f.write(png)
"

  # Update setup.cfg to use Korean locale (robust: any UILanguage -> ko_KR)
  if [[ -f "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/setup.cfg" ]]; then
    if grep -q '^UILanguage=' "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/setup.cfg"; then
      sed -i 's/^UILanguage=.*/UILanguage=ko_KR/' "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/setup.cfg"
    else
      echo "UILanguage=ko_KR" >> "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/setup.cfg"
    fi
    sed -i 's/^ContentEnabledLangs=.*/ContentEnabledLangs=0/' "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/setup.cfg" 2>/dev/null || true
    # Ensure ko_KR is advertised even if original was 1
    grep -q '^ContentEnabledLangs=' "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/setup.cfg" || echo "ContentEnabledLangs=0" >> "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/setup.cfg"
  fi

  # Create system-wide default Office.conf to force Korean locale + cm units
  mkdir -p "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/default"
  cat > "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/default/Office.conf" << 'EOF'
[6.0]
UILanguage=ko_KR

[Application Settings]
UILanguage=ko_KR

[kl]
UILanguage=ko_KR

[Versions]

[6.0\Common]
UILanguage=ko_KR

wps\Custom%20Application%20Settings\MeasurementUnit=cm
wpp\Custom%20Application%20Settings\MeasurementUnit=cm
et\Custom%20Application%20Settings\MeasurementUnit=cm
EOF
  # Also install to /etc/xdg as system-wide xdg config fallback (some WPS builds check here)
  mkdir -p "${pkgdir}/etc/xdg/Kingsoft"
  cp "${pkgdir}/opt/kingsoft/wps-office/office6/cfgs/default/Office.conf" "${pkgdir}/etc/xdg/Kingsoft/Office.conf"

  # TRANSLATE en_US .qm → ko_KR .qm via .ts extraction + translation pipeline
  msg "Translating en_US .qm files to Korean..."
  local en_us_dir="${pkgdir}/opt/kingsoft/wps-office/office6/mui/en_US"
  local ko_kr_dir="${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR"
  local ts_extract_dir="${srcdir}/ts_extracted"
  mkdir -p "$ts_extract_dir"

  # Step 1: Extract .ts files from en_US .qm files
  if command -v lconvert &>/dev/null; then
    for qm_file in "${en_us_dir}"/*.qm; do
      [[ -f "$qm_file" ]] || continue
      local base=$(basename "$qm_file" .qm)
      lconvert -i "$qm_file" -o "${ts_extract_dir}/${base}.ts" 2>/dev/null && \
        msg2 "Extracted: ${base}.ts" || \
        msg2 "Skip: ${base}.qm (extract failed)"
    done
  else
    msg2 "lconvert not available, using pre-extracted .ts from win_translations"
  fi

  # Step 2: Run translation pipeline (English .ts → Korean .qm)
  if [[ -f "${srcdir}/scripts/build_translations.sh" ]]; then
    local ts_source="${ts_extract_dir}"
    if [[ ! "$(ls -A ${ts_source}/*.ts 2>/dev/null)" ]]; then
      ts_source="${srcdir}/win_translations"
    fi
    if [[ -d "$ts_source" ]] && [[ "$(ls -A ${ts_source}/*.ts 2>/dev/null)" ]]; then
      bash "${srcdir}/scripts/build_translations.sh" \
        "$ts_source" \
        "$ko_kr_dir" \
        "${srcdir}/translation_dict.json" \
        2>&1 | while IFS= read -r line; do msg2 "$line"; done
    else
      msg2 "Warning: No .ts files found for translation"
    fi
  fi

  # Install fontconfig for improved font rendering (OnlyOffice-inspired)
  install -Dm644 "${srcdir}/99-wps-office-font-rendering.conf" \
    "${pkgdir}/opt/kingsoft/wps-office/office6/fonts/conf/99-wps-office-font-rendering.conf"

  # Install MIME type definitions
  install -Dm644 "${srcdir}/wps-office-mime.xml" \
    "${pkgdir}/opt/kingsoft/wps-office/office6/mime/wps-office-mime.xml"

  # Install startup script to disable MIME detection
  install -Dm755 "${srcdir}/wps-office-disable-mime-detection.sh" \
    "${pkgdir}/opt/kingsoft/wps-office/office6/wps-office-disable-mime-detection.sh"
}

# Build-time Korean translation pipeline (.ts → merge → translate → .qm)
_build_translations() {
  msg "Building Korean translation files (build-time pipeline)..."

  local mui_dir="${pkgdir}/opt/kingsoft/wps-office/office6/mui"
  local ko_dir="${mui_dir}/ko_KR"

  # Create ko_KR directory structure
  mkdir -p "${ko_dir}"

  # Extract Windows Korean .ts tarball
  msg "Extracting Windows-sourced Korean .ts files..."
  local src_ts_tar="${srcdir}/win_translations.tar.gz"
  local src_ts_dir="${srcdir}/win_translations"
  if [[ -f "${src_ts_tar}" ]]; then
    tar -xzf "${src_ts_tar}" -C "${srcdir}"
  fi
  
  if [[ ! -d "${src_ts_dir}" ]]; then
    msg2 "Warning: Source .ts directory not found at ${src_ts_dir}"
    return 0
  fi

  # Run build-time translation pipeline
  msg "Running build-time translation pipeline..."
  if [[ -f "${srcdir}/scripts/build_translations.sh" ]]; then
    bash "${srcdir}/scripts/build_translations.sh" \
      "${src_ts_dir}" \
      "${srcdir}/build_qm" \
      "${srcdir}/translation_dict.json" \
      2>&1 | while IFS= read -r line; do msg2 "$line"; done
  else
    msg2 "Warning: build_translations.sh not found, skipping pipeline"
    return 0
  fi

  # Install compiled .qm files (from build_qm if pipeline succeeded)
  local build_qm_dir="${srcdir}/build_qm"
  local has_compiled_qm=0
  if [[ -d "${build_qm_dir}" ]]; then
    local qm_count
    qm_count=$(ls -1 "${build_qm_dir}"/*.qm 2>/dev/null | wc -l)
    if [[ "$qm_count" -gt 0 ]]; then
      has_compiled_qm=1
      msg "Installing compiled Korean .qm files..."
      for qm_file in "${build_qm_dir}"/*.qm; do
        [[ -f "$qm_file" ]] || continue
        cp "$qm_file" "${ko_dir}/"
        msg2 "Installed (compiled): $(basename "$qm_file")"
      done
      if [[ -d "${build_qm_dir}/addons" ]]; then
        for addon_dir in "${build_qm_dir}/addons"/*; do
          [[ -d "$addon_dir" ]] || continue
          addon_name=$(basename "$addon_dir")
          mkdir -p "${ko_dir}/${addon_name}"
          for qm_file in "${addon_dir}"/*.qm; do
            [[ -f "$qm_file" ]] || continue
            cp "$qm_file" "${ko_dir}/${addon_name}/"
            msg2 "Installed addon (compiled): ${addon_name}/$(basename "$qm_file")"
          done
        done
      fi
    fi
  fi

  # Fallback: direct copy from prebuilt Windows Korean .qm (ko_qm_windows.tar.gz)
  if [[ "$has_compiled_qm" -eq 0 ]]; then
    msg "No compiled .qm from pipeline, falling back to prebuilt ko_qm_windows..."
    local win_qm_tar="${srcdir}/ko_qm_windows.tar.gz"
    local win_qm_dir="${srcdir}/ko_qm_windows"
    if [[ -f "$win_qm_tar" ]]; then
      tar -xzf "$win_qm_tar" -C "${srcdir}" 2>/dev/null || true
    fi
    if [[ -d "$win_qm_dir" ]]; then
      for qm_file in "${win_qm_dir}"/*.qm; do
        [[ -f "$qm_file" ]] || continue
        cp "$qm_file" "${ko_dir}/"
        msg2 "Installed (fallback): $(basename "$qm_file")"
      done
      if [[ -d "${win_qm_dir}/addons" ]]; then
        for addon_dir in "${win_qm_dir}/addons"/*; do
          [[ -d "$addon_dir" ]] || continue
          addon_name=$(basename "$addon_dir")
          mkdir -p "${ko_dir}/${addon_name}"
          for qm_file in "${addon_dir}"/*.qm; do
            [[ -f "$qm_file" ]] || continue
            cp "$qm_file" "${ko_dir}/${addon_name}/"
            msg2 "Installed addon (fallback): ${addon_name}/$(basename "$qm_file")"
          done
        done
      fi
    fi
  fi

  # Copy supplementary Korean .qm from Linux addons (always, to ensure completeness)
  msg "Copying supplementary Korean .qm from Linux addons..."
  find "${mui_dir}/../addons" -name "*.qm" -path "*/ko_KR/*" 2>/dev/null | while read -r qm_file; do
    # Path: addons/<addon_name>/mui/ko_KR/*.qm → extract <addon_name>
    local addon_name=$(basename $(dirname $(dirname $(dirname "$qm_file"))))
    local target_dir="${ko_dir}/${addon_name}"
    mkdir -p "${target_dir}"
    cp "$qm_file" "${target_dir}/"
    msg2 "Installed (Linux): ${addon_name}/$(basename "$qm_file")"
  done
  # Also copy main .qm from Linux addons that may not be in build_qm/win_qm (e.g. promotion, cloud docs)
  # Ensure ko_KR directory has at least kso.qm, wps.qm, wpp.qm, et.qm, qing.qm if available from addons fallback copy
  for src_qm in "${mui_dir}/../addons"/*/mui/ko_KR/*.qm; do
    [[ -f "$src_qm" ]] || continue
    # Only copy if not already present in ko_dir root (main apps vs addons)
    base=$(basename "$src_qm")
    if [[ ! -f "${ko_dir}/${base}" ]]; then
      # For debugging, keep this as addon copy already handled; skip
      true
    fi
  done

  # Install translation dictionary for reference
  install -Dm644 "${srcdir}/translation_dict.json" \
    "${ko_dir}/translation_dict.json"

  msg "Korean translation files installed (build-time pipeline)"
}

# Main build function - checks for pre-built first
build() {
  # Check if we should use pre-built packages
  if [[ -n "${USE_PREBUILT}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
    msg "Attempting to use pre-built packages from GitHub Release..."
    
    local assets
    assets=$(_check_prebuilt) || {
      msg "No pre-built packages found, falling back to source build"
      USE_PREBUILT=0
    }
    
    if [[ -n "${assets}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
      msg "Pre-built packages found! Downloading..."
      
      # Download all three packages
      _download_prebuilt "${assets}" "wps-office-kr" || USE_PREBUILT=0
      _download_prebuilt "${assets}" "wps-office-kr-mime" || USE_PREBUILT=0
      _download_prebuilt "${assets}" "wps-office-kr-fonts" || USE_PREBUILT=0
      
      if [[ "${USE_PREBUILT}" != "0" ]]; then
        msg "Successfully downloaded all pre-built packages"
        return 0
      fi
    fi
  fi
  
  # Normal source build
  msg "Building from source..."
  # Source is already prepared in prepare()
  return 0
}

package_wps-office-kr() {
  depends=('fontconfig' 'libxrender' 'xdg-utils' 'glu'
    'libpulse' 'libxss' 'sqlite' 'libtool' 'libtiff'
    'libxslt' 'libjpeg-turbo' 'libpng' 'freetype2'
    'desktop-file-utils' 'shared-mime-info' 'hicolor-icon-theme'
    'sdl2' 'libglvnd')
  optdepends=('wps-office-kr-fonts: Korean fonts provided by WPS Office'
    'ttf-liberation: Metric-compatible fonts for MS Office compatibility'
    'ttf-carlito: Metric-compatible font for Calibri'
    'ttf-ms-fonts: Microsoft core fonts (AUR)'
    'cups: for printing support'
    'pango: for complex text layout support')
  conflicts=('wps-office' 'wps-office-365' 'wps-office-cn' 'wps-office-mime')
  provides=('wps-office' 'wps-office-mime')

  # If using pre-built, extract it
  if [[ -n "${USE_PREBUILT}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
    local pkgfile="wps-office-kr-${pkgver}-${pkgrel}-${CARCH}.pkg.tar.zst"
    [[ -f "${pkgfile}" ]] || pkgfile="../${pkgfile}"
    [[ -f "${pkgfile}" ]] || pkgfile="${PKGDEST}/${pkgfile}"
    
    if [[ -f "${pkgfile}" ]]; then
      msg "Extracting pre-built package: ${pkgfile}"
      bsdtar -xf "${pkgfile}" -C "${pkgdir}"
      return 0
    fi
  fi
  
  # Normal build from source
  _install --exclude ./usr/*xiezuo* \
          --exclude ./usr/share/fonts \
          --exclude ./usr/share/desktop-directories \
          --exclude ./usr/share/templates \
          --exclude ./usr/share/mime \
          ./opt/kingsoft/wps-office/office6 \
          ./usr

  _apply_korean_patches

  # Build and install Korean translations
  _build_translations

  cd "${pkgdir}"

  # Use system libraries instead of bundled ones
  rm -f opt/kingsoft/wps-office/office6/lib{jpeg,stdc++}.so*

  # Install fontconfig for improved rendering
  install -d usr/share/fontconfig/conf.avail
  install -d usr/share/fontconfig/conf.default
  install -m644 opt/kingsoft/wps-office/office6/fonts/conf/99-wps-office-font-rendering.conf \
    usr/share/fontconfig/conf.avail/99-wps-office-font-rendering.conf
  ln -sf ../conf.avail/99-wps-office-font-rendering.conf \
    usr/share/fontconfig/conf.default/99-wps-office-font-rendering.conf

  # Install MIME definitions
  install -d usr/share/mime/packages
  install -m644 "${srcdir}/wps-office-mime.xml" \
    usr/share/mime/packages/wps-office.xml

  # Install startup script to disable MIME detection
  install -m755 opt/kingsoft/wps-office/office6/wps-office-disable-mime-detection.sh \
    usr/bin/wps-office-disable-mime-detection

  # Fix menu category
  sed -i 's|Categories=.*|&Office;|' usr/share/applications/*.desktop

  # Fix input method (fcitx5)
  sed -i '2i [[ "$XMODIFIERS" == "@im=fcitx" ]] && export QT_IM_MODULE=fcitx' \
    usr/bin/{wps,wpp,et,wpspdf}

  # Allow custom fontconfig
  sed -i '2i [[ -f ~/.config/Kingsoft/fonts/fonts.conf ]] && export FONTCONFIG_FILE=~/.config/Kingsoft/fonts/fonts.conf' \
    usr/bin/{wps,wpp,et,wpspdf}

  # Disable force login
  sed -i '2i sed -i "s/enableForceLogin=true/enableForceLogin=false/" $HOME/.config/Kingsoft/Office.conf' \
    usr/bin/{wps,wpp,et,wpspdf}

  # Clear WPS Office locale cache to force Korean on first run
  for app in wps wpp et wpspdf; do
    sed -i '2a\
# Clear stale locale cache to apply Korean UI\
if [[ -f "$HOME/.config/Kingsoft/Office.conf" ]]; then\
  sed -i "s/UILanguage=.*/UILanguage=ko_KR/" "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null\
fi' usr/bin/${app}
  done

  # Set default locale to Korean (for UI + font name display)
  # LANG: 기본 로케일
  # LC_ALL: 모든 로케일 카테고리 오버라이드
  # LANGUAGE: 메시지 언어 우선순위 (Qt의 로케일 판단에 영향)
  # LC_CTYPE: 문자 분류/변환 (폰트 이름 선택에 간접 영향)
  for app in wps wpp et wpspdf; do
    sed -i '2i\
# Force Korean locale for UI and font name display\
export LANG=ko_KR.UTF-8\
export LC_ALL=ko_KR.UTF-8\
export LANGUAGE=ko_KR:ko\
export LC_CTYPE=ko_KR.UTF-8' usr/bin/${app}
  done

  # Add MIME detection disable to launcher
  for app in wps wpp et wpspdf; do
    sed -i '2a # Disable WPS Office MIME type detection at startup\nif [[ -x /usr/bin/wps-office-disable-mime-detection ]]; then\n  /usr/bin/wps-office-disable-mime-detection\nfi' usr/bin/${app}
  done

  # Install post-install Korean setup script + hook (후속 프로세스)
  install -Dm755 "${srcdir}/scripts/wps-office-kr-setup.sh" \
    "${pkgdir}/usr/bin/wps-office-kr-setup"
  # Wrapper for simple invocation (ALPM hook Exec needs no args)
  install -Dm644 "${srcdir}/wps-office-kr.hook" \
    "${pkgdir}/usr/share/libalpm/hooks/wps-office-kr.hook"
  # Ensure .install file is tracked (makepkg validates)
  install -Dm644 "${srcdir}/wps-office-kr.install" \
    "${pkgdir}/usr/share/doc/${pkgname}/wps-office-kr.install" 2>/dev/null || true

  # Fix bsdtar warning
  export LC_ALL=C

  # Install license
  if [[ -d opt/kingsoft/wps-office/office6/mui/default ]]; then
    install -Dm644 -t usr/share/licenses/${pkgname} opt/kingsoft/wps-office/office6/mui/default/*.html
  fi
}

package_wps-office-kr-mime() {
  pkgdesc="MIME type definitions for WPS Office (prevents system MIME override issues)"
  arch=('any')
  depends=('shared-mime-info')
  conflicts=('wps-office-mime' 'wps-office-mime-cn')
  provides=('wps-office-mime')

  # If using pre-built, extract it
  if [[ -n "${USE_PREBUILT}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
    local pkgfile="wps-office-kr-mime-${pkgver}-${pkgrel}-any.pkg.tar.zst"
    [[ -f "${pkgfile}" ]] || pkgfile="../${pkgfile}"
    [[ -f "${pkgfile}" ]] || pkgfile="${PKGDEST}/${pkgfile}"
    
    if [[ -f "${pkgfile}" ]]; then
      msg "Extracting pre-built package: ${pkgfile}"
      bsdtar -xf "${pkgfile}" -C "${pkgdir}"
      return 0
    fi
  fi
  
  # Normal build
  install -d "${pkgdir}/usr/share/mime/packages"
  install -m644 "${srcdir}/wps-office-mime.xml" \
    "${pkgdir}/usr/share/mime/packages/wps-office.xml"

  if [[ -d "${srcdir}/opt/kingsoft/wps-office/office6/mui/default" ]]; then
    install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" \
      "${srcdir}/opt/kingsoft/wps-office/office6/mui/default/"*.html
  fi
}

package_wps-office-kr-fonts() {
  pkgdesc="Korean fonts provided by WPS Office"
  arch=('any')
  conflicts=('wps-office-fonts' 'wps-office-365-fonts' 'wps-office-cn-fonts')
  provides=('wps-office-fonts')

  # If using pre-built, extract it
  if [[ -n "${USE_PREBUILT}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
    local pkgfile="wps-office-kr-fonts-${pkgver}-${pkgrel}-any.pkg.tar.zst"
    [[ -f "${pkgfile}" ]] || pkgfile="../${pkgfile}"
    [[ -f "${pkgfile}" ]] || pkgfile="${PKGDEST}/${pkgfile}"
    
    if [[ -f "${pkgfile}" ]]; then
      msg "Extracting pre-built package: ${pkgfile}"
      bsdtar -xf "${pkgfile}" -C "${pkgdir}"
      return 0
    fi
  fi
  
  # Normal build
  _install ./etc/fonts ./usr/share/fonts

  # Install fontconfig for WPS fonts
  install -d "${pkgdir}/usr/share/fontconfig/conf.avail"
  install -d "${pkgdir}/usr/share/fontconfig/conf.default"
  install -m644 "${pkgdir}/etc/fonts/conf.avail/40-wps-office.conf" \
    "${pkgdir}/usr/share/fontconfig/conf.avail/40-wps-office.conf"
  ln -sf ../conf.avail/40-wps-office.conf \
    "${pkgdir}/usr/share/fontconfig/conf.default/40-wps-office.conf"

  install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" \
    "${srcdir}/opt/kingsoft/wps-office/office6/mui/default/"*.html 2>/dev/null || true
}

# vim:set ts=2 sw=2 et: