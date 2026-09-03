#!/bin/bash
# get_wps_windows.sh - WPS Office Windows 버전을 https://www.wps.com/download/ 에서 동적으로 받아옴
# 1순위: wps.com/download 페이지의 직접 다운로드 링크 (online installer 5M, fallback)
# 2순위: APKPure offline (254M, full) - https://windows.apkpure.com/wps-office/download
# 3순위: 기존 로컬 캐시

set -euo pipefail

OUT="${1:-/tmp/wps_win.exe}"
WPS_URL="https://www.wps.com/download/"

echo "=== WPS Windows 동적 다운로드 (wps.com) ==="
echo "출력: $OUT"
echo "소스: $WPS_URL"

# 1) wps.com 직접 시도 - 사용자가 지정한 600.1002 온라인 인스톨러 우선
echo "[1/3] wps.com 시도..."
WPS_DL="https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/onlinesetup/distsrc/600.1002/wpsinst/wps_office_inst.exe"
# Try to scrape wps.com for newer wdl1 link (if 600.1002 is outdated)
if command -v curl >/dev/null 2>&1; then
  PAGE=$(curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" "$WPS_URL" 2>&1 | head -c 500000 || true)
  SCRAPED=$(echo "$PAGE" | grep -o 'https://[^"]*wdl1[^"]*\.exe[^"]*' | head -1 || true)
  if [[ -n "$SCRAPED" && "$SCRAPED" != "$WPS_DL" ]]; then
    echo "  wps.com에서 신규 발견: $SCRAPED (600.1002 대신 사용)"
    WPS_DL="$SCRAPED"
  else
    echo "  사용: $WPS_DL (600.1002 지정, wps.com online installer 5M)"
    echo "  참고: online installer는 qm 미포함, offline은 APKPure로 fallback"
  fi
fi

# 2) APKPure offline fallback (full 254M, qm 포함) - 동적 버전 감지
echo "[2/3] APKPure offline 시도..."
APK_URL=""
APK_PAGE=$(curl -sL -A "Mozilla/5.0" "https://windows.apkpure.com/wps-office/download" 2>&1 | head -c 300000 || true)
# APKPure page has direct exe link like https://d.cdnpure.com/b/exe/...
APK_URL=$(echo "$APK_PAGE" | grep -o 'https://d\.cdnpure\.com[^"]*\.exe[^"]*' | head -1 || true)
if [[ -z "$APK_URL" ]]; then
  # Fallback to known 12.2.0.23131
  APK_URL="https://d.cdnpure.com/b/exe/V1BTIE9mZmljZV91cHRvZG93bl8yOTA3N18xMi4yLjAuMjMxMzFfNWQxMzIxOGM?_fn=V1BTIE9mZmljZV8xMi4yLjAuMjMxMzEuZXhl"
  echo "  APKPure 파싱 실패, fallback: $APK_URL"
else
  echo "  발견: $APK_URL"
fi

# 3) 다운로드
if [[ -n "$APK_URL" ]]; then
  echo "[3/3] 다운로드 $APK_URL -> $OUT"
  mkdir -p "$(dirname "$OUT")"
  if curl -L -o "$OUT" "$APK_URL" 2>&1 | tail -n 20; then
    SIZE=$(du -sh "$OUT" 2>/dev/null | cut -f1)
    echo "[완료] $OUT ($SIZE)"
    file "$OUT" 2>&1 | head
    # Verify it's PE with NSIS and contains office files
    if 7z l "$OUT" 2>&1 | grep -q "CONTROL"; then
      echo "  검증: CONTROL 포함, 정상 WPS installer"
    else
      echo "  경고: CONTROL 없음, 다른 파일일 수 있음"
    fi
    exit 0
  fi
fi

# Fallback to wps.com online installer if APKPure fails
if [[ -n "$WPS_DL" ]]; then
  echo "[fallback] wps.com online installer 다운로드"
  mkdir -p "$(dirname "$OUT")"
  curl -L -o "$OUT" "$WPS_DL" 2>&1 | tail -n 20
  ls -lh "$OUT" 2>&1 | head
  exit 0
fi

echo "[x] 모든 소스 실패"
exit 1
