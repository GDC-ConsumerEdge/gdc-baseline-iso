# Overview

This project will assist in creating a headless bootable Ubuntu 20.04 or 22.04 LTS ISO ready to be flashed to a bootable USB drive.

> !!! Booting this USB in any computer will wipe that computer's disk device without asking first !!!

> !!! This script has only been tested on Ubuntu 20.04 and 22.04 LTS. No other testing has been performed on other OS or OS versions. Use at your own risk

# TL;DR

1. Clone this repository and the `core` (https://github.com/GDC-ConsumerEdge/consumer-edge-core) repoistory (2 separate folders)

  ```shell
    $ tree
    .
    ├── gdc-baseline-iso/
    ├── consumer-edge-core/
  ```

1. Download a USB flashing tool (example: [balena Etcher](https://www.balena.io/etcher/), [Rufus](https://rufus.ie/)) for your Operating system

  * `dd` works for Linux and Mac, but is not as elegant as Balena or Rufus

1. Add public key to the ISO for easy passwordless

    1. Copy public key(s) into `pub_keys`
        1. Copy SSH Pub keys into this file (single-line) for passwordless SSH access
        ```bash
        # Add one public key to file
        cat [key-file.pub] >> ./pub_keys
        ```
    1. NOTE: While not required, making a backup of this key to GCP Secret Manger is not a bad idea

1. Run the image generator script with defaults (use `./generate-isos.sh -?` for help)

    ```shell
    # Generate 3 ISOs with "edge" prefix and placed in ./iso-outputs folder
    export HOSTNAME_PREFIX="edge"
    export TEMPLATE="luks-dual" # "single", "luks-single", "dual", "luks-dual"

    ./generate-isos.sh -n 3 -t ${TEMPLATE} -k . -h ${HOSTNAME_PREFIX} -o ./iso-outputs
    ```

    a. The settings applied to the template are found in the `settings-*.sh` files in the root of the project (for now).

    | Disk Type | Template | Settings file |
    |--------------|-----------------------------------------------|-------------------------------|
    | single       | template-nocloud/user-data-single-disk        | ./settings-single-disk-nuc.sh |
    | dual         | template-nocloud/user-data-dual-disk          | ./settings-dual-disk-nuc.sh   |
    | luks-single  | template-nocloud/user-data-luks-single-disk   | ./settings-single-disk-nuc.sh |
    | luks-dual    | template-nocloud/user-data-luks-dual-disk     | ./settings-dual-disk-nuc.sh   |


1. Use a USB flashing tool to flash ISOs to USB(s)
    * [Rufus](https://rufus.ie/) - Windows
    * [balena Etcher](https://www.balena.io/etcher/) - MacOS
    * [dd](https://man7.org/linux/man-pages/man1/dd.1.html) - Linux and MacOS

1. `dd` method:

  * Get list of disks to flash to using `lsblk`

  ```shell
  # OF needs to match the device you want to flash to (this will overwrite)
  # IF needs to match the ISO you want to flash
  sudo dd if=./iso-outputs/cluster-1.iso of=/dev/sda status=progress
  ```

## NOTES
* USB does not have a stop method, it reboots after completing. This can re-start the installation process.
* Default username: `abm-admin`
* If not supplied, passwords are randomly generated and diplayed at the completion of the build. There is NO method to recover, so save the password. Future option will include pushing to a Google Secret Manager
* Default to 1 ISO replica, change with `-n X` (number). Multiple ISOs speeds up install by automatically setting hostnames
