#!/bin/sh
# Push only after creating a NEW empty GitHub repository and confirming redistribution rights.
set -eu
REPO_URL=${1:-}
if [ -z "$REPO_URL" ]; then
  echo 'Usage: sh tools/publish-existing-repo.sh https://github.com/OWNER/Forsaken-Starlight-CN.git'
  exit 2
fi
case "$REPO_URL" in
 https://github.com/*/*.git) ;;
 *) echo 'Expected GitHub HTTPS repository URL ending with .git'; exit 2;;
esac
if [ ! -d .git ]; then
  git init -b main
  git add .
  git -c user.name='Forsaken Local Build' -c user.email='forsaken-local@example.invalid' commit -m 'Initial Forsaken Starlight CN stage 2 source'
fi
if ! git remote get-url origin >/dev/null 2>&1; then
 git remote add origin "$REPO_URL"
else
 echo 'origin already exists; verify before pushing'
 git remote -v
 exit 2
fi
git push -u origin main
