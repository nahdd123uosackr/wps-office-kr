# WPS Office KR - 한국어 패치

WPS Office 12 (CN base, `12.1.2.28080`)에 한국어 UI, `yyyy-MM-dd` 기본 날짜서식, MIME 보호, 폰트 개선, 로그인 강제 해제를 적용한 Arch Linux용 재현 빌드. `wps_한글_패치` 휴먼번역(klangkokr 167파일)을 1순위로 탑재하고, GitHub Actions로 매일 자동 빌드·릴리즈.

**저장소:** https://github.com/nahdd123uosackr/wps-office-kr

---

## 주요 구현

### 1. 한국어 로케일 (`/usr/lib/office6/mui/ko_KR`)
- `patches/ko_KR/config/{datetimeformat.cfg,controldatetimeformat.cfg,idstr.cfg}` → `yyyy-MM-dd`를 index 1로 고정 (`id="1042"`, `preStr="[$-412]"`)
- `lang.conf` `DisplayName=한국어 (대한민국)` `Community=true` `Icon=ko_KR.png` (wps_한글_패치 원본)
- `numberformat/ko_KR.cfg` 및 `downloadIrmUrl.cfg` 등 7종 필수 cfg 복사, `.rcc`/`DesignScience.png` 복제
- `PKGBUILD:_apply_korean_patches()` 와 `scripts/wps-office-kr-setup.sh` 가 동일 로직으로 시스템/사용자 `Office.conf`에 `UILanguage=ko_KR` 강제

