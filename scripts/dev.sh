#!/bin/bash
# Local development helper script for WPS Office KR
# Supports hybrid build: pre-built from GitHub Release or from source

set -euo pipefail

# Load .env if exists
if [[ -f ".env" ]]; then
    export $(grep -v '^#' .env | xargs)
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
  check-version    Check upstream WPS Office version
  build            Build package locally (hybrid: tries pre-built first)
  build-source     Force build from source (skip pre-built check)
  test             Test package in LXC container
  install          Install built packages with pacman
  clean            Clean build artifacts
  help             Show this help

Environment variables (from .env or export):
  USE_PREBUILT=1   Use pre-built packages from GitHub Release (default: 1)
  USE_PREBUILT=0   Force build from source
  GITHUB_TOKEN     GitHub PAT for private repo access (optional)
  PKGDEST          Custom package destination directory

Examples:
  # Default: try pre-built, fallback to source
  $0 build

  # Force source build
  USE_PREBUILT=0 $0 build
  # or
  $0 build-source

  # Check version only
  $0 check-version

  # Install after build
  $0 build && $0 install
EOF
}

check_version() {
    echo -e "${GREEN}Checking upstream version...${NC}"
    python3 << 'PYEOF'
import requests
import re
import os

base_url = "https://pubwps-wps365-obs.wpscdn.cn/download/Linux/"
try:
    resp = requests.get(base_url, timeout=30)
    versions = re.findall(r'(\d{5})/', resp.text)
    versions = sorted(set(versions), reverse=True)
    if versions:
        latest_build = versions[0]
        latest_version = f"12.1.2.{latest_build}"
        print(f"Latest: {latest_version} (build: {latest_build})")
        print(f"Deb URL: https://pubwps-wps365-obs.wpscdn.cn/download/Linux/{latest_build}/wps-office_{latest_version}.AK.preread.sw.365_765469_amd64.deb")
        
        # Check GitHub Release
        gh_url = f"https://api.github.com/repos/nahdd123uosackr/wps-office-kr/releases/tags/v{latest_version}"
        headers = {}
        if os.environ.get('GITHUB_TOKEN'):
            headers['Authorization'] = f"token {os.environ['GITHUB_TOKEN']}"
        gh_resp = requests.get(gh_url, headers=headers, timeout=10)
        if gh_resp.status_code == 200:
            assets = gh_resp.json().get('assets', [])
            if assets:
                print(f"✓ Pre-built packages available on GitHub Release v{latest_version}")
                for asset in assets:
                    if asset['name'].endswith('.pkg.tar.zst'):
                        print(f"  - {asset['name']} ({asset['size']} bytes)")
            else:
                print("✗ No pre-built packages on GitHub Release")
        else:
            print("? GitHub Release not found or not accessible")
    else:
        print("Could not find versions")
except Exception as e:
    print(f"Error: {e}")
PYEOF
}

build() {
    echo -e "${GREEN}Building package (hybrid mode)...${NC}"
    
    # Check if running in Arch-based system
    if ! command -v pacman &> /dev/null; then
        echo -e "${RED}Not in Arch Linux. Use LXC container or GitHub Actions.${NC}"
        echo "For local testing, use: lxc-attach -n wps-build -- su - builder -c 'cd /root/wpsoffice && $0 build'"
        exit 1
    fi
    
    # Install build dependencies
    echo -e "${BLUE}Installing build dependencies...${NC}"
    sudo pacman -S --needed --noconfirm base-devel curl jq
    
    # Run makepkg with USE_PREBUILT
    echo -e "${BLUE}Running makepkg...${NC}"
    USE_PREBUILT="${USE_PREBUILT:-1}" makepkg -s --noconfirm 2>&1 | tee build.log
    
    # Show results
    echo -e "${GREEN}Build complete!${NC}"
    ls -la *.pkg.tar.zst 2>/dev/null || echo "No packages found"
}

build_source() {
    echo -e "${YELLOW}Force building from source...${NC}"
    USE_PREBUILT=0 makepkg -s --noconfirm 2>&1 | tee build.log
}

test_container() {
    echo -e "${GREEN}Testing in LXC container...${NC}"
    if ! command -v lxc-attach &> /dev/null; then
        echo -e "${RED}LXC not available${NC}"
        exit 1
    fi
    
    lxc-attach -n wps-build -- su - builder -c "
        cd /root/wpsoffice
        export USE_PREBUILT=\${USE_PREBUILT:-1}
        export GITHUB_TOKEN=\${GITHUB_TOKEN:-}
        makepkg -s --noconfirm 2>&1 | tee build.log
    "
}

install_pkg() {
    echo -e "${GREEN}Installing packages...${NC}"
    for pkg in *.pkg.tar.zst; do
        [[ -f "$pkg" ]] && sudo pacman -U --noconfirm "$pkg"
    done
}

clean() {
    echo -e "${YELLOW}Cleaning build artifacts...${NC}"
    rm -rf pkg src *.pkg.tar.zst *.log *.deb
    find . -name "*.pkg.tar.zst" -delete 2>/dev/null
}

case "${1:-help}" in
    check-version) check_version ;;
    build) build ;;
    build-source) build_source ;;
    test) test_container ;;
    install) install_pkg ;;
    clean) clean ;;
    *) usage ;;
esac