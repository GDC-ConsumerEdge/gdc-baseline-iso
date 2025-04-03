#!/bin/bash

###
### This is a script file that contains only functions and should not be directly runnable
###

function output_msg() {
    if [[ "${VERBOSE}" == "true" ]]; then
        set +x
    fi
    NC='\033[0m'
    BIYellow='\033[1;93m'
    printf "${BIYellow} $1 ${NC}\n"
    if [[ "${VERBOSE}" == "true" ]]; then
        set -x
    fi
}

function validate_config() {
    if [[ -z "${GRUB_PARTITION}" ]]; then
        echo "GRUB_PARTITION size variable has not been set"
        exit 1
    fi
    if [[ -z "${PRIMARY_PARTITION}" ]]; then
        echo "PRIMARY_PARTITION size variable has not been set"
        exit 1
    fi
    if [[ -z "${AUX_PARTITION}" ]]; then
        echo "AUX_PARTITION size variable has not been set"
        exit 1
    fi
}

function show_help() {
    echo ""
    echo "Usage:"
    echo "  ./generate-isos.sh [options]"
    echo "  Options:"
    echo "    -?                        Show this help text"
    echo "    -u <username>             Put this user on the ISO OS"
    echo "    -t <disk type>            Specify 'single' for single disk or 'dual' for dual disk hosts"
    echo "    -p <password>             Use this password for the user at install time. If left empty, a generated password will be created"
    echo "    -h <hostname>             The hostname to be set at install time"
    echo "    -n <integer>              Quantity of ISOs to build in sequence (default 1)"
    echo "    -c                        Clean/remove the output folder"
    echo "    -d                        Dry-run only (no actions)"
    echo "    -o <filepath>             Folder to output (default is ${OUTPUT_PATH}"
    echo "    -k <directory>            Directory containing pub_keys file. Defaults to ./"
    echo "    -e                        Use hardware enablement (HWE) kernel"
    echo "    -v                        Verbose output"
    echo ""
    echo "If you have trouble building this iso in your OS, you can build it in a docker container easily with:"
    echo "'docker run -it -v \$(pwd):/tmp/host -e buildingindocker=true ubuntu:latest'"
    echo " then 'cd /tmp/host', and generate from there."
    echo ""
}

function install_packages() {
  apt update -y && \
  apt install -y wget whois diceware p7zip-full fdisk xorriso
}

function download_iso() {
    if [ ! -f $ISO_NAME ]; then
        wget $UBUNTU_MIRROR/${UBUNTU_VERSION}/$ISO_NAME
    fi
}

function inject_keys() {
    ssh_keys=$'\\n'
    while read key; do
        ssh_keys="$ssh_keys      - '$key'"$'\\n'
    done <${PUB_KEYS_DIR}/pub_keys
    sed -i "s|__SSH_AUTH_KEYS__|$ssh_keys|g" "${REPO_DIR}"/user-data
}

