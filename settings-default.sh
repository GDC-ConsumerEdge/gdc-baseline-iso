#!/bin/bash

# jammy version
UBUNTU_VERSION="22.04.5"

# Pick kernel flavor - generic will be LTS regular focal kernel (e.g. 5.4) while HWE will be backported
# kernel (e.g. 5.15+).
# Note: Focal Generic doesnt support Intel AX WIFI and others - need 5.10+ kernel so Focal HWE will work.
# Possible values: "generic" or "hwe"
KERNEL="hwe"

DISK_0_PATH="" # Default to NUC disks
DISK_1_PATH="" # default to empty, allows automation to replace when commented out
ETH_NAME="en*" # default ethernet adaptor name. This takes wildcard en* (ie: eth0, enp181s0f0, enp111s0, etc)
PRIMARY_PARTITION="130GB" # Partition for the OS
AUX_PARTITION="-1" # Partition for the "customer" data

# Default User
DEFAULT_USER='abm-admin'

# Below are examples of that you can copy to create settings for YOUR target hardware.
# DON'T FORGET to uncomment the "Two Disks" in user-data IF you are using multiple disks

####################################################
##############  LARGE NUCS   #######################
####################################################
####### This profile has 2 physical disks, #########
####### both about 1TB #############################
####################################################
#GRUB_PARTITION="1GB"
#PRIMARY_PARTITION="-1"
#AUX_PARTITION="-1"
#DISK_0_PATH="/dev/nvme1n1"
#DISK_1_PATH="/dev/nvme0n1"
#ETH_NAME="en*"

####################################################
##############  MEDIUM NUCS   ######################
####################################################
########## Medium NUC (500GB total) ################
####################################################

# GRUB_PARTITION="1GB"
# PRIMARY_PARTITION="130GB"
# AUX_PARTITION="-1"
# DISK_0_PATH="/dev/nvme0n1"

####################################################
##############  SMALL NUCS ( MOST COMMON) ##########
####################################################
######## Smaller NUC (~250GB total storage) ########
####################################################
# GRUB_PARTITION="1GB"
# PRIMARY_PARTITION="40GB"
# DISK_0_PATH="/dev/nvme0n1"
