# Maintainer: WPS Office Korean Patch Project (CN base - actively reflects wps-office-cn AUR)
# Base PKGBUILD: wps-office-cn AUR (https://aur.archlinux.org/packages/wps-office-cn)
# Korean patches added on top: locale ko_KR, yyyy-MM-dd, MIME/font, login bypass

pkgbase=wps-office-kr
pkgname=('wps-office-kr' 'wps-office-kr-mime' 'wps-office-kr-fonts')
pkgver=12.1.2.28080
pkgrel=1
pkgdesc="WPS Office with Korean locale, default yyyy-MM-dd date format, fixed MIME types, and improved font rendering (CN base, /usr/lib/office6)"
arch=('x86_64' 'aarch64')
url="https://github.com/nahdd123uosackr/wps-office-kr"
license=('LicenseRef-WPS-EULA')
options=('!emptydirs')
makedepends=('tar' 'xz' 'fontconfig' 'curl' 'jq' 'qt5-tools' 'python-pip' 'libarchive')

# GitHub Release
_gh_repo="nahdd123uosackr/wps-office-kr"
_gh_api="https://api.github.com/repos/${_gh_repo}"

# Upstream CN source - actively reflects wps-office-cn AUR _get_source_url
_get_source_url() {
    local furl="https://wps-linux-personal.wpscdn.cn/wps/download/ep/Linux2023/${pkgver##*.}/wps-office_${pkgver}.AK.preread.sw.Personal_765474_$1.deb"
    local uri="${furl#https://wps-linux-personal.wpscdn.cn}"
    local secrityKey='7f8faaaa468174dc1c9cd62e5f218a5b'
    local timestamp10=$(date '+%s')
    local md5hash=$(echo -n "${secrityKey}${uri}${timestamp10}" | md5sum)
    echo "${furl}?t=${timestamp10}&k=${md5hash%% *}"
}
source_x86_64=("wps-office_${pkgver}_amd64.deb::$(_get_source_url amd64)")
source_aarch64=("wps-office_${pkgver}_arm64.deb::$(_get_source_url arm64)")
sha256sums_x86_64=('2fa999f60a71e21093ab49ef6d7f61d7668c844bfebf30907d2c290e460f9be0')
sha256sums_aarch64=('SKIP')

install=wps-office-kr.install

# Korean locale patches (on top of CN base)
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

_check_prebuilt() {
  local tag="v${pkgver}"
  local api_url="${_gh_api}/releases/tags/${tag}"
  msg "Checking for pre-built packages at ${api_url}..."
  local curl_args=(-sL)
  [[ -n "${GITHUB_TOKEN}" ]] && curl_args+=(-H "Authorization: token ${GITHUB_TOKEN}")
  local release_info
  release_info=$(curl "${curl_args[@]}" "${api_url}" 2>/dev/null) || return 1
  echo "${release_info}" | jq -e '.assets | length > 0' >/dev/null 2>&1 || return 1
  local assets
  assets=$(echo "${release_info}" | jq -r '.assets[] | select(.name | test("wps-office-kr.*\\.pkg\\.tar\\.zst$")) | "\(.name)|\(.browser_download_url)"')
  [[ -z "${assets}" ]] && return 1
  echo "${assets}"
  return 0
}
_download_prebuilt() {
  local assets="$1"
  local pkgname="$2"
  local pkgfile="${pkgname}-${pkgver}-${pkgrel}-${CARCH}.pkg.tar.zst"
  [[ "${CARCH}" == "any" ]] && pkgfile="${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst"
  local url
  url=$(echo "${assets}" | grep "^${pkgfile}|" | cut -d'|' -f2)
  [[ -z "${url}" ]] && return 1
  msg "Downloading pre-built package: ${pkgfile}..."
  curl -sL "${url}" -o "${pkgfile}" || return 1
  bsdtar -tf "${pkgfile}" .PKGINFO >/dev/null 2>&1 || return 1
  install -Dm644 "${pkgfile}" "${PKGDEST}/${pkgfile}" 2>/dev/null || cp "${pkgfile}" "${PKGDEST}/"
  return 0
}

