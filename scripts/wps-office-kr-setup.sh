#!/bin/bash
# wps-office-kr-setup.sh - WPS Office KR post-install Korean setup (idempotent)
# 시스템 + 사용자 한글 설정 후속 프로세스
# Usage: wps-office-kr-setup [--system] [--user] [--check] [--verbose]
# - --system: 시스템 레벨만 (root 필요)
# - --user: 사용자 레벨만
# - --check: 검증만 (변경 없음)
# - --verbose: 상세 출력
# 기본값: 둘 다 수행 (권한에 따라 자동 스킵)

set -euo pipefail

VERBOSE=0
DO_SYSTEM=1
DO_USER=1
CHECK_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --system) DO_USER=0 ;;
    --user) DO_SYSTEM=0 ;;
    --check) CHECK_ONLY=1 ;;
    --verbose) VERBOSE=1 ;;
    --help|-h)
      echo "Usage: $0 [--system] [--user] [--check] [--verbose]"
      exit 0
      ;;
  esac
done

log() { [[ $VERBOSE -eq 1 ]] && echo "[wps-kr-setup] $*" || echo "$*"; }
ok() { echo "  ✓ $*"; }
warn() { echo "  ! $*"; }
fail() { echo "  ✗ $*"; }

# === 시스템 레벨 ===
do_system() {
  [[ $CHECK_ONLY -eq 1 ]] && log "=== [CHECK] 시스템 레벨 ===" || log "=== 시스템 레벨 한글 설정 ==="
  local changed=0

  # 1) ko_KR.UTF-8 로케일 확인/생성
  if locale -a 2>/dev/null | grep -qi "ko_KR.utf8"; then
    ok "로케일 ko_KR.UTF-8 존재"
  else
    if [[ $CHECK_ONLY -eq 1 ]]; then fail "로케일 ko_KR.UTF-8 없음 (생성 필요)"; else
      warn "ko_KR.UTF-8 없음 -> 생성 시도"
      if grep -q "^#ko_KR.UTF-8" /etc/locale.gen 2>/dev/null; then
        sed -i 's/^#ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen
        locale-gen 2>&1 | tail -n 3 || true
        ok "ko_KR.UTF-8 생성 완료"
      elif grep -q "^ko_KR.UTF-8" /etc/locale.gen 2>/dev/null; then
        locale-gen 2>&1 | tail -n 3 || true
        ok "locale-gen 재실행"
      else
        echo "ko_KR.UTF-8 UTF-8" >> /etc/locale.gen
        locale-gen 2>&1 | tail -n 3 || true
        ok "ko_KR.UTF-8 추가 및 생성"
      fi
      changed=1
    fi
  fi

  # 2) /etc/locale.conf 확인
  if [[ -f /etc/locale.conf ]] && grep -q "ko_KR" /etc/locale.conf; then
    ok "/etc/locale.conf에 ko_KR 설정됨"
  else
    if [[ $CHECK_ONLY -eq 1 ]]; then warn "/etc/locale.conf에 ko_KR 미설정 (권장)"; else
      if [[ -f /etc/locale.conf && -s /etc/locale.conf ]]; then
        warn "/etc/locale.conf 유지 (수동 확인 권장: LANG=ko_KR.UTF-8)"
      else
        echo "LANG=ko_KR.UTF-8" > /etc/locale.conf
        ok "/etc/locale.conf 생성: LANG=ko_KR.UTF-8"
        changed=1
      fi
    fi
  fi

  # 3) mui/ko_KR 검증
  local mui="/opt/kingsoft/wps-office/office6/mui/ko_KR"
  for f in config/datetimeformat.cfg config/controldatetimeformat.cfg config/idstr.cfg lang.conf; do
    if [[ -f "$mui/$f" ]]; then ok "mui/ko_KR/$f 존재"; else fail "mui/ko_KR/$f 없음 (패키지 재설치 필요)"; fi
  done
  if grep -q 'yyyy-MM-dd' "$mui/config/datetimeformat.cfg" 2>/dev/null; then
    ok "날짜 서식 yyyy-MM-dd 확인"
  else
    fail "날짜 서식 불일치"
  fi
  # .qm 파일 개수
  local qm_cnt
  qm_cnt=$(ls -1 "$mui"/*.qm 2>/dev/null | wc -l)
  if [[ "$qm_cnt" -ge 3 ]]; then ok "번역 .qm $qm_cnt개 존재 (kso/wps/wpp/et 등)"; else warn ".qm $qm_cnt개 - 일부 번역 누락 가능"; fi

  # 4) setup.cfg
  local setup="/opt/kingsoft/wps-office/office6/cfgs/setup.cfg"
  if [[ -f "$setup" ]]; then
    if grep -q "^UILanguage=ko_KR" "$setup"; then ok "setup.cfg UILanguage=ko_KR"; else
      if [[ $CHECK_ONLY -eq 1 ]]; then fail "setup.cfg UILanguage != ko_KR"; else
        if grep -q "^UILanguage=" "$setup"; then sed -i 's/^UILanguage=.*/UILanguage=ko_KR/' "$setup"; else echo "UILanguage=ko_KR" >> "$setup"; fi
        ok "setup.cfg 수정 -> ko_KR"
        changed=1
      fi
    fi
  else
    warn "setup.cfg 없음"
  fi

  # 5) Office.conf 시스템 기본값
  for conf in "/opt/kingsoft/wps-office/office6/cfgs/default/Office.conf" "/etc/xdg/Kingsoft/Office.conf"; do
    if [[ -f "$conf" ]] && grep -q "UILanguage=ko_KR" "$conf"; then ok "$conf UILanguage=ko_KR"; 
    elif [[ -f "$conf" ]]; then
      if [[ $CHECK_ONLY -eq 1 ]]; then fail "$conf UILanguage != ko_KR"; else
        mkdir -p "$(dirname "$conf")"
        cat > "$conf" <<'EOF'
[6.0]
UILanguage=ko_KR

[Application Settings]
UILanguage=ko_KR

[kl]
UILanguage=ko_KR

[Versions]

[6.0\Common]
UILanguage=ko_KR

wps\Custom%20Application%20Settings\MeasurementUnit=cm
wpp\Custom%20Application%20Settings\MeasurementUnit=cm
et\Custom%20Application%20Settings\MeasurementUnit=cm
EOF
        ok "$conf 재생성 -> ko_KR"
        changed=1
      fi
    else
      warn "$conf 없음"
    fi
  done

  # 6) 런처 환경변수
  for app in wps wpp et wpspdf; do
    local launcher="/usr/bin/$app"
    if [[ -f "$launcher" ]]; then
      if grep -q "LANG=ko_KR.UTF-8" "$launcher" && grep -q "LC_ALL=ko_KR.UTF-8" "$launcher"; then ok "launcher $app 한글 환경변수 존재"; else
        if [[ $CHECK_ONLY -eq 1 ]]; then fail "launcher $app 한글 환경변수 없음"; else
          warn "launcher $app 패치 누락 (재설치 권장) - 자동 패치 시도"
          # idempotent 패치
          grep -q "LANG=ko_KR.UTF-8" "$launcher" || sed -i '2i export LANG=ko_KR.UTF-8\nexport LC_ALL=ko_KR.UTF-8\nexport LANGUAGE=ko_KR:ko\nexport LC_CTYPE=ko_KR.UTF-8' "$launcher"
          ok "launcher $app 패치 적용"
          changed=1
        fi
      fi
    fi
  done

  # 7) 폰트/MIME/데스크톱 DB
  if [[ $CHECK_ONLY -eq 0 ]]; then
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
    command -v update-mime-database >/dev/null 2>&1 && update-mime-database /usr/share/mime >/dev/null 2>&1 || true
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
    ok "font/mime/desktop DB 갱신"
  fi

  [[ $changed -eq 1 ]] && log "시스템 설정 일부 수정됨" || log "시스템 설정 정상"
}

# === 사용자 레벨 ===
do_user() {
  # root가 sudo로 실행 시 실제 사용자 홈으로
  local real_home="${HOME}"
  local real_user="${USER:-$(whoami)}"
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    real_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    real_user="$SUDO_USER"
  fi
  # 여러 홈을 지원하기 위해: 현재 프로세스의 $HOME 외에 로그인 사용자 전체 스캔은 하지 않음 (보안)
  local homes=("$real_home")
  # 추가로 /home/* 스캔은 --all-users 옵션일 때만 (현재는 스킵)

  [[ $CHECK_ONLY -eq 1 ]] && log "=== [CHECK] 사용자 레벨 ($real_user) ===" || log "=== 사용자 레벨 한글 설정 ($real_user) ==="

  for home in "${homes[@]}"; do
    [[ -d "$home" ]] || continue
    local conf="$home/.config/Kingsoft/Office.conf"
    local conf_dir="$home/.config/Kingsoft"

    if [[ -f "$conf" ]]; then
      if grep -q "UILanguage=ko_KR" "$conf"; then ok "$home Office.conf UILanguage=ko_KR";
      else
        if [[ $CHECK_ONLY -eq 1 ]]; then fail "$home Office.conf UILanguage != ko_KR (수정 필요)"; else
          # 백업
          cp -a "$conf" "$conf.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
          # 모든 UILanguage 라인을 ko_KR로
          if grep -q "UILanguage" "$conf"; then
            sed -i 's/UILanguage=.*/UILanguage=ko_KR/g' "$conf"
          else
            # 섹션별 추가
            echo "" >> "$conf"
            echo "[6.0]" >> "$conf"
            echo "UILanguage=ko_KR" >> "$conf"
          fi
          # 섹션 보장: [Application Settings], [kl], [6.0\Common]
          for sec in "\[Application Settings\]" "\[kl\]" "\[6.0\\\\Common\]"; do
            if ! grep -q "$sec" "$conf"; then
              echo "" >> "$conf"
              # 실제 sec 문자열은 대괄호 제거 후
              echo "$sec" | sed 's/\\//g' >> "$conf"
              echo "UILanguage=ko_KR" >> "$conf"
            fi
          done
          # 중복 섹션 내 UILanguage 보정
          ok "$home Office.conf 수정 -> ko_KR (백업 생성)"
        fi
      fi
    else
      if [[ $CHECK_ONLY -eq 1 ]]; then warn "$home Office.conf 없음 (첫 실행 시 생성됨)"; else
        mkdir -p "$conf_dir"
        cat > "$conf" <<'EOF'
[6.0]
UILanguage=ko_KR

[Application Settings]
UILanguage=ko_KR

[kl]
UILanguage=ko_KR

[6.0\Common]
UILanguage=ko_KR
EOF
        chown "$real_user:" "$conf" 2>/dev/null || true
        ok "$home Office.conf 생성 -> ko_KR"
      fi
    fi

    # MIME Override.xml 제거 (사용자 홈)
    local override="$home/.local/share/mime/packages/Override.xml"
    if [[ -f "$override" ]]; then
      if [[ $CHECK_ONLY -eq 1 ]]; then warn "$home Override.xml 존재 (삭제 필요)"; else
        rm -f "$override"
        command -v update-mime-database >/dev/null 2>&1 && update-mime-database "$home/.local/share/mime" >/dev/null 2>&1 || true
        ok "$home Override.xml 삭제 및 MIME DB 갱신"
      fi
    else
      ok "$home Override.xml 없음 (정상)"
    fi

    # 권한 보정
    chown -R "$real_user:" "$home/.config/Kingsoft" 2>/dev/null || true
  done

  log "사용자 설정 완료. 터미널 재시작 또는 'wps' 재실행 필요"
}

main() {
  if [[ $DO_SYSTEM -eq 1 ]]; then
    if [[ $EUID -ne 0 && $CHECK_ONLY -eq 0 ]]; then
      warn "시스템 레벨은 root 권한 필요 -> sudo wps-office-kr-setup --system 으로 실행하세요 (건너뜀, 사용자만 수행)"
    else
      do_system
    fi
  fi
  if [[ $DO_USER -eq 1 ]]; then
    do_user
  fi
  if [[ $CHECK_ONLY -eq 1 ]]; then
    log "점검 완료. 이상이 있으면 'sudo wps-office-kr-setup' 실행"
  else
    log "완료. 확인: wps-office-kr-setup --check"
  fi
}

main