function xorriso_make() {
    HOST=$1

    if [[ "${UBUNTU_VERSION%%.*}" == "20" ]]; then
        #doing focal image w/ isolinux
        xorriso -as mkisofs -r \
                -V "${HOST}" \
                -o "${DESTINATION_FILE}" \
                -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
                -boot-load-size 4 -boot-info-table \
                -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
                -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
                -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin  \
                "${BUILD_DIR}"/boot "${BUILD_DIR}"
    else
        #doing jammy funny without isolinux
        # create the ISO
        #TBD do all the ISO creation stuff
        dd bs=1 count=432 if="${ISO_NAME}" of=MBR.img

        # yank the EFI image off the ISO
        EFI_COUNT=$(fdisk -l "${ISO_NAME}" | awk '/EFI System/' | tr -s " " | cut -d " " -f 4)
        EFI_SKIP=$(fdisk -l "${ISO_NAME}" | awk '/EFI System/' | tr -s " " | cut -d " " -f 2)
        dd bs=512 count="${EFI_COUNT}" skip="${EFI_SKIP}" if="${ISO_NAME}" of=EFI.img

        #  Static vars retrieved from running this command on the ubuntu ISO
        #  temp=$(sudo xorriso -indev ubuntu-22.04.1-desktop-amd64.iso -report_el_torito as_mkisofs)
        #  editing them on the fly likely possible but difficult given the bucket of arguments needed
        #  to create the ISO. Modified to follow the recommended changes from https://help.ubuntu.com/community/LiveCDCustomization
        #  NOTE - if the ISO version changes - some values may shift (like -boot_image any load_size=5154816)
        #    These values need to be updated using the above ...-report_el_torito cmd... to get the new values
        #    or the remixed ISO will be corrupt and likely not work properly

        # Build the ISO
        xorriso -as mkisofs \
        -V "${HOST}" \
        -o "${DESTINATION_FILE}" \
        --grub2-mbr MBR.img \
        --protective-msdos-label \
        -partition_cyl_align off \
        -partition_offset 16 \
        --mbr-force-bootable \
        -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b EFI.img \
        -appended_part_as_gpt \
        -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
        -c '/boot.catalog' \
        -b '/boot/grub/i386-pc/eltorito.img' \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --grub2-boot-info \
        -eltorito-alt-boot \
        -e '--interval:appended_partition_2:::' \
        -no-emul-boot \
        "${BUILD_DIR}"
    fi
}

