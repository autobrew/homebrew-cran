#!/bin/sh
set -e
brew update


brew test-bot

export HOMEBREW_NO_GITHUB_API=1
export HOMEBREW_NO_INSTALL_FROM_API=1
export HOMEBREW_NO_AUTO_UPDATE=1


# Reset homebrew-core
cd $(brew --repo homebrew/core)
git clean -fxd
git remote set-url origin https://github.com/autobrew/homebrew-ventura
git fetch origin main
git reset --hard origin/main


#cd $(brew --repo homebrew/core)
#git clean -fxd
#git reset --hard 2c411e06ca26620ff6d4917f610a0ee5ae0e1baa
#git branch ventura
#git checkout ventura
#git remote remove origin

# brew itself
cd $(brew --repo)
git clean -fxd
git reset --hard 0a7a60f50645c532528b2dcffbc9b7788cb2dcbb
git branch ventura
git checkout ventura
git remote remove origin

GITHUB_ENV="${GITHUB_ENV:-/dev/stderr}"
echo "HOMEBREW_NO_GITHUB_API=1" >> "$GITHUB_ENV"
echo "HOMEBREW_NO_INSTALL_FROM_API=1" >> "$GITHUB_ENV"
echo "HOMEBREW_NO_AUTO_UPDATE=1" >> "$GITHUB_ENV"
