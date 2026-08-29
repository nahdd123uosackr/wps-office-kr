# WPS Office 12 한국어 패치 + 날짜 서식 기본값 변경 - 완료 작업 기록

## 작업 일시
2026-08-29

## 작업 요약
WPS Office 12.1.2.28080 Linux 버전을 기반으로 한국어 로케일 패치와 날짜 서식 기본값(yyyy-MM-dd) 변경을 적용하는 Arch Linux PKGBUILD를 작성함.

## 상세 작업 내용

### 1. 소스 확보
- **패키지**: wps-office-365 12.1.2.28080 (AUR wps-office-365 PKGBUILD 참조)
- **다운로드**: `https://pubwps-wps365-obs.wpscdn.cn/download/Linux/28080/wps-office_12.1.2.28080.AK.preread.sw.365_765469_amd64.deb`
- **SHA256**: `df89257786787ba4d22511438d6061c991762a354a66c65903858facd6f2da90`
- **크기**: 841 MB (data.tar 3.5 GB 압축 해제 시)

### 2. 한국어 로케일 분석
기존 Linux 버전은 `mui/ko_KR/` 디렉토리가 없고, `mui/default/config/numberformat/ko_KR.cfg`만 존재.
다음 3개 설정 파일이 누락되어 있었음:
- `mui/<locale>/config/datetimeformat.cfg` - 메인 날짜/시간 서식
- `mui/<locale>/config/controldatetimeformat.cfg` - 컨트롤용 날짜/시간 서식
- `mui/<locale>/config/idstr.cfg` - 내장 숫자/날짜 포맷 문자열

### 3. 한국어 패치 파일 생성 (`patches/ko_KR/config/`)
| 파일 | 핵심 변경사항 |
|---|---|
| `datetimeformat.cfg` | `format/1/name = "yyyy-MM-dd"` (index 1), LCID=1042, preStr=[$-412] |
| `controldatetimeformat.cfg` | `item[1] = "yyyy-MM-dd"`, LCID=1042 |
| `idstr.cfg` | `TX_BUILDIN_NF_DATE1 = "yyyy-MM-dd"`, `TX_NF_USER_Date_1 = "yyyy-MM-dd;@"`, 화폐단위 ₩, 한국어 번역 |

### 4. PKGBUILD 작성 (`PKGBUILD`)
- **패키지명**: `wps-office-kr`, `wps-office-kr-fonts`
- **충돌/제공**: `wps-office`, `wps-office-365`와 충돌, `wps-office` 제공
- **prepare()**: deb 추출 + ko_KR 디렉토리 생성 + 패치 파일 복사 + numberformat.cfg 복사
- **package_wps-office-kr()**: 
  - 시스템 라이브러리 사용(libjpeg, libstdc++ 제거)
  - 데스크톱 Categories에 Office; 추가
  - fcitx 입력기, 커스텀 폰트설정, 강제로그인 비활성화
  - **핵심**: 런처에 `export LC_ALL=ko_KR.UTF-8`, `export LANG=ko_KR.UTF-8` 추가

### 5. 테스트 검증
- deb 추출 → 패치 적용 → 런처 수정 → 데스크톱 파일 수정 → 라이브러리 정리
- 모든 파일 정상 적용 확인됨

## 생성된 파일 구조
```
/root/wpsoffice/
├── AGENT.md                           # 프로젝트 관리 문서
├── 요청사항.md                         # 사용자 원 요청
├── 구현기술.md                         # 기술 지식 누적
├── PKGBUILD                           # Arch Linux 빌드 스크립트
├── patches/
│   └── ko_KR/
│       └── config/
│           ├── datetimeformat.cfg
│           ├── controldatetimeformat.cfg
│           └── idstr.cfg
├── ko_KR_datetimeformat.patch         # PKGBUILD source용
├── ko_KR_controldatetimeformat.patch
├── ko_KR_idstr.patch
├── wps-office_12.1.2.28080.AK.preread.sw.365_765469_amd64.deb
└── test_build/                        # 테스트용 추출 (git 제외)
```

## Arch Linux에서 빌드/설치 방법
```bash
# 1. PKGBUILD와 소스 파일들을 빌드 디렉토리에 복사
# 2. makepkg -si 실행
# 3. wps-office-kr, wps-office-kr-fonts 설치됨

# 실행 시 자동으로 한국어 로케일 적용:
et  # 스프레드시트 실행 → 날짜 기본 서식이 yyyy-MM-dd
```

## 알려진 제약사항
1. **한글 폰트**: `wps-office-kr-fonts` 별도 설치 필요 또는 시스템 폰트 설정
2. **입력기**: fcitx5 권장, 런처에 QT_IM_MODULE 설정됨
3. **ARM64/LoongArch**: PKGBUILD에 아키텍처 미포함 (필요시 추가)

## 참고: Windows+Wine 방식 미사용 사유
- Wine 32/64비트 멀티아키텍처 설정 복잡
- 설치 프로세스에서 추가 다운로드 필요 (네트워크 의존)
- 설정 파일이 레지스트리/바이너리에 있어 리버스 엔지니어링 필요
- Linux 네이티브가 설정 파일 텍스트 기반으로 패치 훨씬 용이