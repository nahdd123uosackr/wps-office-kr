#!/usr/bin/env bash
# Windows WPS Office 온라인설치 과정에서 받은 한국어 언어팩(klangkokr)을
# Linux 네이티브 WPS Office 설치 구조에 병합 적용하는 스크립트.
set -uo pipefail

SRC="$HOME/.wine-wps-kokr/drive_c/users/corp/AppData/Roaming/kingsoft/wps_intl/addons/pool/win-x64/klangkokr_3.1.0.1703"
DST="/usr/lib/office6"
BACKUP_DIR="$HOME/wps_kokr_backup_$(date +%Y%m%d_%H%M%S)"
SKIPPED_LOG="$BACKUP_DIR/skipped_modules.txt"
APPLIED_LOG="$BACKUP_DIR/applied_modules.txt"

if [ ! -d "$SRC" ]; then
  echo "소스 언어팩을 찾을 수 없습니다: $SRC"
  echo "먼저 Wine에서 WPS Office를 설치해 klangkokr 애드온이 다운로드되어야 합니다."
  exit 1
fi

if [ ! -d "$DST" ]; then
  echo "Linux WPS Office 설치 경로를 찾을 수 없습니다: $DST"
  exit 1
fi

mkdir -p "$BACKUP_DIR"
: > "$SKIPPED_LOG"
: > "$APPLIED_LOG"

echo "=== WPS 한국어 언어팩 병합 시작 ==="
echo "소스: $SRC"
echo "대상: $DST"
echo "백업: $BACKUP_DIR"
echo

# sudo 자격을 먼저 한 번 받아둔다 (이후 호출은 캐시된 자격으로 진행됨).
# 터미널에서 직접 실행해야 여기서 비밀번호를 입력할 수 있다.
if ! sudo -v; then
  echo "sudo 인증 실패. 터미널에서 이 스크립트를 직접 실행해 비밀번호를 입력해 주세요."
  exit 1
fi
# 스크립트 실행 동안 sudo 타임스탬프를 주기적으로 갱신 (백그라운드)
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

# 1. 코어 언어팩 (mui/ko_KR) 병합
if [ -d "$SRC/ko_KR" ]; then
  echo "--- 코어 mui/ko_KR 병합 ---"
  if [ -d "$DST/mui/ko_KR" ]; then
    sudo cp -a "$DST/mui/ko_KR" "$BACKUP_DIR/core_mui_ko_KR.bak" || echo "경고: core 백업 실패"
  fi
  if sudo mkdir -p "$DST/mui/ko_KR" && sudo cp -a "$SRC/ko_KR/." "$DST/mui/ko_KR/"; then
    echo "core" >> "$APPLIED_LOG"
    echo "적용됨: core"
  else
    echo "core" >> "$SKIPPED_LOG"
    echo "실패: core"
  fi
fi

# 2. addon별 mui/ko_KR 및 wps-i18n/ko-kr 리소스 병합
echo
echo "--- addon별 언어 리소스 병합 ---"
for moddir in "$SRC/addons"/*/; do
  name=$(basename "$moddir")
  target="$DST/addons/$name"

  if [ ! -d "$target" ]; then
    echo "$name" >> "$SKIPPED_LOG"
    continue
  fi

  applied_this=0
  failed_this=0

  # 2a. mui/ko_KR (.qm 번역 파일 등)
  if [ -d "$moddir/mui/ko_KR" ]; then
    if [ -d "$target/mui/ko_KR" ]; then
      sudo mkdir -p "$BACKUP_DIR/addons/$name" || failed_this=1
      sudo cp -a "$target/mui/ko_KR" "$BACKUP_DIR/addons/$name/mui_ko_KR.bak" || failed_this=1
    fi
    if sudo mkdir -p "$target/mui" && sudo cp -a "$moddir/mui/ko_KR" "$target/mui/"; then
      applied_this=1
    else
      failed_this=1
    fi
  fi

  # 2b. wps-i18n/ko-kr (내장 웹뷰 UI용 JS 리소스, 여러 하위 경로에 존재 가능)
  while IFS= read -r wdir; do
    rel="${wdir#"$moddir"}"
    destdir="$target/$(dirname "$rel")"
    if sudo mkdir -p "$destdir" && sudo cp -a "$wdir" "$destdir/"; then
      applied_this=1
    else
      failed_this=1
    fi
  done < <(find "$moddir" -type d -path "*/wps-i18n/ko-kr" 2>/dev/null)

  if [ "$applied_this" -eq 1 ] && [ "$failed_this" -eq 0 ]; then
    echo "$name" >> "$APPLIED_LOG"
    echo "적용됨: $name"
  elif [ "$failed_this" -eq 1 ]; then
    echo "$name (일부 실패)" >> "$SKIPPED_LOG"
    echo "실패: $name"
  fi
done

echo
echo "=== 완료 ==="
echo "적용된 모듈 수: $(wc -l < "$APPLIED_LOG")"
echo "건너뛴 모듈 수 (Linux에 해당 addon 없음): $(wc -l < "$SKIPPED_LOG")"
echo "백업 위치: $BACKUP_DIR"
echo
echo "적용을 확인하려면 WPS Office를 재시작한 뒤 메뉴가 한국어로 표시되는지 확인하세요."
echo "문제가 생기면 복원: sudo cp -a $BACKUP_DIR/core_mui_ko_KR.bak/. $DST/mui/ko_KR/  (addon별 백업은 $BACKUP_DIR/addons/<모듈명>/ 참고)"
