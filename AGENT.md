# AGENT.md

> 이 파일에는 AI가 사용자의 요청을 이해하고 설계/판단한 내용을 **간략히** 기록합니다.
> 상세 내용(조사 과정, 기술 분석, 검증 로그 등)은 각 항목이 링크한 `done_tasks/`(완료) 폴더의
> 주제별 파일에 있습니다. 사용자의 원 요청 내용 자체는 `요청사항.md`에 기록됩니다.
> 실측으로 확정된 핵심 기술 지식은 `구현기술.md`에 누적 기록됩니다.

## 프로젝트 정의: WPS Office 12 한국어 패치 + 날짜 서식 기본값 변경 + MIME/폰트 개선

**목표**: WPS Office 12.1.2.28080 버전을 기준으로 한국어 패치를 적용하고, 엑셀(스프레드시트)에서 날짜 표기 형식을 서식 변경 없이 `yyyy-MM-dd`로 기본 표시되도록 수정한다. Arch Linux PKGBUILD 스크립트로 동적 빌드 환경을 구축한다. 추가로 MIME 타입 오버라이드 방지와 OnlyOffice 방식의 폰트 렌더링 개선을 적용한다.

### 핵심 요구사항
1. **한국어 패치**: Linux 네이티브 버전(wps-office-365) 기반으로 누락된 `ko_KR` 로케일 설정 파일 생성
2. **날짜 서식 기본값**: 설정 파일(`datetimeformat.cfg`, `controldatetimeformat.cfg`, `idstr.cfg`)에서 `yyyy-MM-dd`를 index 1로 설정
3. **MIME 타입 보호**: 시작 시 MIME 탐지 비활성화, 자체 MIME 정의 제공, Override.xml 자동 삭제
4. **폰트 렌더링 개선**: OnlyOffice 방식의 메트릭 호환 폰트 대체( Liberation, Carlito) 적용
5. **빌드 시스템**: Arch Linux PKGBUILD로 재현 가능한 동적 빌드 (3개 서브패키지)
6. **파일 정리**: 필요 파일은 현재 폴더에 다운로드, 폴더 구조 깔끔하게 유지

### 기술적 접근 (변경됨)
- **초기 계획**: Windows 버전 + Wine 설치 → 리소스 추출 (복잡, 불안정)
- **실제 구현**: Linux 네이티브 버전(wps-office-365 12.1.2.28080) 사용
  - Wine 불필요, 네이티브 성능, 설정 파일 텍스트 기반으로 패치 용이
  - 한국어 번역 리소스(.qm) 이미 addons에 포함됨
  - 날짜 서식 설정 파일이 텍스트(cfg)로 직접 수정 가능

---

## 폴더 구조 (완성)

| 경로 | 내용 |
|---|---|
| `PKGBUILD` | Arch Linux 패키지 빌드 스크립트 (메인, 3개 서브패키지) |
| `patches/ko_KR/config/` | 한국어 로케일 패치 3개 (datetimeformat, controldatetimeformat, idstr) |
| `ko_KR_*.patch` | PKGBUILD source용 패치 파일 복사본 |
| `99-wps-office-font-rendering.conf` | Fontconfig (OnlyOffice-inspired 메트릭 호환 폰트 대체) |
| `wps-office-mime.xml` | MIME 타입 정의 (WPS 고유 포맷만, MS Office 포맷 오버라이드 안 함) |
| `wps-office-disable-mime-detection.sh` | 시작 시 MIME 탐지 비활성화 스크립트 |
| `wps-office_12.1.2.28080.AK.preread.sw.365_765469_amd64.deb` | 업스트림 소스 (841MB) |
| `done_tasks/` | 완료 작업 상세 기록 |
| `요청사항.md` | 사용자 원 요청 |
| `구현기술.md` | 실측 기술 지식 누적 |

---

## 진행 이력

