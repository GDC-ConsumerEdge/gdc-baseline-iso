#!/bin/bash

# upload-isos.sh
# Uploads generated ISOs to a Synology NAS via SMB.

# Default values
NAS_HOST="${NAS_HOST:-storage.ensor-labs.com}"
NAS_SHARE="${NAS_SHARE:-iso_share}"
ISO_DIR="${ISO_DIR:-./iso-outputs}"
ISO_PATTERN="${ISO_PATTERN:-*.iso}"

# Error handling
set -e

function output_error() {
    echo -e "\033[1;91mError: $1\033[0m" >&2
}

function output_msg() {
    echo -e "\033[1;96m$1\033[0m"
}

function check_dependencies() {
    if ! command -v smbclient &> /dev/null; then
        output_error "Required command 'smbclient' is not installed."
        echo "On Debian/Ubuntu, install it using: sudo apt install smbclient"
        exit 1
    fi
}

# Validation
if [[ -z "${NAS_USER}" ]]; then
    output_error "Environment variable NAS_USER is required."
    exit 1
fi

if [[ -z "${NAS_PASS}" ]]; then
    output_error "Environment variable NAS_PASS is required."
    exit 1
fi

if [[ ! -d "${ISO_DIR}" ]]; then
    output_error "Directory ISO_DIR (${ISO_DIR}) does not exist."
    exit 1
fi

check_dependencies

output_msg "Configuration loaded successfully."
output_msg "Target: //${NAS_HOST}/${NAS_SHARE}"
output_msg "Source: ${ISO_DIR}/${ISO_PATTERN}"
