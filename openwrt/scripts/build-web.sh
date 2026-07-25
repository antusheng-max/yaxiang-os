#!/bin/bash
# Yaxiang OS - Web Production Build Script
# Builds the web frontend for production deployment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")/.."
WEB_DIR="${PROJECT_DIR}/web"
OUTPUT_DIR="${PROJECT_DIR}/openwrt/output/v0.2-dev"

echo "========================================="
echo " Yaxiang OS Web Build"
echo "========================================="
echo ""

# Check Node.js
if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js not found"
  exit 1
fi

echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"
echo ""

# Navigate to web directory
cd "$WEB_DIR"

# Clean previous build
echo "[1/3] Cleaning previous build..."
rm -rf dist/

# Install dependencies (if needed)
echo "[2/3] Checking dependencies..."
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm ci 2>/dev/null || npm install
fi

# Build for production
echo "[3/3] Building production bundle..."
echo "  Mode: real (no mock data)"
echo "  Adapter: real (OpenWrt backend)"
echo ""

VITE_APP_MODE=real VITE_ADAPTER_MODE=real npm run build

# Verify build output
echo ""
echo "Build output:"
echo "  Files: $(find dist -type f | wc -l)"
echo "  Size: $(du -sh dist | cut -f1)"
echo "  Source maps: $(find dist -name '*.map' | wc -l)"

# Check for sensitive content
if grep -rq "LineHub\|智能网络优化" dist/ 2>/dev/null; then
  echo "WARNING: Found sensitive text in build output!"
  exit 1
fi

if grep -rq "dev-mock" dist/ 2>/dev/null; then
  echo "WARNING: Found dev-mock references in build output!"
  exit 1
fi

echo ""
echo "Web build completed successfully!"
echo "Output: ${WEB_DIR}/dist"