prepare() {
  if [[ -n "${USE_PREBUILT}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
    msg "Using pre-built packages, skipping source preparation"
    return 0
  fi
  msg "Preparing source from upstream (CN base)..."
  # CN AUR: bsdtar -xpf data.tar.xz (ar already handled by makepkg source extraction, but we handle both)
  if [[ ! -f data.tar.xz ]]; then
    for deb_file in wps-office_*_amd64.deb *.deb; do
      [[ -f "$deb_file" ]] || continue
      msg "Extracting $deb_file..."
      ar x "$deb_file" 2>/dev/null || true
      break
    done
  fi
  if [[ -f data.tar.xz ]]; then
    bsdtar -xpf data.tar.xz
  elif [[ -f data.tar ]]; then
    bsdtar -xpf data.tar
  fi
  # CN AUR: fix launchers /opt -> /usr/lib (actively reflected)
  if [[ -d usr/bin ]]; then
    msg "Patching launchers /opt/kingsoft/wps-office -> /usr/lib (CN base)..."
    sed -i 's|/opt/kingsoft/wps-office|/usr/lib|' usr/bin/* 2>/dev/null || true
    [[ "$CARCH" = "aarch64" ]] && sed -i '2a export LD_PRELOAD=/usr/lib/libfreetype.so' usr/bin/* 2>/dev/null || true
  fi
  # Keep wps_한글_패치 compatibility: also handle opt path if needed (no-op for CN)
  local script_src="$(dirname "${BASH_SOURCE[0]}")/scripts"
  if [[ -d "${script_src}" ]]; then
    cp -r "${script_src}" "${srcdir}/"
  fi
  local patch_src="$(dirname "${BASH_SOURCE[0]}")/wps_한글_패치"
  if [[ -d "${patch_src}" ]]; then
    cp -r "${patch_src}" "${srcdir}/" 2>/dev/null || true
    msg "Copied wps_한글_패치 to srcdir for human translation (klangkokr 167파일)"
  fi
  # klangkokr 추출은 빌드에서 제거 - 별도 자정 스케줄에서 처리 (매일 자정 새버전 감지)
}

_install() {
  bsdtar --no-same-owner -C "${pkgdir}" -xf data.tar "$@" 2>/dev/null || bsdtar --no-same-owner -C "${pkgdir}" -xf ../data.tar "$@" 2>/dev/null || true
}

_apply_korean_patches() {
  # CN base: office is at /usr/lib/office6 (actively reflects wps-office-cn)
  local office_root="${pkgdir}/usr/lib/office6"
  mkdir -p "${office_root}/mui/ko_KR/config"
  cp "${srcdir}/ko_KR_datetimeformat.patch" "${office_root}/mui/ko_KR/config/datetimeformat.cfg"
  cp "${srcdir}/ko_KR_controldatetimeformat.patch" "${office_root}/mui/ko_KR/config/controldatetimeformat.cfg"
  cp "${srcdir}/ko_KR_idstr.patch" "${office_root}/mui/ko_KR/config/idstr.cfg"
  cat > "${office_root}/mui/ko_KR/lang.conf" << 'LANDEOF'
[Language]
DisplayName=한국어
DisplayName[en_US]=Korean
DisplayName[zh_CN]=韩语
Icon=ko_KR.png
Community=true
LANDEOF
  cp "${office_root}/mui/default/config/numberformat/ko_KR.cfg" "${office_root}/mui/ko_KR/config/numberformat.cfg" 2>/dev/null || true
  for cfg_file in downloadIrmUrl.cfg envelopesproperties.cfg localizedfunctionname.cfg printpaper.cfg wpplist.cfg wpsfieldnumber.cfg wpslist.cfg; do
    if [[ -f "${office_root}/mui/default/config/${cfg_file}" ]]; then
      cp "${office_root}/mui/default/config/${cfg_file}" "${office_root}/mui/ko_KR/config/${cfg_file}"
    fi
  done
  for res_file in DesignScience.png EULA_linux.html Privacy_Linux.html; do
    if [[ -f "${office_root}/mui/default/${res_file}" ]]; then
      cp "${office_root}/mui/default/${res_file}" "${office_root}/mui/ko_KR/${res_file}"
    fi
  done
  for rcc_file in "${office_root}/mui/default/"*.rcc; do
    [[ -f "$rcc_file" ]] && cp "$rcc_file" "${office_root}/mui/ko_KR/"
  done
  python3 -c "
import struct, zlib
width, height = 32, 32
raw_data = b''
for y in range(height):
    raw_data += b'\x00'
    for x in range(width):
        cx, cy = width//2, height//2
        dx, dy = x - cx, y - cy
        dist = (dx*dx + dy*dy) ** 0.5
        if dist < 10:
            raw_data += bytes([255, 255, 255, 255])
        else:
            raw_data += bytes([66, 133, 244, 255])
def make_chunk(chunk_type, data):
    chunk = chunk_type + data
    return struct.pack('>I', len(data)) + chunk + struct.pack('>I', zlib.crc32(chunk) & 0xffffffff)
png = b'\x89PNG\r\n\x1a\n'
png += make_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
png += make_chunk(b'IDAT', zlib.compress(raw_data))
png += make_chunk(b'IEND', b'')
with open('${office_root}/mui/ko_KR/ko_KR.png', 'wb') as f:
    f.write(png)
"
  if [[ -f "${office_root}/cfgs/setup.cfg" ]]; then
    if grep -q '^UILanguage=' "${office_root}/cfgs/setup.cfg"; then
      sed -i 's/^UILanguage=.*/UILanguage=ko_KR/' "${office_root}/cfgs/setup.cfg"
    else
      echo "UILanguage=ko_KR" >> "${office_root}/cfgs/setup.cfg"
    fi
    sed -i 's/^ContentEnabledLangs=.*/ContentEnabledLangs=0/' "${office_root}/cfgs/setup.cfg" 2>/dev/null || true
    grep -q '^ContentEnabledLangs=' "${office_root}/cfgs/setup.cfg" || echo "ContentEnabledLangs=0" >> "${office_root}/cfgs/setup.cfg"
  fi
  mkdir -p "${office_root}/cfgs/default"
  cat > "${office_root}/cfgs/default/Office.conf" << 'EOF'
[6.0]
UILanguage=ko_KR
forbidEditInForceLogin=false
enableForceLogin=false
enableForceLoginForFirstInstallDevice=false
EnableForceLoginFori18n2c=false
EnableLoginEntranceStyle=false

[Application Settings]
UILanguage=ko_KR

[kl]
UILanguage=ko_KR

[Versions]

[6.0\Common]
UILanguage=ko_KR
forbidEditInForceLogin=false
enableForceLogin=false

[common]
do_not_detect_file_association_while_startup=true
forbidEditInForceLogin=false
enableForceLogin=false
enableForceLoginForFirstInstallDevice=false

wps\Custom%20Application%20Settings\MeasurementUnit=cm
wpp\Custom%20Application%20Settings\MeasurementUnit=cm
et\Custom%20Application%20Settings\MeasurementUnit=cm
EOF
  mkdir -p "${pkgdir}/etc/xdg/Kingsoft"
  cp "${office_root}/cfgs/default/Office.conf" "${pkgdir}/etc/xdg/Kingsoft/Office.conf"
  local en_us_dir="${office_root}/mui/en_US"
  local ko_kr_dir="${office_root}/mui/ko_KR"
  local ts_extract_dir="${srcdir}/ts_extracted"
  mkdir -p "$ts_extract_dir"
  if command -v lconvert &>/dev/null; then
    for qm_file in "${en_us_dir}"/*.qm; do
      [[ -f "$qm_file" ]] || continue
      local base=$(basename "$qm_file" .qm)
      lconvert -i "$qm_file" -o "${ts_extract_dir}/${base}.ts" 2>/dev/null && msg2 "Extracted: ${base}.ts" || msg2 "Skip: ${base}.qm"
    done
  else
    msg2 "lconvert not available, using pre-extracted .ts from win_translations"
  fi
  if [[ -f "${srcdir}/scripts/build_translations.sh" ]]; then
    local ts_source="${ts_extract_dir}"
    if [[ ! "$(ls -A ${ts_source}/*.ts 2>/dev/null)" ]]; then
      ts_source="${srcdir}/win_translations"
    fi
    if [[ -d "$ts_source" ]] && [[ "$(ls -A ${ts_source}/*.ts 2>/dev/null)" ]]; then
      bash "${srcdir}/scripts/build_translations.sh" "$ts_source" "$ko_kr_dir" "${srcdir}/translation_dict.json" 2>&1 | while IFS= read -r line; do msg2 "$line"; done
    else
      msg2 "Warning: No .ts files found for translation"
    fi
  fi
  install -Dm644 "${srcdir}/99-wps-office-font-rendering.conf" "${office_root}/fonts/conf/99-wps-office-font-rendering.conf"
  install -Dm644 "${srcdir}/wps-office-mime.xml" "${office_root}/mime/wps-office-mime.xml"
  install -Dm755 "${srcdir}/wps-office-disable-mime-detection.sh" "${office_root}/wps-office-disable-mime-detection.sh"
}

_build_translations() {
  msg "Building Korean translation files (build-time pipeline)..."
  local mui_dir="${pkgdir}/usr/lib/office6/mui"
  local ko_dir="${mui_dir}/ko_KR"
  mkdir -p "${ko_dir}"
  # Priority 1: wps_한글_패치 human translation (complete, 729K et.qm) - directly reflects manual patch
  local wps_patch_dir=""
  for cand in "${srcdir}/wps_한글_패치/ko_KR" "$(dirname "${BASH_SOURCE[0]}")/wps_한글_패치/ko_KR" "./wps_한글_패치/ko_KR"; do
    if [[ -d "$cand" ]]; then wps_patch_dir="$cand"; break; fi
  done
  if [[ -n "$wps_patch_dir" && -d "$wps_patch_dir" ]]; then
    msg "Using wps_한글_패치 human translation: $wps_patch_dir"
    local patch_cnt=0
    for qm_file in "${wps_patch_dir}"/*.qm; do
      [[ -f "$qm_file" ]] || continue
      cp "$qm_file" "${ko_dir}/"
      msg2 "Installed (wps_한글_패치): $(basename "$qm_file") ($(stat -c '%s' "$qm_file") bytes)"
      patch_cnt=$((patch_cnt+1))
    done
    [[ -f "${wps_patch_dir}/lang.conf" ]] && cp "${wps_patch_dir}/lang.conf" "${ko_dir}/lang.conf" 2>/dev/null || true
    [[ -f "${wps_patch_dir}/ko_KR.png" ]] && cp "${wps_patch_dir}/ko_KR.png" "${ko_dir}/ko_KR.png" 2>/dev/null || true
    # Actively reflect apply_wps_kokr_langpack.sh: addon별 mui/ko_KR 및 wps-i18n/ko-kr 병합
    local patch_addons_dir="$(dirname "$wps_patch_dir")/addons"
    # wps_한글_패치의 addons는 ko_KR 루트에 없으므로, klangkokr 풀 구조를 따름
    # 실제 wps_한글_패치에는 addons가 별도로 없으나, klangkokr 풀에서는 addons/*/mui/ko_KR 및 wps-i18n/ko-kr 존재
    # 호환: wps_한글_패치 상위에서 klangkokr 풀 탐색
    local klang_pool=""
    for pool_cand in "$HOME/.wine-wps-kokr/drive_c/users/$USER/AppData/Roaming/kingsoft/wps_intl/addons/pool/win-x64/klangkokr_"* "$HOME/.wine/drive_c/users/$USER/AppData/Roaming/kingsoft/wps_intl/addons/pool/win-x64/klangkokr_"*; do
      [[ -d "$pool_cand" ]] || continue
      klang_pool="$pool_cand"
      break
    done
    # Fallback to wps_한글_패치의 상위 klangkokr (if exists)
    if [[ -z "$klang_pool" ]]; then
      for cand in "${srcdir}/klangkokr" "$(dirname "${BASH_SOURCE[0]}")/klangkokr" "./klangkokr"; do
        if [[ -d "$cand" && -d "$cand/addons" ]]; then klang_pool="$cand"; break; fi
      done
    fi
    if [[ -n "$klang_pool" && -d "$klang_pool/addons" ]]; then
      msg "Merging klangkokr addons from $klang_pool (apply_wps_kokr_langpack.sh logic)..."
      for moddir in "$klang_pool"/addons/*/; do
        [[ -d "$moddir" ]] || continue
        local name=$(basename "$moddir")
        local target="${pkgdir}/usr/lib/office6/addons/$name"
        # Only if target addon exists in Linux package
        [[ -d "$target" ]] || continue
        # 2a. mui/ko_KR
        if [[ -d "$moddir/mui/ko_KR" ]]; then
          mkdir -p "${ko_dir}/../ko_KR" 2>/dev/null || true
          # For main ko_KR, addons are in subdirs; for package, we copy to ko_KR/<addon>
          local addon_target="${ko_dir}/$name"
          mkdir -p "$addon_target"
          for qm in "$moddir/mui/ko_KR"/*; do
            [[ -f "$qm" ]] && cp -a "$qm" "$addon_target/" 2>/dev/null && msg2 "Addon $name mui: $(basename "$qm")"
          done
          # Also copy to target mui if exists
          mkdir -p "$target/mui"
          cp -a "$moddir/mui/ko_KR" "$target/mui/" 2>/dev/null || true
        fi
        # 2b. wps-i18n/ko-kr (multiple paths)
        while IFS= read -r wdir; do
          [[ -z "$wdir" ]] || [[ ! -d "$wdir" ]] && continue
          local rel="${wdir#"$moddir"}"
          local destdir="$target/$(dirname "$rel")"
          mkdir -p "$destdir" 2>/dev/null || true
          cp -a "$wdir" "$destdir/" 2>/dev/null && msg2 "Addon $name i18n: $rel"
        done < <(find "$moddir" -type d -path "*/wps-i18n/ko-kr" 2>/dev/null)
      done
    fi
    if [[ "$patch_cnt" -ge 5 ]]; then
      msg "wps_한글_패치: $patch_cnt qm installed, skipping machine translation"
      install -Dm644 "${srcdir}/translation_dict.json" "${ko_dir}/translation_dict.json" 2>/dev/null || true
      return 0
    fi
  fi
  local src_ts_tar="${srcdir}/win_translations.tar.gz"
  local src_ts_dir="${srcdir}/win_translations"
  if [[ -f "${src_ts_tar}" ]]; then
    tar -xzf "${src_ts_tar}" -C "${srcdir}" 2>/dev/null || true
  fi
  if [[ ! -d "${src_ts_dir}" ]]; then
    msg2 "Warning: Source .ts directory not found at ${src_ts_dir}"
    return 0
  fi
  msg "Running build-time translation pipeline (fallback)..."
  if [[ -f "${srcdir}/scripts/build_translations.sh" ]]; then
    bash "${srcdir}/scripts/build_translations.sh" "${src_ts_dir}" "${srcdir}/build_qm" "${srcdir}/translation_dict.json" 2>&1 | while IFS= read -r line; do msg2 "$line"; done
  else
    msg2 "Warning: build_translations.sh not found, skipping pipeline"
    return 0
  fi
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
  msg "Copying supplementary Korean .qm from Linux addons..."
  find "${mui_dir}/../addons" -name "*.qm" -path "*/ko_KR/*" 2>/dev/null | while read -r qm_file; do
    local addon_name=$(basename $(dirname $(dirname $(dirname "$qm_file"))))
    local target_dir="${ko_dir}/${addon_name}"
    mkdir -p "${target_dir}"
    cp "$qm_file" "${target_dir}/"
    msg2 "Installed (Linux): ${addon_name}/$(basename "$qm_file")"
  done
  for src_qm in "${mui_dir}/../addons"/*/mui/ko_KR/*.qm; do
    [[ -f "$src_qm" ]] || continue
    base=$(basename "$src_qm")
    if [[ ! -f "${ko_dir}/${base}" ]]; then
      true
    fi
  done
  install -Dm644 "${srcdir}/translation_dict.json" "${ko_dir}/translation_dict.json" 2>/dev/null || true
  msg "Korean translation files installed (build-time pipeline)"
}

build() {
  if [[ -n "${USE_PREBUILT}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
    msg "Attempting to use pre-built packages from GitHub Release..."
    local assets
    assets=$(_check_prebuilt) || {
      msg "No pre-built packages found, falling back to source build"
      USE_PREBUILT=0
    }
    if [[ -n "${assets}" ]] && [[ "${USE_PREBUILT}" != "0" ]]; then
      msg "Pre-built packages found! Downloading..."
      _download_prebuilt "${assets}" "wps-office-kr" || USE_PREBUILT=0
      _download_prebuilt "${assets}" "wps-office-kr-mime" || USE_PREBUILT=0
      _download_prebuilt "${assets}" "wps-office-kr-fonts" || USE_PREBUILT=0
      if [[ "${USE_PREBUILT}" != "0" ]]; then
        msg "Successfully downloaded all pre-built packages"
        return 0
      fi
    fi
  fi
  msg "Building from source (CN base, actively reflects wps-office-cn AUR)..."
  return 0
}

# Actively reflects wps-office-cn AUR package_wps-office-cn()
package_wps-office-kr() {
  depends=('fontconfig' 'xorg-mkfontscale' 'libxrender' 'desktop-file-utils' 'shared-mime-info' 'xdg-utils' 'glu' 'sdl2' 'libpulse' 'hicolor-icon-theme' 'libxss' 'sqlite' 'libtool' 'libxslt' 'libjpeg-turbo')
  optdepends=('cups: for printing support'
              'libjpeg-turbo: JPEG image codec support'
              'pango: for complex (right-to-left) text support'
              'curl: An URL retrieval utility and library'
              'ttf-wps-fonts: Symbol fonts required by wps-office'
              'ttf-ms-fonts: Microsft Fonts recommended for wps-office'
              'wps-office-fonts: FZ TTF fonts provided by wps community'
              'wps-office-mime-cn: Use mime files provided by Kingsoft'
              'wps-office-mui-zh-cn: zh_CN support for WPS Office'
              'wps-office-kr-fonts: Korean fonts provided by WPS Office')
  conflicts=('wps-office' 'wps-office-365' 'wps-office-cn' 'wps-office-mime' 'kingsoft-office')
  provides=('wps-office' 'wps-office-mime')
  install="${pkgname}.install"
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
  # --- CN base: actively reflects package_wps-office-cn() ---
  cd "${srcdir}/opt/kingsoft/wps-office/"
  install -d "${pkgdir}/usr/lib"
  cp -r office6 "${pkgdir}/usr/lib"
  rm "${pkgdir}/usr/lib/office6/libstdc++.so"* 2>/dev/null || true
  rm "${pkgdir}/usr/lib/office6/libjpeg.so"* 2>/dev/null || true
  [[ "$CARCH" = "aarch64" ]] && rm "${pkgdir}"/usr/lib/office6/libfreetype.so* 2>/dev/null || true
  install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" office6/mui/default/*.html 2>/dev/null || true
  rm -r "${pkgdir}/usr/lib/office6/mui/en_US/resource/help" 2>/dev/null || true
  # Korean patch: add ko_KR on top of CN base (wps_한글_패치 호환)
  _apply_korean_patches
  _build_translations
  cd "${pkgdir}"
  rm -f usr/lib/office6/lib{jpeg,stdc++}.so* 2>/dev/null || true
  install -d usr/share/fontconfig/conf.avail
  install -d usr/share/fontconfig/conf.default
  if [[ -f usr/lib/office6/fonts/conf/99-wps-office-font-rendering.conf ]]; then
    install -m644 usr/lib/office6/fonts/conf/99-wps-office-font-rendering.conf usr/share/fontconfig/conf.avail/99-wps-office-font-rendering.conf
  fi
  ln -sf ../conf.avail/99-wps-office-font-rendering.conf usr/share/fontconfig/conf.default/99-wps-office-font-rendering.conf 2>/dev/null || true
  install -d usr/share/mime/packages
  install -m644 "${srcdir}/wps-office-mime.xml" usr/share/mime/packages/wps-office.xml 2>/dev/null || true
  install -m755 usr/lib/office6/wps-office-disable-mime-detection.sh usr/bin/wps-office-disable-mime-detection 2>/dev/null || install -m755 "${srcdir}/wps-office-disable-mime-detection.sh" usr/bin/wps-office-disable-mime-detection 2>/dev/null || true
  # CN base: install launchers, desktop files, icons, fonts, menu (actively reflected)
  install -d "${pkgdir}/usr/bin"
  if [[ -d "${srcdir}/usr/bin" ]]; then
    install -m755 "${srcdir}/usr/bin"/* "${pkgdir}/usr/bin" 2>/dev/null || true
  fi
  if [[ -d "${srcdir}/usr/share/applications" ]]; then
    install -d "${pkgdir}/usr/share/applications"
    cp -r "${srcdir}/usr/share/applications"/* "${pkgdir}/usr/share/applications" 2>/dev/null || true
  fi
  if [[ -d "${srcdir}/usr/share/desktop-directories" ]]; then
    install -d "${pkgdir}/usr/share/desktop-directories"
    cp -r "${srcdir}/usr/share/desktop-directories"/* "${pkgdir}/usr/share/desktop-directories" 2>/dev/null || true
  fi
  if [[ -d "${srcdir}/usr/share/icons" ]]; then
    install -d "${pkgdir}/usr/share/icons"
    cp -r "${srcdir}/usr/share/icons"/* "${pkgdir}/usr/share/icons" 2>/dev/null || true
  fi
  if [[ -f "${srcdir}/etc/xdg/menus/applications-merged/wps-office.menu" ]]; then
    install -Dm644 "${srcdir}/etc/xdg/menus/applications-merged/wps-office.menu" "${pkgdir}/etc/xdg/menus/applications-merged/wps-office.menu"
  fi
  if [[ -d "${srcdir}/usr/share/fonts" ]]; then
    install -d "${pkgdir}/usr/share/fonts"
    cp -r "${srcdir}/usr/share/fonts"/* "${pkgdir}/usr/share/fonts" 2>/dev/null || true
  fi
  # Korean patch: desktop categories, IME, fontconfig, login bypass, locale (on top of CN)
  sed -i 's|Categories=.*|&Office;|' usr/share/applications/*.desktop 2>/dev/null || true
  sed -i '2i [[ "$XMODIFIERS" == "@im=fcitx" ]] && export QT_IM_MODULE=fcitx' usr/bin/{wps,wpp,et,wpspdf} 2>/dev/null || true
  sed -i '2i [[ -f ~/.config/Kingsoft/fonts/fonts.conf ]] && export FONTCONFIG_FILE=~/.config/Kingsoft/fonts/fonts.conf' usr/bin/{wps,wpp,et,wpspdf} 2>/dev/null || true
  for app in wps wpp et wpspdf; do
    sed -i '2i # Disable forced login - allow editing without Kingsoft account\nif [[ -f "$HOME/.config/Kingsoft/Office.conf" ]]; then\n  for key in enableForceLogin forbidEditInForceLogin enableForceLoginForFirstInstallDevice EnableForceLoginFori18n2c; do\n    if grep -q "$key" "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null; then\n      sed -i "s/$key=.*/$key=false/" "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null\n    else\n      if grep -q "^\\[6.0\\]" "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null; then\n        sed -i "/^\\[6.0\\]/a $key=false" "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null\n      elif grep -q "^\\[common\\]" "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null; then\n        sed -i "/^\\[common\\]/a $key=false" "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null\n      else\n        echo "$key=false" >> "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null\n      fi\n    fi\n  done\nfi' usr/bin/${app} 2>/dev/null || true
  done
  for app in wps wpp et wpspdf; do
    sed -i '2a\
# Clear stale locale cache to apply Korean UI\
if [[ -f "$HOME/.config/Kingsoft/Office.conf" ]]; then\
  sed -i "s/UILanguage=.*/UILanguage=ko_KR/" "$HOME/.config/Kingsoft/Office.conf" 2>/dev/null\
fi' usr/bin/${app} 2>/dev/null || true
  done
  for app in wps wpp et wpspdf; do
    sed -i '2i\
# Force Korean locale for UI and font name display\
export LANG=ko_KR.UTF-8\
export LC_ALL=ko_KR.UTF-8\
export LANGUAGE=ko_KR:ko\
export LC_CTYPE=ko_KR.UTF-8' usr/bin/${app} 2>/dev/null || true
  done
  for app in wps wpp et wpspdf; do
    sed -i '2a # Disable WPS Office MIME type detection at startup\nif [[ -x /usr/bin/wps-office-disable-mime-detection ]]; then\n  /usr/bin/wps-office-disable-mime-detection\nfi' usr/bin/${app} 2>/dev/null || true
  done
  install -Dm755 "${srcdir}/scripts/wps-office-kr-setup.sh" "${pkgdir}/usr/bin/wps-office-kr-setup" 2>/dev/null || true
  install -Dm644 "${srcdir}/wps-office-kr.hook" "${pkgdir}/usr/share/libalpm/hooks/wps-office-kr.hook" 2>/dev/null || true
  install -Dm644 "${srcdir}/wps-office-kr.install" "${pkgdir}/usr/share/doc/${pkgname}/wps-office-kr.install" 2>/dev/null || true
  export LC_ALL=C
  if [[ -d usr/lib/office6/mui/default ]]; then
    install -Dm644 -t usr/share/licenses/${pkgname} usr/lib/office6/mui/default/*.html 2>/dev/null || true
  fi
  # Only /usr/lib - no /opt duplication (user request)
}

# Actively reflects wps-office-mime-cn AUR
package_wps-office-kr-mime() {
  pkgdesc="MIME type definitions for WPS Office (prevents system MIME override issues)"
  arch=('any')
  depends=('shared-mime-info')
  conflicts=('wps-office-mime' 'wps-office-mime-cn')
  provides=('wps-office-mime')
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
  install -d "${pkgdir}/usr/share/mime/packages"
  install -m644 "${srcdir}/wps-office-mime.xml" "${pkgdir}/usr/share/mime/packages/wps-office.xml"
  if [[ -d "${srcdir}/opt/kingsoft/wps-office/office6/mui/default" ]]; then
    install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" "${srcdir}/opt/kingsoft/wps-office/office6/mui/default/"*.html 2>/dev/null || true
  elif [[ -d "${srcdir}/usr/lib/office6/mui/default" ]]; then
    install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" "${srcdir}/usr/lib/office6/mui/default/"*.html 2>/dev/null || true
  fi
  cd "${srcdir}/usr/share"
  install -d "${pkgdir}/usr/share/mime" 2>/dev/null || true
  cp -r mime/* "${pkgdir}/usr/share/mime" 2>/dev/null || true
}

package_wps-office-kr-fonts() {
  pkgdesc="Korean fonts provided by WPS Office"
  arch=('any')
  conflicts=('wps-office-fonts' 'wps-office-365-fonts' 'wps-office-cn-fonts')
  provides=('wps-office-fonts')
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
  _install ./etc/fonts ./usr/share/fonts 2>/dev/null || true
  if [[ -f "${pkgdir}/etc/fonts/conf.avail/40-wps-office.conf" ]]; then
    install -d "${pkgdir}/usr/share/fontconfig/conf.avail"
    install -d "${pkgdir}/usr/share/fontconfig/conf.default"
    install -m644 "${pkgdir}/etc/fonts/conf.avail/40-wps-office.conf" "${pkgdir}/usr/share/fontconfig/conf.avail/40-wps-office.conf"
    ln -sf ../conf.avail/40-wps-office.conf "${pkgdir}/usr/share/fontconfig/conf.default/40-wps-office.conf"
  fi
  install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" "${srcdir}/opt/kingsoft/wps-office/office6/mui/default/"*.html 2>/dev/null || install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" "${srcdir}/usr/lib/office6/mui/default/"*.html 2>/dev/null || true
}

# vim:set ts=2 sw=2 et:
