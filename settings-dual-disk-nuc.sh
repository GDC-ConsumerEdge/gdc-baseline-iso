#!/bin/bash

####################################################
##############  LARGE NUCS   #######################
####################################################
####### This profile has 2 physical disks, #########
####### both about 1TB #############################
####################################################
GRUB_PARTITION="1GB"
PRIMARY_PARTITION="-1"
AUX_PARTITION="-1"
DISK_0_PATH="/dev/nvme0n1" # Swap for Edge1
DISK_1_PATH="/dev/nvme1n1"