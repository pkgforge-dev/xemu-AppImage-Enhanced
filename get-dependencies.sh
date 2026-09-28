#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	cmake \
	glib2 \
	glslang \
	glu \
	hicolor-icon-theme \
	libatomic \
	libepoxy \
	libgcc \
	libpcap \
	libsamplerate \
	libslirp \
	libusb \
	meson \
	nlohmann-json \
	python-distlib \
	python-yaml \
	sdl3 \
	tomlplusplus \
	vulkan-headers \
	vulkan-icd-loader

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

#if [ "${DEVEL_RELEASE-}" = 1 ]; then
#	package=xemu-git
#else
#	package=xemu
#fi
#make-aur-package "$package"
#pacman -Q "$package" | awk '{print $2; exit}' > ~/version
echo "Building xemu..."
echo "---------------------------------------------------------------"
REPO="https://github.com/xemu-project/xemu"
if [ "${DEVEL_RELEASE-}" = 1 ]; then
    echo "Making nightly build of xemu..."
    echo "---------------------------------------------------------------"
    VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9 | head -1)"
    git clone --depth 1 "$REPO" ./xemu
else
	echo "Making stable build of xemu..."
	VERSION="$(git ls-remote --tags --sort="v:refname" "$REPO" | tail -n1 | sed 's/.*\///; s/\^{}//; s/^v//')"
	git clone --branch v"$VERSION" --single-branch --depth 1 "$REPO" ./xemu
fi
echo "$VERSION" > ~/version

mkdir -p ./AppDir/bin
cd ./xemu

for file in subprojects/SPIRV-Reflect.wrap \
            subprojects/VulkanMemoryAllocator.wrap \
            subprojects/glslang.wrap \
            subprojects/nv2a_vsh_cpu.wrap \
            subprojects/volk.wrap; do
    sed '/\[wrap-/a\
method=cmake
' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
done

meson subprojects download
mkdir -p ../build
python scripts/gen-license.py > XEMU_LICENSE
# fix bug with cmake subprojects
sed -i '/CPU_CFLAGS="-m64"/d' configure

cd ../build
../xemu/configure \
	--audio-drv-list="sdl" \
	--disable-docs \
	--disable-download \
	--disable-werror \
	--enable-pie \
	--extra-cflags="-DXBOX=1" \
	--target-list="i386-softmmu" \
	-Dbuildtype=plain
make qemu-system-i386 -j$(nproc)
mv -v qemu-system-i386 ../AppDir/bin/xemu
