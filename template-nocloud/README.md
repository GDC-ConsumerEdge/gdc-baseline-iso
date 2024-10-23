# Overview

The "no-cloud" is a datasource for Cloud Init that indicates how a system is to be configured. There are two files that are pre-configured corresponding to Single Disk and Two Disk installations

## Partitions
1. Partition 1 - the boot partition containing all of the boot information (ie: efi & grub). Default to 1GB of storage
1. Partition 2 - the OS boot partition containing the OS and the cluster w/ adjacent space for logs, containers, etc. Default set to 130GB of storage
1. Partition 3 - the "customer" partition containing the space that the SDS uses for storage. Default is to take the remaining or all of the disk (ie: "-1" for "all remaining")

## Disk Types

> Single Disk

For systems that have just one disk in them. Partitions 1-3 are all located on the same disk

> Dual Disk

For systems where there are 2 disks, one dedicated for "customer" data used by the SDS

## TODO
- Create a command line switch to use different configurations based on disk count




./generate-isos.sh -k . -n 3 -t luks-dual -h wwc -o ./iso-outputs
