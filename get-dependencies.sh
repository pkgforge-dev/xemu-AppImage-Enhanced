#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
#pacman -Syu --noconfirm

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

if [ "${DEVEL_RELEASE-}" = 1 ]; then
	package=xemu-git
else
	package=xemu
fi
make-aur-package "$package"
pacman -Q "$package" | awk '{print $2; exit}' > ~/version
