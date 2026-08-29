# Maintainer: WPS Office Korean Patch Project
pkgbase=wps-office-kr
pkgname=('wps-office-kr' 'wps-office-kr-mime' 'wps-office-kr-fonts')
pkgver=12.1.2.28080
pkgrel=1
pkgdesc="WPS Office with Korean locale, default yyyy-MM-dd date format, fixed MIME types, and improved font rendering"
arch=('x86_64')
url="https://github.com/nahdd123uosackr/wps-office-kr"
license=('LicenseRef-WPS-EULA')
makedepends=('tar' 'xz' 'fontconfig' 'curl' 'jq' 'qt5-tools' 'python-pip')
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
sha256sums_x86_64=('df89257786787ba4d22511438d6061c991762a354a66c65903858facd6f2da90')

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

  # Copy Korean number format config from default to ko_KR
  cp "${pkgdir}/opt/kingsoft/wps-office/office6/mui/default/config/numberformat/ko_KR.cfg" \
    "${pkgdir}/opt/kingsoft/wps-office/office6/mui/ko_KR/config/numberformat.cfg"

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
      2>&1 | while IFS= read -r line; do msg2 "$line"; done
  else
    msg2 "Warning: build_translations.sh not found, skipping pipeline"
    return 0
  fi

  # Install compiled .qm files
  local build_qm_dir="${srcdir}/build_qm"
  if [[ -d "${build_qm_dir}" ]]; then
    msg "Installing compiled Korean .qm files..."
    
    # Main app .qm files
    for qm_file in "${build_qm_dir}"/*.qm; do
      [[ -f "$qm_file" ]] || continue
      cp "$qm_file" "${ko_dir}/"
      msg2 "Installed: $(basename "$qm_file")"
    done
    
    # Addon .qm files (if any)
    if [[ -d "${build_qm_dir}/addons" ]]; then
      for addon_dir in "${build_qm_dir}/addons"/*; do
        [[ -d "$addon_dir" ]] || continue
        addon_name=$(basename "$addon_dir")
        mkdir -p "${ko_dir}/${addon_name}"
        for qm_file in "${addon_dir}"/*.qm; do
          [[ -f "$qm_file" ]] || continue
          cp "$qm_file" "${ko_dir}/${addon_name}/"
          msg2 "Installed addon: ${addon_name}/$(basename "$qm_file")"
        done
      done
    fi
  fi

  # Copy supplementary Korean .qm from Linux addons
  msg "Copying supplementary Korean .qm from Linux addons..."
  find "${mui_dir}/../addons" -name "*.qm" -path "*/ko_KR/*" 2>/dev/null | while read -r qm_file; do
    local addon_name=$(basename $(dirname $(dirname "$qm_file")))
    local target_dir="${ko_dir}/${addon_name}"
    mkdir -p "${target_dir}"
    cp "$qm_file" "${target_dir}/"
    msg2 "Installed (Linux): ${addon_name}/$(basename "$qm_file")"
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

  # Set default locale to Korean
  sed -i '2i export LC_ALL=ko_KR.UTF-8' usr/bin/{wps,wpp,et,wpspdf}
  sed -i '2i export LANG=ko_KR.UTF-8' usr/bin/{wps,wpp,et,wpspdf}

  # Add MIME detection disable to launcher
  for app in wps wpp et wpspdf; do
    sed -i '2a # Disable WPS Office MIME type detection at startup\nif [[ -x /usr/bin/wps-office-disable-mime-detection ]]; then\n  /usr/bin/wps-office-disable-mime-detection\nfi' usr/bin/${app}
  done

  # Fix bsdtar warning
  export LC_ALL=C

  # Install license
  install -Dm644 -t usr/share/licenses/${pkgname} opt/kingsoft/wps-office/office6/mui/default/*.html
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

  install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" \
    "${srcdir}/opt/kingsoft/wps-office/office6/mui/default/"*.html
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
    "${srcdir}/opt/kingsoft/wps-office/office6/mui/default/"*.html
}

# vim:set ts=2 sw=2 et: