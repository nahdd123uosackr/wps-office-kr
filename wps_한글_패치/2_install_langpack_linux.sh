#!/usr/bin/env bash
# 2. 언어팩 Linux 설치 스크립트
# 스테이징 폴더의 Windows 원본 한국어 언어팩을 Linux WPS 의 mui/ko_KR 에 설치한다.
#  - 설치 전 기존 ko_KR 백업
#  - lang.conf 의 러시아어 오매핑을 한국어로 자동 교정
#  - 언어팩 위치 확인 프롬프트 포함
# 시스템 폴더(/usr/lib/office6) 에 쓰기 위해 sudo 필요.
set -euo pipefail

# ---- 기본 경로 ----
DEFAULT_SRC="/disk1/linux/wps/ko_KR"
DEFAULT_DST="/usr/lib/office6/mui/ko_KR"

# 올바른 한국어 lang.conf 내용 (ko_KR/lang.conf 교정용)
write_lang_conf() {
    local f="$1"
    cat > "$f" <<'EOF'
[Language]
DisplayName=한국어 (대한민국)
DisplayName[en_US]=Korean (South Korea)
Icon=ko_KR.png
Community=true
EOF
}

print_line() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }

echo "=== 언어팩 Linux 설치 ==="
echo
echo "설치할 언어팩(스테이징) 위치를 입력하세요."
echo "  (그대로 Enter = 기본값 사용)"
echo "기본값: $DEFAULT_SRC"
read -r -p "> " SRC
SRC="${SRC:-$DEFAULT_SRC}"

if [[ ! -d "$SRC" ]]; then
    echo "[x] 원본 언어팩 폴더가 없습니다: $SRC"
    echo "    먼저 1_copy_windows_langpack.sh 로 복사해 두세요."
    exit 1
fi

echo "Linux WPS 설치 목표 위치를 입력하세요."
echo "  (그대로 Enter = 기본값 사용)"
echo "기본값: $DEFAULT_DST"
read -r -p "> " DST
DST="${DST:-$DEFAULT_DST}"

if [[ ! -d "$(dirname "$DST")" ]]; then
    echo "[x] 목표 상위 폴더가 없습니다: $(dirname "$DST")"
    echo "    WPS 가 설치되어 있는지 확인하세요."
    exit 1
fi

# ---- WPS 실행 중이면 경고 ----
if pgrep -x -a et >/dev/null 2>&1 || pgrep -x -a wps >/dev/null 2>&1; then
    echo "[!] WPS 가 실행 중입니다. 설치 전 종료하는 것을 권장합니다."
    read -r -p "WPS 를 종료하고 계속할까요? [y/N] " k
    if [[ "$k" =~ ^[Yy]$ ]]; then
        pkill -x et 2>/dev/null || true
        pkill -x wps 2>/dev/null || true
        pkill -x wpp 2>/dev/null || true
        pkill -x ksoLauncher 2>/dev/null || true
        sleep 1
    fi
fi

# ---- 확인 프롬프트 ----
print_line
echo "설치 작업 요약:"
echo "  원본(스테이징) : $SRC  ($(find "$SRC" -type f | wc -l) 파일, $(du -sh "$SRC" | cut -f1))"
echo "  목표(Linux)    : $DST"
echo "  백업           : ${DST}.bak.YYYYMMDD_HHMMSS (기존 ko_KR 보존)"
echo "  사후 처리      : lang.conf 러시아어→한국어 자동 교정"
echo "  권한           : sudo 필요(시스템 폴더 쓰기)"
print_line
read -r -p "이대로 설치할까요? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "취소했습니다."; exit 0; }

# ---- 실행 ----
STAMP=$(date +%Y%m%d_%H%M%S)
BACKUP="${DST}.bak.${STAMP}"

echo "[1/4] 기존 ko_KR 백업 -> $BACKUP"
if [[ -d "$DST" ]]; then
    sudo cp -a "$DST" "$BACKUP"
else
    sudo mkdir -p "$DST"
    sudo cp -a "$DST" "$BACKUP"
fi

echo "[2/4] 기존 ko_KR 비우고 언어팩 설치"
sudo mkdir -p "$DST"
# 숨김파일 포함 안전 삭제 후 복사
sudo find "$DST" -mindepth 1 -delete 2>/dev/null || true
sudo cp -a "$SRC"/. "$DST"/

echo "[3/4] lang.conf 교정(러시아어 → 한국어)"
TMP_CONF=$(mktemp)
write_lang_conf "$TMP_CONF"
sudo cp -a "$TMP_CONF" "$DST/lang.conf"
rm -f "$TMP_CONF"

echo "[4/4] 권한/소유자 정리"
# 시스템 폴더이므로 root 소유로 통일
sudo chown -R root:root "$DST" 2>/dev/null || true
sudo find "$DST" -type d -exec chmod 755 {} + 2>/dev/null || true
sudo find "$DST" -type f -exec chmod 644 {} + 2>/dev/null || true

echo
echo "[완료] 설치됨 -> $DST"
echo "  백업본 : $BACKUP"
echo "  파일 수: $(find "$DST" -type f | wc -l)"
echo "  lang.conf:"
sed 's/^/    /' "$DST/lang.conf" 2>/dev/null || sudo cat "$DST/lang.conf" | sed 's/^/    /'
echo
echo "WPS 를 다시 실행해서 메뉴가 한국어로 바뀌었는지 확인하세요."
echo "복구가 필요하면 3_restore_langpack_linux.sh 를 사용하세요."
