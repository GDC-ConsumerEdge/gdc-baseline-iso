#!/bin/bash

# Include functions
source ./include.sh

trap 'error_handler $? $BASH_LINENO $LINENO $BASH_COMMAND $FUNCNAME[0] $BASH_SOURCE ${FUNCNAME-maincontext[@]}' ERR

# Ability to skip the ISO build, only generate the contents
SKIP_ISO_BUILD=${SKIP_ISO_BUILD:-"false"}

error_handler() {
    set +x
    NC='\033[0m'
    BIYellow='\033[1;93m'
    printf "${BIYellow}Error returned ($1) in File ($0) occured on line: ($3) in function/command: ($4) ${NC}\n"
    set -x
}

OPTIND=1
HOST_COUNT=1
VERBOSE="false"

while getopts "?u:t:p:h:o:n:k:cdev" opt; do
    case "$opt" in
    \?)
        show_help
        exit 0
        ;;
    u)  OPT_USER="$OPTARG";;
    t)  DISK_TYPE="$OPTARG";;
    p)  PASSWORD="$OPTARG";;
    h)  HOSTNAME="$OPTARG";;
    n)  HOST_COUNT="$OPTARG";;
    c)  CLEAN="true";;
    o)  OUTPUT_PATH="$OPTARG";;
    d)  DRY_RUN="true";;
    k)  PUB_KEYS_DIR="$OPTARG";;
    e)  HWE="true";;
    v)  VERBOSE="true";;
    esac
done
shift $(($OPTIND-1))

if [[ ${VERBOSE} == "true" ]]; then
    #set -e exits immediately when a non-zero error is returned from any command
    set -e
    #set -E forces errors to bubble up from functions
    set -E
    #set -o functrace (or -T) adds additional details to errors generated inside of functions
    set -T
    #set -x echos all commands preceeded by a + sign
    set -x
fi

output_msg "Checking executables used in ISO creation"

HAS_EXEC_ERROR=false

for executable in fdisk dd diceware apt wget xorriso 7z sed gnuzip; do
  if ! command -v "$executable" &> /dev/null
  then
    output_msg "$executable could not be found on the path, please install it" "warning"
    HAS_EXEC_ERROR=true
  fi
done

if [[ "$HAS_EXEC_ERROR" == "true" ]]; then
    output_msg "Fatal errors preventing the continue of the creation. Please fix and retry" "error"
    exit 1
fi

if [[ "$DISK_TYPE" == "single" ]]; then
    output_msg "Using SINGLE disk config"
    rm nocloud/user-data || true
    cp template-nocloud/user-data-single-disk nocloud/user-data
    source ./settings-single-disk-nuc.sh
elif [[ "$DISK_TYPE" == "dual" ]]; then
    output_msg "Using DUAL disk config"
    rm nocloud/user-data || true
    cp template-nocloud/user-data-dual-disk nocloud/user-data
    source ./settings-dual-disk-nuc.sh
elif [[ "$DISK_TYPE" == "luks-single" ]]; then
    output_msg "Using LUKS SINGLE disk config"
    rm nocloud/user-data || true
    cp template-nocloud/user-data-luks-single-disk nocloud/user-data
    source ./settings-single-disk-nuc.sh
elif [[ "$DISK_TYPE" == "luks-dual" ]]; then
    output_msg "Using LUKS DUAL disk config"
    rm nocloud/user-data || true
    cp template-nocloud/user-data-luks-dual-disk nocloud/user-data
    source ./settings-dual-disk-nuc.sh
else
    output_msg "-t <disk type> must be 'single', 'dual', 'luks-single', or 'luks-dual'"
    exit 1
fi

### If the CLI password is set, this takes precedence over the ENV variable
### If no CLI, then ENV variable is second choice
### If no CLI or ENV, then generate a password
if [[ ! -z "$PASSWORD" ]]; then
    output_msg "Using ENV varaible DEFAULT_USER_PASSWORD as plain-text password (value will be encoded)"
elif [[ ! -z "$DEFAULT_USER_PASSWORD" ]]; then
    output_msg "No CLI password set, but DEFAULT_USER_PASSWORD detected as plain-text password (value will be encoded)"
    PASSWORD="${DEFAULT_USER_PASSWORD}" # simulate the variables for output message
else
    output_msg "No CLI password set or DEFAULT_USER_PASSWORD, generating a new password"
    PASSWORD=$(diceware -d "-" --no-caps --num 3)
fi
ENCRYPTED_USER_PASSWORD=$(mkpasswd -m sha512crypt "$PASSWORD")


if [[ ! -z "$OPT_USER" ]]; then
    DEFAULT_USER="$OPT_USER"
elif [[ -z "$DEFAULT_USER" ]]; then
    output_msg "Must set either -u <username> on the command line or DEFAULT_USER in your settings file (single or dual)"
    exit 1
else
   OPT_USER="$DEFAULT_USER"
fi

BUILD_DIR='./build'
SUB_DIR='nocloud'
REPO_DIR="$BUILD_DIR/$SUB_DIR"
UBUNTU_MIRROR="http://releases.ubuntu.com"
ISO_NAME="ubuntu-${UBUNTU_VERSION}-live-server-amd64.iso"
HOSTNAME="${HOSTNAME:-ubuntu-server}"    # Default
CLEAN="${CLEAN:-'true'}"
OUTPUT_PATH="${OUTPUT_PATH:-./output}"   # Default
DRY_RUN="${DRY_RUN:-''}"
FLAVOR="${FLAVOR:-generic}"             # Default setting of kernel type (if -e cmd-switch, then hwe is replaced)
PUB_KEYS_DIR="${PUB_KEYS_DIR:-.}"

# Validate the configuration
validate_config

# Print variables out
print_config

if [ "$buildingindocker" == "true" ];
then
    install_packages_ubuntu_container
else
    install_packages
fi

download_iso

if [[ "${SKIP_ISO_BUILD}" == "false" ]]; then
    build_iso "$OPT_USER" "$ENCRYPTED_USER_PASSWORD" "$HOSTNAME"
fi