### 2. 번역 파이프라인
- **1순위 휴먼번역:** `wps_한글_패치/ko_KR` 18개 `*.qm` (`et.qm 713K`, `kso.qm 494K` 등) - `klangkokr_3.1.0.399`에서 Wine `pool/win-x64/klangkokr_*/ko_KR` 추출본. `PKGBUILD:prepare()`가 `wps_한글_패치`를 `srcdir`로 복사, `_build_translations()`가 이를 `usr/lib/office6/mui/ko_KR`에 직접 `cp` (기계번역 스킵)
- **2순위 기계번역 fallback:** `win_translations.tar.gz` (en_US `lconvert` 추출 20개 `*.ts`) + `translation_dict.json` 176개 (wps_한글_패치에서 추출 161 + win 25개 커버) + `ArgosTranslate` (`en→ko` 모델, `wps-kr-build.yml`에서 `pip --break-system-packages`로 강제 설치). `scripts/build_translations.sh`가 `source` 비어있고 `translation`에 영문이 있는 WPS quirk를 처리
- **추출 자동화:** `scripts/extract_klangkokr.sh` (Wine 풀 자동탐색 `sort -V | tail -1` → APKPure 254M `exe` 다운로드 후 `wine /S` silent install) + `scripts/get_wps_windows.sh` (https://www.wps.com/download/ `600.1002` 동적 감지)

### 3. 빌드 베이스
- **CN base 전면 반영:** `PKGBUILD`가 `wps-office-cn` AUR 원문을 베이스로 재구성 - `_get_source_url()` 서명 URL(`t/k`), `prepare()` `bsdtar -xpf` + `sed s|/opt|/usr/lib|`, `package_wps-office-kr()` `cp -r office6 → /usr/lib`, `libstdc++/libjpeg` 제거, `help/zh_CN` 정리, `bin/applications/icons/fonts/menu` 설치 순서 동일. 경로는 `/usr/lib/office6` 단일, `wps_한글_패치` `DEFAULT_DST`와 일치
- **호환성:** `/opt` 중복 제거 (이전 866M 중복 → 단일), `wps_한글_패치` 수동 설치와 동일 경로

### 4. 로그인 강제 해제
- `Office.conf` 5키: `forbidEditInForceLogin=false`, `enableForceLogin=false`, `enableForceLoginForFirstInstallDevice=false`, `EnableForceLoginFori18n2c=false`, `EnableLoginEntranceStyle=false` 를 `PKGBUILD:cfgs/default/Office.conf` 및 `wps-office-kr-setup.sh` 사용자/시스템 모두에 idempotent 적용. 런처 `wps/wpp/et/wpspdf`도 매 실행 시 `Office.conf` 패치

### 5. MIME 보호 (3중)
- `wps-office-mime.xml` (WPS 고유 `.wps/.et/.dps/.ofd`만 정의) + `Office.conf` `do_not_detect_file_association_while_startup=true` + `wps-office-disable-mime-detection.sh` (`Override.xml` 삭제 + `update-mime-database`)

### 6. 폰트 렌더링 (OnlyOffice 방식)
- `99-wps-office-font-rendering.conf` : `Calibri→Carlito`, `Cambria→Caladea`, `Arial→Liberation Sans` 등 메트릭 호환 대체, `Noto Sans CJK KR` 폴백, `hintslight` + 서브픽셀. `PKGBUILD`가 `fonts/conf` 및 `fontconfig`에 설치

### 7. 후속 프로세스
- `wps-office-kr-setup.sh` (`/usr/bin/wps-office-kr-setup`): `--system` (locale, `setup.cfg`, `Office.conf`, `mui` 검증, `fc-cache` 등) + `--user` (`~/.config/Kingsoft/Office.conf` 패치, `Override.xml` 제거) + `--check` 검증
- `wps-office-kr.install` `post_install/post_upgrade` 및 `wps-office-kr.hook` `PostTransaction`에서 자동 실행

### 8. 자동 빌드
- **`klangkokr-update.yml` 매일 15:00 UTC (KST 자정):** `wps_한글_패치`/`translation_dict` 변경 감지, `lconvert`로 사전 재구축, 변경 시 커밋
- **`wps-kr-build.yml` 매일 19:00 UTC (KST 새벽 4시, klangkokr 이후):** `linux.wps.cn`/`AUR` 4곳에서 `pkgver` 감지, `translation_updated`도 함께 체크, `changed || translation_updated` 시 `archlinux:base-devel` 컨테이너에서 `makepkg -s` → `Verify` → `Release` (`softprops/action-gh-release`) → `wps-office-kr-*.pkg.tar.zst` 첨부. `push` 트리거 (`translation_dict.json` 등)도 지원
- **수동:** `gh workflow run wps-kr-build.yml -f force_build=true`

---

## 설치

```bash
# GitHub Release (권장)
sudo pacman -U https://github.com/nahdd123uosackr/wps-office-kr/releases/download/v12.1.2.28080/wps-office-kr-12.1.2.28080-1-x86_64.pkg.tar.zst
sudo pacman -U wps-office-kr-mime-*.pkg.tar.zst wps-office-kr-fonts-*.pkg.tar.zst

# 또는 PKGBUILD
git clone https://github.com/nahdd123uosackr/wps-office-kr.git
cd wps-office-kr
makepkg -si

# 검증
wps-office-kr-setup --check
et  # 스프레드시트 yyyy-MM-dd, 한글 메뉴 확인

# 수동 패치 (CN + wps_한글_패치 조합 시 이미 불필요, 참고)
# bash wps_한글_패치/2_install_langpack_linux.sh # /usr/lib/office6/mui/ko_KR 로 복사
```

---

## 구조

```
PKGBUILD  # CN base + 한글 패치 (3서브패키지)
patches/ko_KR/config/ # datetimeformat/controldatetimeformat/idstr
wps_한글_패치/ # 휴먼번역 167파일 (klangkokr 3.1.0.399)
scripts/ # build_translations.sh, extract_klangkokr.sh, wps-office-kr-setup.sh, get_wps_windows.sh
99-wps-office-font-rendering.conf
wps-office-mime.xml / wps-office-disable-mime-detection.sh
translation_dict.json  # 176개, win 25개 100% 커버
.github/workflows/ # wps-kr-build.yml, klangkokr-update.yml
apply_wps_kokr_langpack.sh / install_wps_wine.sh / install_wine_and_extract_kokr.sh # 로컬 Wine 추출/병합
```

---

## 참고

- WPS Linux 공식: https://linux.wps.cn / https://www.wps.com/office/linux/
- AUR wps-office-cn: https://aur.archlinux.org/packages/wps-office-cn
- Windows 한글 팩: https://apps.microsoft.com/detail/9nsgm705mqwc / https://filehippo.com/download_wps-office-free/ (offline 12.2.0.23196) / APKPure 12.2.0.23131 - 모두 베이스에 ko_KR 없음, klangkokr 별도
- OnlyOffice 폰트 대체: https://github.com/ONLYOFFICE/core/pull/1646
```

