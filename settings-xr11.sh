#!/bin/bash

####################################################
##############     XR11      #######################
####################################################
####### This profile has 2 physical disks, #########
####### both about 1TB #############################
####################################################
GRUB_PARTITION="1GB"
PRIMARY_PARTITION="-1"              # remaining of disk
AUX_PARTITION="-1"                  # remaining of disk (or whole-disk in this case)
DISK_0_PATH="/dev/sdb"              # OS & Boot partitions
DISK_1_PATH="/dev/sda"              # "Customer" partition
ETH_NAME="en*"                      # Ethernet interface name matcher