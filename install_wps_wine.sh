#!/usr/bin/env bash
# WPS Office Windows 설치파일을 Wine에서 무인(GUI 자동 클릭)으로 설치하는 스크립트
set -uo pipefail

INSTALLER="/home/corp/다운로드/wps_wid.cid-549782062.1783900409.exe"
LOGFILE="/tmp/wps_wine_install.log"
SCREEN_RES="1024x768x24"

echo "=== WPS Office Wine 무인 설치 시작: $(date) ===" | tee "$LOGFILE"

# 0. 필수 패키지 확인
missing=()
command -v wine      >/dev/null 2>&1 || missing+=("wine")
command -v xvfb-run  >/dev/null 2>&1 || missing+=("xvfb")
command -v xdotool   >/dev/null 2>&1 || missing+=("xdotool")
if [ ${#missing[@]} -gt 0 ]; then
  echo "다음 패키지가 필요합니다: ${missing[*]}"
  echo "설치: sudo apt install ${missing[*]}"
  exit 1
fi

if [ ! -f "$INSTALLER" ]; then
  echo "설치 파일을 찾을 수 없습니다: $INSTALLER"
  exit 1
fi

# 1. 사일런트 설치 스위치 우선 시도 (NSIS/InnoSetup 계열에서 흔히 쓰이는 옵션들)
SILENT_FLAG_SETS=(
  "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-"
  "/S"
  "/silent"
  "/qn"
)

for flags in "${SILENT_FLAG_SETS[@]}"; do
  echo "--- 사일런트 옵션 시도: wine \"$INSTALLER\" $flags ---" | tee -a "$LOGFILE"
  # shellcheck disable=SC2086
  if timeout 90 wine "$INSTALLER" $flags >>"$LOGFILE" 2>&1; then
    sleep 5
    if find "$HOME/.wine/drive_c" -maxdepth 4 -iname "*wps*" 2>/dev/null | grep -qi wps; then
      echo "사일런트 설치 성공으로 확인됩니다 (설치 경로 발견)." | tee -a "$LOGFILE"
      exit 0
    fi
  fi
  # 남아있을 수 있는 설치 프로세스 정리 후 다음 옵션 시도
  pkill -f "wps_wid" >/dev/null 2>&1 || true
  sleep 2
done

echo "사일런트 옵션이 통하지 않았습니다. Xvfb(가상 디스플레이) + xdotool로 설치 마법사를 자동 클릭합니다." | tee -a "$LOGFILE"

# 2. GUI 자동화: 실제 모니터 없이 가상 디스플레이에서 설치 마법사를 띄우고
#    Tab(체크박스 이동) -> Space(동의 체크) -> Return(다음/설치/완료 클릭)을 계속 반복 전송
xvfb-run --server-args="-screen 0 ${SCREEN_RES}" --auto-servernum bash -c "
  INSTALLER='${INSTALLER}'
  LOGFILE='${LOGFILE}'

  wine \"\$INSTALLER\" >>\"\$LOGFILE\" 2>&1 &
  WINE_PID=\$!
  echo \"Wine 설치 프로세스 시작 (PID: \$WINE_PID)\" >> \"\$LOGFILE\"

  ELAPSED=0
  MAX_WAIT=600   # 최대 10분

  while kill -0 \"\$WINE_PID\" 2>/dev/null && [ \"\$ELAPSED\" -lt \"\$MAX_WAIT\" ]; do
    sleep 2
    ELAPSED=\$((ELAPSED + 2))
    for win in \$(xdotool search --onlyvisible '' 2>/dev/null); do
      xdotool windowactivate --sync \"\$win\" 2>/dev/null || true
      # 체크박스(라이선스 동의 등) 토글 -> 다음/확인/설치/완료 버튼(기본 포커스) 실행
      xdotool key --window \"\$win\" space  2>/dev/null || true
      xdotool key --window \"\$win\" Return 2>/dev/null || true
      xdotool key --window \"\$win\" alt+n  2>/dev/null || true   # Next 단축키(있는 경우)
      xdotool key --window \"\$win\" alt+i  2>/dev/null || true   # Install 단축키(있는 경우)
      xdotool key --window \"\$win\" alt+f  2>/dev/null || true   # Finish 단축키(있는 경우)
    done
  done

  if kill -0 \"\$WINE_PID\" 2>/dev/null; then
    echo '시간 초과: Wine 프로세스를 강제 종료합니다.' >> \"\$LOGFILE\"
    kill \"\$WINE_PID\" 2>/dev/null || true
  else
    echo 'Wine 설치 프로세스가 정상 종료되었습니다.' >> \"\$LOGFILE\"
  fi
"

echo "=== 설치 스크립트 종료: $(date) ===" | tee -a "$LOGFILE"

# 3. 설치 결과 확인
if find "$HOME/.wine/drive_c" -maxdepth 4 -iname "*wps*" 2>/dev/null | grep -qi wps; then
  echo "설치 확인: WPS 관련 경로가 Wine prefix에 존재합니다."
else
  echo "설치 확인 실패: Wine prefix에서 WPS 경로를 찾지 못했습니다. 로그를 확인하세요: $LOGFILE"
fi

echo "--- 최근 로그 ---"
tail -40 "$LOGFILE"
