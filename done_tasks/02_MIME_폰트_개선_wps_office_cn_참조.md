# wps-office-cn 참조 및 MIME/폰트 개선 - 완료 작업 기록

## 작업 일시
2026-08-29

## 작업 요약
AUR wps-office-cn 패키지를 분석하여 MIME 타입 분리 패키지 구조를 채택하고, OnlyOffice의 폰트 렌더링 방식을 분석하여 WPS Office에 적용함.

## 상세 작업 내용

### 1. wps-office-cn PKGBUILD 분석
- **서브패키지 구조**: `wps-office-cn`, `wps-office-mime-cn`, `wps-office-mui-zh-cn` 3개로 분리
- **설치 경로**: `/opt/kingsoft/wps-office/` → `/usr/lib/office6/`로 재배치 (FHS 준수)
- **런처 수정**: `/usr/lib/office6` 경로로 sed 치환
- **시스템 라이브러리**: libjpeg, libstdc++ 제거하여 시스템 것 사용

### 2. MIME 타입 오버라이드 문제 해결 (3중 방어)

#### 문제 원인
WPS Office 시작 시 `~/.local/share/mime/packages/Override.xml` 생성하여 `.docx`, `.xlsx`, `.pptx` 등 시스템 MIME 타입을 강제로 WPS로 변경 → 다른 앱과 충돌

#### 해결 방안
| 레이어 | 구현 | 파일 |
|---|---|---|
| 1. 설정 비활성화 | `Office.conf`에 `do_not_detect_file_association_while_startup=true` | `wps-office-disable-mime-detection.sh` |
| 2. 자체 MIME 정의 | WPS 고유 포맷만 정의 (.wps, .et, .dps, .ofd 등) | `wps-office-mime.xml` |
| 3. 시작 시 정리 | Override.xml 삭제 + MIME DB 갱신 | `wps-office-disable-mime-detection.sh` |

#### PKGBUILD 통합
- `package_wps-office-kr-mime` 서브패키지로 분리 (`arch=('any')`)
- `shared-mime-info` 의존 → `update-mime-database` 훅 자동 실행
- `/usr/share/mime/packages/wps-office.xml` 설치

### 3. OnlyOffice 폰트 렌더링 분석 및 적용

#### OnlyOffice 핵심 기술 (PR #1646 분석)
1. **메트릭 호환 폰트 대체**: 런타임에 시스템 폰트 스캔 후 Microsoft 폰트를 메트릭 호환 오픈소스 폰트로 매핑
2. **정적 대체 리스트**: Times New Roman→Liberation Serif, Calibri→Carlito 등 하드코딩된 매핑
3. **AllFonts.js 생성**: 편집기 폰트 드롭다운용 메타데이터 생성
4. **번들 폴백 폰트**: Liberation, Carlito 기본 포함

#### WPS Office 적용: `99-wps-office-font-rendering.conf`
```xml
<!-- MS 폰트 → 메트릭 호환 대체 -->
<alias>
  <family>Arial</family>
  <prefer><family>Liberation Sans</family><family>Noto Sans</family></prefer>
</alias>
<!-- Calibri → Carlito -->
<alias>
  <family>Calibri</family>
  <prefer><family>Carlito</family><family>Liberation Sans</family></prefer>
</alias>
<!-- 한글 폴백 체인 -->
<alias>
  <family>Noto Sans CJK KR</family>
  <prefer><family>Noto Sans CJK KR</family><family>NanumGothic</family>...</prefer>
</alias>
```

#### 렌더링 최적화 설정
- 안티앨리어싱 + 힌팅 (`hintslight`) 활성화
- 서브픽셀 렌더링 (RGB LCD 필터)
- 작은 한글 텍스트(≤16px): `hintmedium` + 오토힌팅
- 비트맵 폰트 거부 (스케일러블만)
- 이모지 폴백: Noto Color Emoji → Twemoji

#### optdepends 추가
- `ttf-liberation`: Arial/Times/Courier 메트릭 호환 (필수급)
- `ttf-carlito`: Calibri 메트릭 호환
- `ttf-ms-fonts` (AUR): 완벽 호환 필요 시

### 4. PKGBUILD 업데이트 사항
- `arch=('x86_64')` 명시 (aarch64는 추후 추가)
- `depends`에 `desktop-file-utils`, `shared-mime-info`, `hicolor-icon-theme`, `sdl2`, `libglvnd` 추가
- `prepare()`에서 fontconfig, MIME, 시작 스크립트 설치
- `package_wps-office-kr()`에서 fontconfig/MIME 시스템 경로 연동
- 런처에 MIME 비활성화 스크립트 호출 추가

## 생성/수정된 파일
```
/root/wpsoffice/
├── PKGBUILD                              # 업데이트됨 (3 서브패키지, MIME/폰트 통합)
├── 99-wps-office-font-rendering.conf     # 신규: Fontconfig (OnlyOffice 방식)
├── wps-office-mime.xml                   # 신규: MIME 정의 (WPS 고유만)
├── wps-office-disable-mime-detection.sh  # 신규: 시작 시 MICE 보호
├── patches/ko_KR/config/                 # 기존 유지
└── 구현기술.md                           # 업데이트됨 (섹션 7, 8 추가)
```

## 검증 사항
- [x] PKGBUILD 문법 검사 (`makepkg --check`)
- [x] 패치 파일 경로 확인
- [x] Fontconfig XML 유효성
- [x] MIME XML 스키마 준수
- [x] 시작 스크립트 실행 권한 및 논리 확인

## 참고: wps-office-cn 대비 개선점
1. **한국어 로케일 추가**: `ko_KR` 전체 지원 (날짜 yyyy-MM-dd 기본)
2. **MIME 분리 패키지**: `wps-office-kr-mime`로 독립 배포
3. **폰트 렌더링**: OnlyOffice 방식 메트릭 호환 대체 적용
4. **런처 강화**: MIME 비활성화 + 로케일 강제 + 입력기 + 폰트설정 + 로그인비활성화
5. **서브패키지 명명**: `-cn` → `-kr` 접미사로 한국어 타겟 명확화