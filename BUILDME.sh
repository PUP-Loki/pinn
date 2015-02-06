#!/bin/bash

# Bash script to rebuild recovery

set -e

# Final directory where NOOBS files will be copied to
NOOBS_OUTPUT_DIR="output"


function get_package_version {
  PACKAGE=$1
  CONFIG_FILE="package/$PACKAGE/$PACKAGE.mk"
  if [ -f "$CONFIG_FILE" ]; then
    CONFIG_VAR=$(echo "$PACKAGE-version" | tr '[:lower:]-' '[:upper:]_')
    grep -E "^$CONFIG_VAR\s*=\s*.+$" "$CONFIG_FILE" | tr -d ' ' | cut -d= -f2
  fi
}


function update_github_package_version {
    PACKAGE=$1
    GITHUB_REPO=$2
    BRANCH=$3
    CONFIG_FILE="package/$PACKAGE/$PACKAGE.mk"
    if [ -f "$CONFIG_FILE" ]; then
        OLDREV=$(get_package_version $PACKAGE)
        if [ -z "$OLDREV" ]; then
            echo "Error getting OLDREV for $PACKAGE";
        else
            REPO_API=https://api.github.com/repos/$GITHUB_REPO/git/refs/heads/$BRANCH
            GITREV=$(curl -s ${REPO_API} | awk '{ if ($1 == "\"sha\":") { print substr($2, 2, 40) } }')
            if [ -z "$GITREV" ]; then
                echo "Error getting GITREV for $PACKAGE ($BRANCH)";
            else
                if [ "$OLDREV" == "$GITREV" ]; then
                    echo "Package $PACKAGE ($BRANCH) is already newest version"
                else
                    CONFIG_VAR=$(echo "$PACKAGE-version" | tr '[:lower:]-' '[:upper:]_')
                    sed -ri "s/(^$CONFIG_VAR\s*=\s*)[0-9a-f]+$/\1$GITREV/" "$CONFIG_FILE"
                    echo "Package $PACKAGE ($BRANCH) updated to version $GITREV"
                fi
            fi
        fi
    else
        echo "$CONFIG_FILE doesn't exist"
    fi
}


function get_kernel_version {
    CONFIG_FILE=.config
    CONFIG_VAR=BR2_LINUX_KERNEL_VERSION
    grep -E "^$CONFIG_VAR=\".+\"$" "$CONFIG_FILE" | tr -d '"' | cut -d= -f2
}


cd buildroot

# WARNING: don't try changing these - you'll break buildroot
BUILD_DIR="output/build"
IMAGES_DIR="output/images"

# Delete buildroot build directory to force rebuild
if [ -e "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR/recovery-$(get_package_version recovery)" || true
fi

for i in $*; do
    # Update raspberrypi/firmware master HEAD version in package/rpi-firmware/rpi-firmware.mk to latest
    if [ $i = "update-firmware" ]; then
        update_github_package_version rpi-firmware raspberrypi/firmware master
    fi

    # Update raspberrypi/userland master HEAD version in package/rpi-userland/rpi-userland.mk to latest
    if [ $i = "update-userland" ]; then
        update_github_package_version rpi-userland raspberrypi/userland master
    fi

    # Early-exit (in case we want to just update config files without doing a build)
    if [ $i = "nobuild" ]; then
        exit
    fi
done

# Let buildroot build everything
make

# Create output dir and copy files
FINAL_OUTPUT_DIR="../$NOOBS_OUTPUT_DIR"
mkdir -p "$FINAL_OUTPUT_DIR"
mkdir -p "$FINAL_OUTPUT_DIR/os"
cp -r ../sdcontent/* "$FINAL_OUTPUT_DIR"
cp "$IMAGES_DIR/zImage" "$FINAL_OUTPUT_DIR/recovery.img"
cp "$IMAGES_DIR/rootfs.cpio.lzo" "$FINAL_OUTPUT_DIR/recovery.rfs"

# Ensure that final output dir contains files necessary to boot
cp "$IMAGES_DIR/rpi-firmware/start.elf" "$FINAL_OUTPUT_DIR/recovery.elf"
cp "$IMAGES_DIR/rpi-firmware/bootcode.bin" "$FINAL_OUTPUT_DIR"
cp "$IMAGES_DIR/cmdline.txt" "$FINAL_OUTPUT_DIR/recovery.cmdline"
touch "$FINAL_OUTPUT_DIR/RECOVERY_FILES_DO_NOT_EDIT"

# Create build-date timestamp file containing Git HEAD info for build
BUILD_INFO="$FINAL_OUTPUT_DIR/BUILD-DATA"
echo "Build-date: $(date +"%Y-%m-%d")" > "$BUILD_INFO"
echo "NOOBS Version: $(git describe)" >> "$BUILD_INFO"
echo "NOOBS Git HEAD @ $(git rev-parse --verify HEAD)" >> "$BUILD_INFO"
echo "rpi-userland Git master @ $(get_package_version rpi-userland)" >> "$BUILD_INFO"
echo "rpi-firmware Git master @ $(get_package_version rpi-firmware)" >> "$BUILD_INFO"
echo "rpi-linux Git rpi-3.6.y @ $(get_kernel_version)" >> "$BUILD_INFO"

cd ..

clear
echo "Build complete. Copy files in '$NOOBS_OUTPUT_DIR' directory onto a clean FAT formatted SD card to use."
