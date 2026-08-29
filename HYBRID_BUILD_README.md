# 하이브리드 빌드 시스템 - WPS Office KR

## 개요
`makepkg` 실행 시 **GitHub Release에 미리 빌드된 패키지가 있으면 다운로드**하고, **없으면 소스에서 빌드**하는 하이브리드 방식입니다.

## 작동 원리

```
makepkg 실행
    │
    ▼
USE_PREBUILT=1 (기본값)?
    │
    ├── Yes ──▶ GitHub Release v{pkgver} 확인
    │              │
    │              ├── 패키지 3개 모두 존재? ──▶ 다운로드 후 설치 완료 ⚡
    │              │
    │              └── 없음/일부 누락 ──▶ 소스 빌드로 폴백
    │
    └── No (USE_PREBUILT=0) ──▶ 소스에서 정상 빌드
```

## 사용법

### 1. 기본 실행 (하이브리드 모드)
```bash
# GitHub Release에서 미리 빌드된 패키지 시도 → 없으면 소스 빌드
makepkg -s
```

### 2. 강제 소스 빌드
```bash
# 미리 빌드된 패키지 무시하고 무조건 소스에서 빌드
USE_PREBUILT=0 makepkg -s
```

### 3. 개발 헬퍼 스크립트 사용
```bash
# 하이브리드 빌드 (기본)
./scripts/dev.sh build

# 강제 소스 빌드
./scripts/dev.sh build-source
# 또는
USE_PREBUILT=0 ./scripts/dev.sh build
```

## 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `USE_PREBUILT` | `1` | `1`=하이브리드 모드, `0`=강제 소스 빌드 |
| `GITHUB_TOKEN` | - | Private repo 접근용 GitHub PAT (선택) |
| `PKGDEST` | - | 패키지 출력 디렉토리 커스텀 |

## GitHub Release 구조 요구사항

자동 다운로드하려면 Release 태그가 `v{pkgver}` 형식이어야 하며, 다음 3개 자산이 포함되어야 합니다:

```
Release: v12.1.2.28080
├── wps-office-kr-12.1.2.28080-1-x86_64.pkg.tar.zst
├── wps-office-kr-mime-12.1.2.28080-1-any.pkg.tar.zst
└── wps-office-kr-fonts-12.1.2.28080-1-any.pkg.tar.zst
```

## 로컬 테스트 시나리오

### 시나리오 1: Release 패키지 있음 (빠른 설치)
```bash
$ makepkg -s
==> Making package: wps-office-kr 12.1.2.28080-1
==> Checking for pre-built packages from GitHub Release...
==> Downloading pre-built packages...
  -> wps-office-kr... OK
  -> wps-office-kr-mime... OK  
  -> wps-office-kr-fonts... OK
==> Successfully downloaded all pre-built packages
==> Finished making: wps-office-kr 12.1.2.28080-1 (5초 소요)
```

### 시나리오 2: Release 패키지 없음 (소스 빌드)
```bash
$ makepkg -s
==> Making package: wps-office-kr 12.1.2.28080-1
==> Checking for pre-built packages from GitHub Release...
==> No pre-built packages found, falling back to source build
==> Building from source...
... (일반 빌드 과정, 수분 소요)
```

### 시나리오 3: 강제 소스 빌드
```bash
$ USE_PREBUILT=0 makepkg -s
==> Making package: wps-office-kr 12.1.2.28080-1
==> USE_PREBUILT=0, building from source...
... (소스 빌드 과정)
```

## CI/CD와의 연동

GitHub Actions 워크플로우(`.github/workflows/wps-kr-build.yml`)는 **항상 소스에서 빌드**하여 Release를 생성합니다. 로컬 사용자만 하이브리드 방식을 혜택받습니다.

```yaml
# CI에서는 USE_PREBUILT 강제 비활성화
env:
  USE_PREBUILT: "0"
```

## 오프라인/방화벽 환경

네트워크 없이 빌드하려면:
```bash
USE_PREBUILT=0 makepkg -s
```

또는 미리 다운로드한 패키지를 `PKGDEST`에 배치:
```bash
export PKGDEST=/path/to/local/packages
makepkg -s  # 로컬 패키지 우선 사용
```

## 문제 해결

### "Could not resolve host: api.github.com"
네트워크 문제. 강제 소스 빌드:
```bash
USE_PREBUILT=0 makepkg -s
```

### "Pre-built package verification failed"
손상된 다운로드. 캐시 삭제 후 재시도:
```bash
rm -f *.pkg.tar.zst
makepkg -s
```

### 버전 불일치
PKGBUILD의 `pkgver`와 Release 태그(`v{pkgver}`)가 일치해야 함:
```bash
# PKGBUILD 확인
grep pkgver PKGBUILD
# → pkgver=12.1.2.28080

# Release 태그 확인
# → v12.1.2.28080
```

## 아키텍처별 동작

| 패키지 | 아키텍처 | 파일명 패턴 |
|--------|----------|-------------|
| wps-office-kr | x86_64 | `*-x86_64.pkg.tar.zst` |
| wps-office-kr-mime | any | `*-any.pkg.tar.zst` |
| wps-office-kr-fonts | any | `*-any.pkg.tar.zst` |

## 보안 고려사항

- `GITHUB_TOKEN` 없이도 Public repo는 접근 가능
- Private repo 사용 시 `GITHUB_TOKEN` 필요 (read:packages 권한)
- 다운로드된 패키지는 `bsdtar`로 무결성 검증 후 설치
- SHA256 별도 검증은 Release 자산 업로드 시 GitHub가 수행