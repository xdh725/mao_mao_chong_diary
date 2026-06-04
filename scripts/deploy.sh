#!/bin/bash
# Deploy dist/ to gh-pages branch (clean, no node_modules)
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# Ensure pnpm and local binaries are in PATH
export PATH="/usr/local/bin:$(pwd)/node_modules/.bin:$PATH"

# Build
echo "Building..."
pnpm build

# Create a clean temp directory with only dist contents
TMPDIR=$(mktemp -d)
cp -r dist/* "$TMPDIR/"
touch "$TMPDIR/.nojekyll"

# Save current branch
CURRENT_BRANCH=$(git branch --show-current)

# Checkout gh-pages, replace all files
git checkout gh-pages

# Remove everything except .git
find . -maxdepth 1 ! -name '.git' ! -name '.' -exec rm -rf {} +

# Copy new files (including hidden ones like .nojekyll)
cp -r "$TMPDIR/." .
rm -rf "$TMPDIR"

# Double-check .nojekyll exists (critical for GitHub Pages)
if [ ! -f .nojekyll ]; then
  echo "Warning: .nojekyll missing, creating it..."
  touch .nojekyll
fi

# Commit and push
git add -A
git commit -m "deploy: $(date +%Y-%m-%d)" || echo "No changes to deploy"
git push origin gh-pages

# Go back
git checkout "$CURRENT_BRANCH"

echo "Deployed to gh-pages!"
