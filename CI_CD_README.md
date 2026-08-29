# WPS Office KR - CI/CD Setup

## Overview
Automated build and release pipeline for WPS Office Korean patch package.

## Workflow: `.github/workflows/wps-kr-build.yml`

### Triggers
- **Schedule**: Daily at 02:00 UTC (11:00 KST) - checks for upstream version changes
- **Manual**: `workflow_dispatch` with optional `force_build` and `version` inputs

### Jobs
1. **check-version**: Fetches latest WPS Office version from CDN, compares with PKGBUILD
2. **build**: Builds 3 packages in clean Ubuntu container with Arch toolchain
3. **release**: Creates GitHub Release with artifacts
4. **notify**: Failure notifications

## Required Secrets

Configure in GitHub Repository Settings → Secrets and variables → Actions:

| Secret | Description | Required |
|--------|-------------|----------|
| `GITHUB_TOKEN` | Auto-provided by GitHub, used for release creation | Yes |
| `KOSIS_API_KEY` | KOSIS OpenAPI key (if using KOSIS integration) | No |

### Adding Secrets
1. Go to: `https://github.com/nahdd123uosackr/wps-office-kr/settings/secrets/actions`
2. Click "New repository secret"
3. Add each secret

## Version Detection Logic

The workflow checks for new versions by:

1. **Primary**: Scans `https://pubwps-wps365-obs.wpscdn.cn/download/Linux/` for build numbers
2. **Fallback**: Checks `wps-office-cn` AUR PKGBUILD
3. **Comparison**: Compares with current `pkgver` in PKGBUILD
4. **Build Trigger**: Only builds if version changed OR `force_build=true`

## Package Outputs

| Package | Arch | Description |
|---------|------|-------------|
| `wps-office-kr` | x86_64 | Main package with all patches |
| `wps-office-kr-mime` | any | MIME type definitions |
| `wps-office-kr-fonts` | any | WPS provided Korean fonts |

## Local Development

```bash
# Clone and setup
git clone https://github.com/nahdd123uosackr/wps-office-kr.git
cd wps-office-kr

# Check version
./scripts/dev.sh check-version

# Build in LXC container (recommended)
lxc-create -n wps-build -t download -- --dist archlinux --release current --arch amd64
lxc-start -n wps-build
# ... setup container (see AGENT.md)
lxc-attach -n wps-build -- su - builder -c 'cd /root/wpsoffice && makepkg -s'

# Or use GitHub Actions locally with act
act -j build -s GITHUB_TOKEN=$GITHUB_TOKEN
```

## Release Process

### Automatic (via workflow)
1. Daily cron detects new version
2. Updates PKGBUILD with new version/SHA256
3. Builds 3 packages
4. Creates GitHub Release with artifacts
5. Commits PKGBUILD update to main branch

### Manual Release
```bash
# Trigger via GitHub UI or CLI
gh workflow run wps-kr-build.yml -f force_build=true

# Or specific version
gh workflow run wps-kr-build.yml -f version=12.1.2.28090
```

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Check Version  │────▶│     Build        │────▶│   Release    │
│  (Python/HTTP)  │     │  (Ubuntu+Arch    │     │  (GitHub     │
│                 │     │   toolchain)     │     │   Release)   │
└─────────────────┘     └──────────────────┘     └──────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
   Version JSON           3 .pkg.tar.zst            Tag + Assets
```

## Troubleshooting

### Version not detected
- Check CDN accessibility: `curl -I https://pubwps-wps365-obs.wpscdn.cn/download/Linux/`
- Verify AUR fallback works

### Build fails
- Check build.log in workflow artifacts
- Common: missing dependencies, path issues in PKGBUILD

### Release not created
- Verify `GITHUB_TOKEN` has `contents:write` permission
- Check workflow permissions in repository settings

## File Structure

```
wps-office-kr/
├── .github/
│   └── workflows/
│       └── wps-kr-build.yml    # Main CI/CD workflow
├── scripts/
│   └── dev.sh                  # Local dev helper
├── .env.example                # Environment template
├── PKGBUILD                    # Arch package build script
├── patches/ko_KR/config/       # Korean locale patches
├── 99-wps-office-font-rendering.conf
├── wps-office-mime.xml
├── wps-office-disable-mime-detection.sh
└── wps-office_*.deb            # Source (downloaded at build)
```