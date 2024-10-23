# Overview

This project will assist in creating a headless bootable Ubuntu 20.04 LTS ISO ready to be flashed to a bootable USB drive.

> !!! Booting this USB in any computer will wipe that computer's disk device without asking first !!!

> !!! This script has only been tested on Ubuntu 20.04 and I've made no attempt to make this work on any other OS !!!

> !!! NOTE: If this is intended to be used in conjunction with Robin.io SDS, please follow instructions at the bottom of this document

# TL;DR

1. Clone this repository and the `core` (https://consumer-edge.googlesource.com/core) repoistory (2 separate folders)

  ```bash
    $ tree
    .
    ├── edge-ubuntu-20-04-autoinstaller/
    ├── core/
  ```

1. Select and uncomment (and/or adjust) variables in the `settings.sh` file to match your hardware

    <!-- | Name | Description |
    |----|--------|
    | small | NUCs, testing and smaller equipment | -->

1. Ensure you have a USB flashing tool (example: [balena Etcher](https://www.balena.io/etcher/), [Rufus](https://rufus.ie/))
1. Add public encryption key to the ISO for easy passwordless

    > OPTION 1 - Create a new SSH key-pair to be added to the `authorized_keys` file for the OS user (required for passwordless SSH).

    ```bash
    # Example ed25519 encryption algorithm key named "consumer-edge-machine" (will create "core/build-artifacts/consumer-edge-machine" and "core/build-artifacts/consumer-edge-machine.pub")
    # From within the `edge-ubuntu-20-04-autoinstaller` project folder
    ssh-keygen -o -a 100 -t ed25519 -f ../core/build-artifacts/consumer-edge-machine -q -N "" -C "consumer-edge-iso"
    ```

    > OPTION 2 - (most common) obtain the SSH Public key string

    BOTH Options -

    1. Copy public key(s) into `pub_keys`
        1. Copy SSH Pub keys into this file (single-line) for passwordless SSH access
        ```bash
        # Add one public key to file
        cat <the-key>>.pub >> ./pub_keys
        ```
    1. NOTE: While not required, making a backup of this key to GCP Secret Manger (b/258469081) is not a bad idea (future use and implementation coming)


1. Run the image generator script with defaults (use `./generate-isos.sh -?` for help)

    ```bash
    # Generate 3 ISOs with "edge" prefix and placed in ./iso-outputs folder
    ./generate-isos.sh -n 3 -t "luks-dual" -p "some-password" -h edge -o ./iso-outputs
    ```
1. Use a USB flashing tool to flash ISOs to USB(s)
    * [Rufus](https://rufus.ie/) - Windows
    * [balena Etcher](https://www.balena.io/etcher/) - MacOS
    * [dd](https://man7.org/linux/man-pages/man1/dd.1.html) - Linux and MacOS

1. `dd` method:

  * Get list of disks to flash to using `lsblk`

  ```bash
  # OF needs to match the device you want to flash to (this will overwrite)
  # IF needs to match the ISO you want to flash
  sudo dd if=./iso-outputs/cluster-1.iso of=/dev/sda status=progress
  ```

## NOTES
* USB does not have a stop method, it reboots after completing. This can re-start the installation process.
* Default username: `abm-admin`
* Default password (though, not used unless necessary): `troubled-marble-150`
* Default to 1 ISO replica, change with `-n X` (number)

# Advanced Configuration

## Two Disk Scenario

Some intended systems may have two disks to physically split up storage. If your system has 2 disks, please look at `nocloud/user-data` template and uncomment the second disk in the configuration. Adding the second disk is both in the `autoinstall.storage.config` segment as well as the partition section. Comments are left in the template to guide.

Here is an exmaple of adding a second disk and referencing `partition-2` to use `disk-1`:

```yaml
  ...
  storage:
    swap:
      size: 0
    config:
      # Primary Disk
      - id: disk-0
        type: disk
        ptable: gpt
        wipe: superblock
        preserve: false
        name: "boot"
        grub_device: false
        path: __DISK_PATH_0__
      ### Second Disk
      - id: disk-1
        type: disk
        ptable: gpt
        wipe: superblock
        preserve: false
        name: "second"
        grub_device: false
        path: __DISK_1_PATH__
  ...
  ...
      # Extended Partition
      - type: partition
        id: partition-2
        device: disk-1          ### Second Disk
        size: __AUX_PARTITION__
        wipe: superblock
        flag: ""
        number: 3
        preserve: false

```

# Robin.IO SDS Specific instructions

Robin requires a non-partitiond second disk drive or a partition. The partition discovery is not yet complete, so if you are flashing for a system that will use Robin, you need to do the following:

1. Follow instructions on how to set up a "two disk"
1. After completing the "two-disk" setup, comment out `nocloud/user-data` comment out the sections labled with:
    ```bash
    # ROBIN-IO -- Comment the block below out
    ```
1. Generate the ISO(s)