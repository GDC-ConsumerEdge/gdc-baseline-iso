#!/bin/bash

# current focal version
# UBUNTU_VERSION="20.04.6"

# current jammy version
UBUNTU_VERSION="22.04.3"

#pick kernel flavor - generic will be LTS regular focal kernel (e.g. 5.4) while HWE will be backported
#  kernel (e.g. 5.15+).
# pick one of the below (NOTE: Focal Generic doesnt support Intel AX WIFI and others - need 5.10+ kernel so Focal HWE will work)
#KERNEL="generic"
KERNEL="hwe"

DISK_0_PATH="" # Default to NUC disks
DISK_1_PATH="" # default to empty, allows automation to replace when commented out
ETH_NAME="en*" # default ethernet adaptor name. This takes wildcard en* (ie: eth0, enp181s0f0, enp111s0, etc)
AUX_PARTITION="-1" # default

# Default User
DEFAULT_USER='abm-admin'

####################################################
##############  SMALL NUCS ( MOST COMMON) ##########
####################################################
######## Smaller NUC (~250GB total storage) ########
####################################################
GRUB_PARTITION="1GB"
PRIMARY_PARTITION="130GB"
DISK_0_PATH="/dev/nvme0n1"