function build_iso() {
    ### $1 = User
    ### $2 = Password
    ### $3 = Host prefix

    rm -rf "${BUILD_DIR}"

    if [[ "${CLEAN}" == "true" ]]; then
        rm -rf "$OUTPUT_PATH"
    fi

    mkdir -p "${BUILD_DIR}"
    mkdir -p "${OUTPUT_PATH}"

    7z x "${ISO_NAME}" -x'![BOOT]' -o"${BUILD_DIR}"

    cp -r "$SUB_DIR" "${BUILD_DIR}/"

    if [[ -f $BUILD_DIR/README.diskdefines ]]; then
        md5sum "${BUILD_DIR}/README.diskdefines" > "${BUILD_DIR}/md5sum.txt"
    fi

    #isolinux isn't in jammy anymore - only run if this is a focal ISO
    #ds=... is surrounded in quotes to prevent grub interpreting the semicolon
    #noprompt prevents the reminder to eject the cdrom
    if [[ "${UBUNTU_VERSION%%.*}" == "20" ]]; then
        sed -i "s|---|autoinstall fsck.mode=skip noprompt noeject \"ds=nocloud;s=/cdrom/${SUB_DIR}/\" ---|g" "${BUILD_DIR}/isolinux/txt.cfg"
    fi
    sed -i "s|---|autoinstall fsck.mode=skip noprompt noeject \"ds=nocloud;s=/cdrom/$SUB_DIR/\" ---|g" "${BUILD_DIR}/boot/grub/grub.cfg"

    #this avoids flagging an error during startup
    cp "${BUILD_DIR}/boot/grub/grub.cfg" "${BUILD_DIR}/boot/grub/loopback.cfg"

     # Dynamically determine the distribution name (e.g., "focal" or "jammy")
    DIST_NAME=$(ls "${BUILD_DIR}/dists" | head -n 1)

    #jammy wants Packages gunzip'ed for some reason otherwise install will fail
    cd "${BUILD_DIR}/dists/${DIST_NAME}/main/binary-amd64"
    gunzip -k Packages.gz
    cd -
    cd "${BUILD_DIR}/dists/${DIST_NAME}/restricted/binary-amd64"
    gunzip -k Packages.gz
    cd -
    #bug in Ubuntu 20.04.2 ISO - linux-modules-extra for HWE is missing d64 from the amd64
    # this fixes it
    LINUX_MODULES_EXTRA_PATH=$(find "${BUILD_DIR}" -name "linux-modules-extra*am.deb")
    if [[ "${LINUX_MODULES_EXTRA_PATH}" != "" ]]; then
        mv "${LINUX_MODULES_EXTRA_PATH}" "${LINUX_MODULES_EXTRA_PATH%%.deb}d64.deb"
    fi

    if [[ "${HWE}" == "true" ]]; then
        FLAVOR="hwe"
    fi

    if [ -f "${PUB_KEYS_DIR}/pub_keys" ]; then
        inject_keys
    else
        echo "No './pub_keys' file found, not adding authorized keys"
        sed -i '/authorized-keys: __SSH_AUTH_KEYS__/d' "${REPO_DIR}/user-data"
    fi
    sed -i "s|__KERNEL_FLAVOR__|${FLAVOR}|g" "${REPO_DIR}/user-data"
    sed -i "s|__USER_NAME__|$1|g" "${REPO_DIR}/user-data"
    sed -i "s|__PASSWORD__|$2|g" "${REPO_DIR}/user-data"

    sed -i "s|__KERNEL__|${KERNEL}|g" "${REPO_DIR}/user-data"

    sed -i "s|__GRUB_PARTITION__|${GRUB_PARTITION}|g" "${REPO_DIR}/user-data"
    sed -i "s|__PRIMARY_PARTITION__|${PRIMARY_PARTITION}|g" "${REPO_DIR}/user-data"
    sed -i "s|__AUX_PARTITION__|${AUX_PARTITION}|g" "${REPO_DIR}/user-data"
    sed -i "s|__ETH_NAME__|${ETH_NAME}|g" "${REPO_DIR}/user-data"
    sed -i "s|__DISK_PATH_0__|${DISK_0_PATH}|g" "${REPO_DIR}/user-data"
    sed -i "s|__DISK_PATH_1__|${DISK_1_PATH}|g" "${REPO_DIR}/user-data"

    for (( host=1; host<=${HOST_COUNT}; host++ ))
    do
        HOST_FINAL="${3}-${host}"
        DESTINATION_FILE="${OUTPUT_PATH}/${HOST_FINAL}.iso"

        echo "Creating '${HOST_FINAL}' ISO image..."
        sed -i "s|hostname: __HOSTNAME__|hostname: ${HOST_FINAL}|g" "${REPO_DIR}/user-data"
        if [[ ${DRY_RUN} == "true" ]];
        then
            echo "DRY-RUN: create-iso using [${DESTINATION_FILE}] for ${HOST_FINAL} "
        else
            #creating a func to handle making a focal or jammy iso
            xorriso_make "${HOST_FINAL}"
        fi
        # reset the hostname placeholder
        sed -i "s|hostname: ${HOST_FINAL}|hostname: __HOSTNAME__|g" "${REPO_DIR}/user-data"
    done

    if [[ "${VERBOSE}" == "true" ]]; then
        set +x
    fi
    echo -e "\n-----------"
    echo "Access/credentials for each ISO:"
    echo -e "Username: ${DEFAULT_USER}"
    echo -e "Unencrypted Password: ${PASSWORD}"
    echo -e "Encrypted Password: ${ENCRYPTED_USER_PASSWORD}"
    echo ""
    if [[ "${VERBOSE}" == "true" ]]; then
        set -x
    fi
}

function print_config {
    output_msg "BUILD_DIR=${BUILD_DIR}"
    output_msg "SUB_DIR=${SUB_DIR}"
    output_msg "REPO_DIR=${REPO_DIR}"
    output_msg "UBUNTU_MIRROR=${UBUNTU_MIRROR}"
    output_msg "ISO_NAME=${ISO_NAME}"
    output_msg "HOSTNAME=${HOSTNAME}"
    output_msg "OUTPUT_PATH=${OUTPUT_PATH}"
    output_msg "DRY_RUN=${DRY_RUN}"
    output_msg "FLAVOR=${FLAVOR}"
    output_msg "PUB_KEYS_DIR=${PUB_KEYS_DIR}"
    output_msg "Username: ${DEFAULT_USER}"
    output_msg "Unencrypted Password: ${PASSWORD}"
    output_msg "Encrypted Password: ${ENCRYPTED_USER_PASSWORD}"

}