| # | 주제 | 요약 | 상태 |
|---|---|---|---|
| 1 | WPS Office 12 소스 확보 | wps-office-365 CDN에서 12.1.2.28080 deb 다운로드 (SHA256 검증) | ✅ 완료 |
| 2 | 한국어 로케일 분석 및 패치 생성 | 누락된 `mui/ko_KR/config/` 3개 파일 생성 (`yyyy-MM-dd` 기본값) | ✅ 완료 |
| 3 | PKGBUILD 작성 (1차) | 기본 한국어 패치 + 로케일 강제 적용 PKGBUILD 작성 | ✅ 완료 |
| 4 | wps-office-cn 참조 및 MIME/폰트 개선 | AUR wps-office-cn 분석 → MIME 분리 패키지, 폰트 렌더링 개선 추가 | ✅ 완료 |
| 5 | OnlyOffice 폰트 렌더링 분석 적용 | Liberation/Carlito 메트릭 호환 대체, 서브픽셀 렌더링, 한글 폴백 체인 | ✅ 완료 |
| 6 | 문서화 | 구현기술.md, AGENT.md, 요청사항.md, done_tasks/ 기록 | ✅ 완료 |

---

## 핵심 기술 지식 (요약)
> 전체 상세는 `구현기술.md` 참고. 아래는 자주 쓰는 최소 요약.

### WPS Office 12 Linux 구조 (12.1.2.28080)
- **설치 경로**: `/opt/kingsoft/wps-office/office6/` (PKGBUILD에서 `/usr/lib/office6/`로 재배치)
- **다국어 리소스**: `/usr/lib/office6/mui/<locale>/`
- **지원 로케일**: `default`, `en_US`, `zh_CN`, `ru_RU` (한국어 `ko_KR` 없음 → 직접 생성)
- **런처 스크립트**: `/usr/bin/{wps,wpp,et,wpspdf}` → `/usr/lib/office6/wpsoffice` 호출

### 날짜 서식 설정 (한국어 로케일 신규 생성)
| 파일 | 핵심 설정 |
|---|---|
| `mui/ko_KR/config/datetimeformat.cfg` | `format/1/name = "yyyy-MM-dd"` (index 1), LCID=1042 |
| `mui/ko_KR/config/controldatetimeformat.cfg` | `item[1] = "yyyy-MM-dd"` |
| `mui/ko_KR/config/idstr.cfg` | `TX_BUILDIN_NF_DATE1 = "yyyy-MM-dd"`, 화폐단위 ₩ |

### MIME 타입 보호 (3중 방어)
1. **설정 비활성화**: `Office.conf` → `do_not_detect_file_association_while_startup=true`
2. **자체 MIME**: `wps-office-mime.xml` (`.wps`, `.et`, `.dps`, `.ofd` 등만 정의)
3. **시작 스크립트**: Override.xml 삭제 + `update-mime-database` 실행

### 폰트 렌더링 (OnlyOffice 방식)
| MS 폰트 | 메트릭 호환 대체 | 패키지 |
|---|---|---|
| Arial | Liberation Sans, Noto Sans | ttf-liberation, noto-fonts |
| Times New Roman | Liberation Serif, Noto Serif | ttf-liberation, noto-fonts |
| Courier New | Liberation Mono, Noto Mono | ttf-liberation, noto-fonts |
| Calibri | Carlito, Liberation Sans | ttf-carlito, ttf-liberation |
| Cambria | Caladea, Liberation Serif | ttf-caladea, ttf-liberation |

### PKGBUILD 구조 (3개 서브패키지)
- `wps-office-kr`: 메인 패키지 (한국어 패치, MIME, 폰트설정, 런처 패치 모두 포함)
- `wps-office-kr-mime`: MIME 타입 정의만 별도 (`shared-mime-info` 훅 자동 실행)
- `wps-office-kr-fonts`: WPS 제공 폰트 + fontconfig 설정

---

## 진행 중 / 미해결 과제
- **완전한 한국어 번역**: addons 내 ko_KR .qm 파일들을 mui/ko_KR/로 통합 필요
- **한글 폰트 번들링**: Noto Sans CJK KR 등 기본 폰트 포함 검토
- **자동 업데이트 차단**: 기업 환경용 설정 추가
- **ARM64/LoongArch64 지원**: PKGBUILD에 아키텍처 추가 (wps-office-365는 지원함)

---

## 참고 자료
- WPS Office 공식 Linux: https://linux.wps.cn/ / https://www.wps.com/office/linux/
- AUR wps-office-365: https://aur.archlinux.org/packages/wps-office-365
- AUR wps-office-cn: https://aur.archlinux.org/packages/wps-office-cn
- Arch Linux PKGBUILD 가이드: https://wiki.archlinux.org/title/PKGBUILD
- OnlyOffice 폰트 대체 PR: https://github.com/ONLYOFFICE/core/pull/1646
- WPS Office MIME 이슈 해결: Arch Wiki / 커뮤니티 가이드