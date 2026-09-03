#!/usr/bin/env bash
# WPS Office Windows 설치파일을 Wine + 가상 디스플레이(Xvfb)로
# 화면 없이 자동 설치하고, 온라인 설치 과정에서 자동 다운로드되는
# 한국어 언어팩(klangkokr)을 추출하는 스크립트.
#
# 전제: 이 설치 프로그램(wps_wid.cid-...exe)은 사일런트 커맨드라인 스위치를
# 지원하지 않는 자체 UI 방식이라, Xvfb(모니터 없는 가상 화면)에서 창을 띄운 뒤
# xdotool로 "동의 체크박스"와 "설치 시작" 버튼을 좌표 클릭으로 자동 처리한다.
# 좌표는 1280x800 해상도, 이 설치 프로그램 버전 기준으로 확인된 값이며,
# 설치 프로그램이 업데이트되면 좌표가 틀어질 수 있다.
set -uo pipefail

INSTALLER="${1:-/home/corp/다운로드/wps_wid.cid-549782062.1783900409.exe}"
WINEPREFIX_DIR="$HOME/.wine-wps-kokr"
DISP=":77"
SCREEN_RES="1280x800x24"
OUT_DIR="$HOME/wps_kokr_extracted"
LOG="/tmp/wps_kokr_install.log"

for bin in wine xvfb-run xdotool Xvfb; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "필요한 도구가 없습니다: $bin"
    echo "설치: sudo pacman -S wine xorg-server-xvfb xdotool"
    exit 1
  }
done

if [ ! -f "$INSTALLER" ]; then
  echo "설치 파일을 찾을 수 없습니다: $INSTALLER"
  exit 1
fi

: > "$LOG"
echo "=== WPS Office 무인 설치 + 한국어 언어팩 추출 시작: $(date) ===" | tee -a "$LOG"

echo "[1/6] 가상 디스플레이(Xvfb $DISP) 시작"
pkill -f "Xvfb $DISP" 2>/dev/null || true
sleep 1
Xvfb "$DISP" -screen 0 "$SCREEN_RES" >/tmp/xvfb_wps.log 2>&1 &
XVFB_PID=$!
sleep 2

export DISPLAY="$DISP"
export WINEPREFIX="$WINEPREFIX_DIR"
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8

WINE_PID=""
cleanup() {
  echo "정리 중..." | tee -a "$LOG"
  [ -n "$WINE_PID" ] && kill "$WINE_PID" 2>/dev/null
  pkill -f "wps_wid" 2>/dev/null || true
  kill "$XVFB_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "[2/6] Wine prefix 초기화 (한국어 로케일): $WINEPREFIX_DIR" | tee -a "$LOG"
mkdir -p "$WINEPREFIX_DIR"
wineboot -u >>"$LOG" 2>&1
sleep 3

echo "[3/6] WPS 설치 프로그램 실행" | tee -a "$LOG"
nohup wine "$INSTALLER" >>"$LOG" 2>&1 &
WINE_PID=$!

echo "설치 창 대기 중..." | tee -a "$LOG"
WIN_READY=0
for _ in $(seq 1 30); do
  if xdotool search --name "WPS Office" >/dev/null 2>&1; then
    WIN_READY=1
    break
  fi
  sleep 1
done
if [ "$WIN_READY" -eq 0 ]; then
  echo "설치 창을 찾지 못했습니다. 로그 확인: $LOG"
  exit 1
fi
sleep 3

echo "[4/6] 라이선스 동의 체크 + 설치 시작 클릭 (자동, 화면 없이 진행)" | tee -a "$LOG"
xdotool mousemove 308 621 click 1
sleep 2
xdotool mousemove 700 480 click 1
sleep 3

echo "[5/6] 다운로드 및 설치 완료 대기 (최대 15분)" | tee -a "$LOG"
DEST_EXE_PATTERN="$WINEPREFIX_DIR/drive_c/users/*/AppData/Local/Kingsoft/WPS Office/*/office6/wps.exe"
WAITED=0
MAX_WAIT=900
INSTALL_OK=0
while [ "$WAITED" -lt "$MAX_WAIT" ]; do
  # shellcheck disable=SC2086
  if compgen -G "$DEST_EXE_PATTERN" > /dev/null 2>&1; then
    echo "WPS 설치 완료 감지됨 (${WAITED}s 경과)" | tee -a "$LOG"
    INSTALL_OK=1
    break
  fi
  sleep 10
  WAITED=$((WAITED + 10))
done

if [ "$INSTALL_OK" -eq 0 ]; then
  echo "설치 완료를 감지하지 못했습니다. 로그를 확인하세요: $LOG"
  exit 1
fi

echo "[6/6] 한국어 언어팩(klangkokr) 자동 다운로드 대기 (최대 5분)" | tee -a "$LOG"
LANG_PATTERN="$WINEPREFIX_DIR/drive_c/users/*/AppData/Roaming/kingsoft/wps_intl/addons/pool/win-x64/klangkokr_*"
WAITED=0
MAX_WAIT=300
FOUND=""
while [ "$WAITED" -lt "$MAX_WAIT" ]; do
  # shellcheck disable=SC2086
  MATCH=$(compgen -G "$LANG_PATTERN" 2>/dev/null | head -1 || true)
  if [ -n "$MATCH" ] && [ -d "$MATCH" ]; then
    SIZE1=$(du -sb "$MATCH" 2>/dev/null | cut -f1)
    sleep 8
    SIZE2=$(du -sb "$MATCH" 2>/dev/null | cut -f1)
    if [ -n "$SIZE1" ] && [ "$SIZE1" = "$SIZE2" ] && [ "$SIZE1" -gt 0 ]; then
      FOUND="$MATCH"
      break
    fi
  fi
  sleep 7
  WAITED=$((WAITED + 15))
done

if [ -z "$FOUND" ]; then
  echo "klangkokr 언어팩을 자동으로 찾지 못했습니다." | tee -a "$LOG"
  echo "WPS가 실행 중이라면 [설정 > 언어]에서 한국어를 선택해 다운로드를 유도한 뒤 이 스크립트를 다시 실행하세요."
  exit 1
fi

echo "언어팩 발견: $FOUND" | tee -a "$LOG"
mkdir -p "$OUT_DIR"
rm -rf "${OUT_DIR:?}"/klangkokr_* 2>/dev/null || true
cp -a "$FOUND" "$OUT_DIR/"

echo | tee -a "$LOG"
echo "=== 전체 완료: $(date) ===" | tee -a "$LOG"
echo "추출된 언어팩: $OUT_DIR/$(basename "$FOUND")" | tee -a "$LOG"
echo "다음 단계: apply_wps_kokr_langpack.sh 를 실행해 Linux WPS Office에 병합하세요." | tee -a "$LOG"
