#!/usr/bin/env bash
# 1. Windows 언어팩 복사 스크립트
# Windows(wine)에 설치된 WPS 한국어 언어팩(klangkokr)을 스테이징 폴더로 복사한다.
# 복사 전 사용자에게 원본/목표 위치를 확인 프롬프트로 보여준다.
set -euo pipefail

# ---- 기본 경로 (환경에 맞게 수정 가능) ----
DEFAULT_SRC="/home/corp/.wine/drive_c/users/corp/AppData/Roaming/kingsoft/wps_intl/addons/pool/win-x64/klangkokr_3.1.0.399/ko_KR"
DEFAULT_DST="/disk1/linux/wps/ko_KR"

print_line() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }

echo "=== Windows 언어팩 복사 ==="
echo
echo "원본(Windows/wine klangkokr 언어팩) 위치를 입력하세요."
echo "  (그대로 Enter = 기본값 사용)"
echo "기본값: $DEFAULT_SRC"
read -r -p "> " SRC
SRC="${SRC:-$DEFAULT_SRC}"

# klangkokr 풀을 자동 탐색(버전 디렉토리가 다를 수 있음)
if [[ ! -d "$SRC" ]]; then
    echo "[!] 입력 경로가 없습니다. wine 풀에서 자동 탐색을 시도합니다..."
    POOL_ROOT="/home/corp/.wine/drive_c/users/corp/AppData/Roaming/kingsoft/wps_intl/addons/pool/win-x64"
    AUTO=$(find "$POOL_ROOT" -maxdepth 1 -type d -name 'klangkokr_*' 2>/dev/null | sort -V | tail -1)
    if [[ -n "${AUTO:-}" && -d "$AUTO/ko_KR" ]]; then
        SRC="$AUTO/ko_KR"
        echo "[+] 탐색 성공: $SRC"
    else
        echo "[x] 원본 ko_KR 폴더를 찾을 수 없습니다. 경로를 확인하세요."
        exit 1
    fi
fi

echo "목표(복사받을 스테이징) 위치를 입력하세요."
echo "  (그대로 Enter = 기본값 사용)"
echo "기본값: $DEFAULT_DST"
read -r -p "> " DST
DST="${DST:-$DEFAULT_DST}"

# ---- 확인 프롬프트 ----
print_line
echo "복사 작업 요약:"
echo "  원본 : $SRC"
echo "  목표 : $DST"
echo "  내용 : $(find "$SRC" -type f | wc -l) 개 파일, $(du -sh "$SRC" | cut -f1)"
print_line
read -r -p "이대로 복사할까요? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "취소했습니다."; exit 0; }

# ---- 실행 ----
mkdir -p "$DST"
# 기존 스테이징 내용이 있으면 백업 후 교체
if [[ -n "$(ls -A "$DST" 2>/dev/null)" ]]; then
    BAK="${DST}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "[+] 기존 스테이징 백업: $BAK"
    mv "$DST" "$BAK"
    mkdir -p "$DST"
fi

cp -a "$SRC"/. "$DST"/
echo
echo "[완료] 복사됨 -> $DST"
echo "  파일 수: $(find "$DST" -type f | wc -l)"
echo
echo "다음: 2_install_langpack_linux.sh 로 Linux 에 설치하세요."
