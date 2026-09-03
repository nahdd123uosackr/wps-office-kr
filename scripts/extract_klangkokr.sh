#!/bin/bash
# extract_klangkokr.sh - Windows Store WPS Office에서 klangkokr 한글 팩 추출
# Usage: ./extract_klangkokr.sh [output_dir]
# - Wine에 설치된 WPS 또는 APKPure exe에서 ko_KR 추출
# - wps_한글_패치/ko_KR 로 저장 (빌드 시 1순위 소스)

set -euo pipefail

OUT_DIR="${1:-$(dirname "$0")/../wps_한글_패치/ko_KR}"
WINE_PREFIX="${WINEPREFIX:-$HOME/.wine}"
POOL_ROOT="$WINE_PREFIX/drive_c/users/$USER/AppData/Roaming/kingsoft/wps_intl/addons/pool/win-x64"

echo "=== klangkokr 추출 ==="
echo "출력: $OUT_DIR"
echo "Wine prefix: $WINE_PREFIX"
echo "Pool: $POOL_ROOT"

# 1) Wine 풀에서 자동 탐색 (가장 확실)
SRC=""
if [[ -d "$POOL_ROOT" ]]; then
  AUTO=$(find "$POOL_ROOT" -maxdepth 1 -type d -name 'klangkokr_*' 2>/dev/null | sort -V | tail -1)
  if [[ -n "${AUTO:-}" && -d "$AUTO/ko_KR" ]]; then
    SRC="$AUTO/ko_KR"
    echo "[+] Wine 풀에서 발견: $SRC ($(find "$SRC" -type f | wc -l) 파일)"
  fi
fi

# 2) 이미 있는 wps_한글_패치 확인
if [[ -z "$SRC" && -d "$(dirname "$0")/../wps_한글_패치/ko_KR" ]]; then
  echo "[*] 기존 wps_한글_패치/ko_KR 사용 (휴먼번역 167파일)"
  SRC="$(dirname "$0")/../wps_한글_패치/ko_KR"
fi

# 3) APKPure exe에서 추출 (CI용, 254M 다운로드)
if [[ -z "$SRC" ]]; then
  echo "[*] Wine 풀 없음, APKPure exe 다운로드 시도..."
  TMP_EXE="/tmp/wps_ms_store.exe"
  if [[ ! -f "$TMP_EXE" ]]; then
    echo "  다운로드 중... (254M)"
    curl -L -o "$TMP_EXE" "https://d.cdnpure.com/b/exe/V1BTIE9mZmljZV91cHRvZG93bl8yOTA3N18xMi4yLjAuMjMxMzFfNWQxMzIxOGM?_fn=V1BTIE9mZmljZV8xMi4yLjAuMjMxMzEuZXhl" 2>&1 | tail -n 5 || {
      echo "[!] 다운로드 실패, 수동 설치 필요"
      exit 1
    }
  fi
  echo "  7z 추출 및 Wine silent install..."
  rm -rf /tmp/wps_win_extract2 /tmp/wps_inner /tmp/wine_wps
  mkdir -p /tmp/wps_win_extract2
  7z x "$TMP_EXE" -o/tmp/wps_win_extract2 -y 2>&1 | tail -n 5
  mkdir -p /tmp/wps_inner
  # $EXEFILE is inside $_11_/
  INNER=$(find /tmp/wps_win_extract2 -name '$EXEFILE' 2>/dev/null | head -1)
  if [[ -z "$INNER" ]]; then
    INNER=$(find /tmp/wps_win_extract2 -name "*.exe" -size +100M 2>/dev/null | head -1)
  fi
  if [[ -n "$INNER" ]]; then
    7z x "$INNER" -o/tmp/wps_inner -y 2>&1 | tail -n 5
    export WINEPREFIX=/tmp/wine_wps
    mkdir -p $WINEPREFIX
    timeout 60 bash -c "WINEPREFIX=/tmp/wine_wps wine \"$INNER\" /S /D=C:\\wps_test" 2>&1 | tail -n 10 || true
    # Find extracted office
    SRC=$(find /tmp/wine_wps -type d -name "ko_KR" 2>/dev/null | head -1)
    if [[ -z "$SRC" ]]; then
      # Fallback: check wps_test
      SRC=$(find /tmp/wine_wps -path "*office6/mui/ko_KR" -type d 2>/dev/null | head -1)
    fi
    if [[ -n "$SRC" ]]; then
      echo "[+] Wine 설치 후 발견: $SRC"
    else
      echo "[!] ko_KR 추출 실패 (베이스에 없음, klangkokr 별도 팩 필요)"
      echo "    WPS 실행 후 언어→한국어 선택 시 pool에 klangkokr 생성됨"
      exit 1
    fi
  fi
fi

if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  echo "[x] ko_KR 소스를 찾을 수 없습니다."
  exit 1
fi

mkdir -p "$OUT_DIR"
echo "[*] 복사 $SRC -> $OUT_DIR"
cp -a "$SRC"/. "$OUT_DIR"/
echo "[완료] $(find "$OUT_DIR" -type f | wc -l) 파일, $(du -sh "$OUT_DIR" | cut -f1)"
ls -lh "$OUT_DIR"/*.qm 2>&1 | head -n 10
echo "lang.conf:"
cat "$OUT_DIR/lang.conf" 2>&1 | head -n 10
