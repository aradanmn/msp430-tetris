#!/bin/bash
# sync.sh — commit and push both repos to GitHub
# Usage: ./sync.sh "commit message"
# Run from inside ~/Documents/msp430-dev-vm/ on your Mac

set -e

MSG="${1:-sync: $(date +%Y-%m-%d)}"

COURSE_REPO="$(cd "$(dirname "$0")" && pwd)"
HANDHELD_REPO="$(dirname "$COURSE_REPO")/Handheld-MSP430"

echo "=== msp430-dev-vm ==="
cd "$COURSE_REPO"
git add -A
if git diff --cached --quiet; then
  echo "Nothing to commit in msp430-dev-vm"
else
  git commit -m "$MSG"
  git push
  echo "Pushed msp430-dev-vm"
fi

echo ""
echo "=== Handheld-MSP430 ==="
if [ -d "$HANDHELD_REPO/.git" ]; then
  cd "$HANDHELD_REPO"
  git add -A
  if git diff --cached --quiet; then
    echo "Nothing to commit in Handheld-MSP430"
  else
    git commit -m "$MSG"
    git push
    echo "Pushed Handheld-MSP430"
  fi
else
  echo "Handheld-MSP430 repo not found at $HANDHELD_REPO — skipping"
fi

echo ""
echo "Done."
