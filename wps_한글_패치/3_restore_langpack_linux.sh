#!/usr/bin/env bash
# 3. 언어팩 Linux 복구 스크립트
# 설치 전 백업해 둔 ko_KR.bak.* 중 하나를 골라 Linux WPS 의 mui/ko_KR 로 복구한다.
#  - 백업 목록 자동 탐색 + 선택 프롬프트
#  - 복구 전 현재 ko_KR 도 안전망 백업
# 시스템 폴더(/usr/lib/office6) 에 쓰기 위해 sudo 필요.
set -euo pipefail

# ---- 기본 경로 ----
DEFAULT_DST="/usr/lib/office6/mui/ko_KR"

print_line() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }

echo "=== 언어팩 Linux 복구 ==="
echo

echo "복구할 Linux WPS 의 ko_KR 위치를 입력하세요."
echo "  (그대로 Enter = 기본값 사용)"
echo "기본값: $DEFAULT_DST"
read -r -p "> " DST
DST="${DST:-$DEFAULT_DST}"

PARENT="$(dirname "$DST")"
if [[ ! -d "$PARENT" ]]; then
    echo "[x] 상위 폴더가 없습니다: $PARENT"
    exit 1
fi

# ---- 백업 목록 탐색 ----
# 현재 ko_KR 디렉토리 자체는 제외하고 .bak.* 만 수집
mapfile -t BACKUPS < <(find "$PARENT" -maxdepth 1 -type d -name 'ko_KR.bak.*' 2>/dev/null | sort -r)

if [[ ${#BACKUPS[@]} -eq 0 ]]; then
    echo "[x] 백업을 찾을 수 없습니다: ${PARENT}/ko_KR.bak.*"
    echo "    2_install_langpack_linux.sh 로 설치한 적이 있는지 확인하세요."
    exit 1
fi

echo "사용 가능한 백업:"
echo "  [0] 취소"
for i in "${!BACKUPS[@]}"; do
    b="${BACKUPS[$i]}"
    cnt=$(find "$b" -type f 2>/dev/null | wc -l)
    sz=$(du -sh "$b" 2>/dev/null | cut -f1)
    # 타임스탬프만 표시
    ts="${b##*.bak.}"
    printf '  [%d] %s  (파일 %s개, %s)\n' "$((i+1))" "$b" "$cnt" "$sz"
done
echo
read -r -p "복구할 백업 번호를 선택하세요 [0..${#BACKUPS[@]}] (0=취소): " sel

case "$sel" in
    0) echo "취소했습니다."; exit 0 ;;
    ''|*[!0-9]*) echo "[x] 잘못된 입력입니다."; exit 1 ;;
esac

if (( sel < 1 || sel > ${#BACKUPS[@]} )); then
    echo "[x] 범위 밖 번호입니다."
    exit 1
fi

RESTORE="${BACKUPS[$((sel-1))]}"

# ---- 확인 프롬프트 ----
print_line
echo "복구 작업 요약:"
echo "  복구원본(백업) : $RESTORE  ($(find "$RESTORE" -type f | wc -l) 파일)"
echo "  복구목표       : $DST"
echo "  안전망         : 현재 ko_KR 을 ko_KR.pre_restore.<시간> 으로 추가 백업"
echo "  권한           : sudo 필요(시스템 폴더 쓰기)"
print_line
read -r -p "이대로 복구할까요? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "취소했습니다."; exit 0; }

# ---- WPS 실행 중 경고 ----
if pgrep -x -a et >/dev/null 2>&1 || pgrep -x -a wps >/dev/null 2>&1; then
    echo "[!] WPS 가 실행 중입니다. 복구 전 종료를 권장합니다."
    read -r -p "WPS 를 종료하고 계속할까요? [y/N] " k
    if [[ "$k" =~ ^[Yy]$ ]]; then
        pkill -x et 2>/dev/null || true
        pkill -x wps 2>/dev/null || true
        pkill -x wpp 2>/dev/null || true
        pkill -x ksoLauncher 2>/dev/null || true
        sleep 1
    fi
fi

# ---- 실행 ----
STAMP=$(date +%Y%m%d_%H%M%S)
SAFETY="${DST}.pre_restore.${STAMP}"

echo "[1/3] 현재 ko_KR 안전망 백업 -> $SAFETY"
sudo cp -a "$DST" "$SAFETY"

echo "[2/3] 백업으로 복구"
sudo mkdir -p "$DST"
sudo find "$DST" -mindepth 1 -delete 2>/dev/null || true
sudo cp -a "$RESTORE"/. "$DST"/

echo "[3/3] 권한/소유자 정리"
sudo chown -R root:root "$DST" 2>/dev/null || true
sudo find "$DST" -type d -exec chmod 755 {} + 2>/dev/null || true
sudo find "$DST" -type f -exec chmod 644 {} + 2>/dev/null || true

echo
echo "[완료] 복구됨 -> $DST"
echo "  복구원본    : $RESTORE"
echo "  안전망백업  : $SAFETY  (필요 없으면 삭제 가능)"
echo "  파일 수     : $(find "$DST" -type f | wc -l)"
echo
echo "WPS 를 다시 실행하세요."
