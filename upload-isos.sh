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

# Find files and upload
# Use a subshell to avoid changing the script's working directory
(
    cd "${ISO_DIR}"
    
    # Expand the pattern and check if files exist
    # Enable nullglob so unmatched patterns return empty instead of the literal string
    shopt -s nullglob
    files=(${ISO_PATTERN})
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        output_msg "No files found matching '${ISO_PATTERN}' in ${ISO_DIR}."
        exit 0
    fi

    for file in "${files[@]}"; do
        output_msg "Uploading ${file}..."
        
        # Execute smbclient
        # -U sets credentials, -c issues the command.
        if ! smbclient "//${NAS_HOST}/${NAS_SHARE}" -U "${NAS_USER}%${NAS_PASS}" -c "put ${file}" ; then
            output_error "Failed to upload ${file}."
            # We don't exit here so other files can still attempt to upload
        else
            output_msg "Successfully uploaded ${file}."
        fi
    done
)

output_msg "Upload process completed."
