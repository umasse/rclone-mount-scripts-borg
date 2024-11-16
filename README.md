# rclone-mount-scripts

This repository contains two Bash scripts for managing the mounting and unmounting of remote drives using [Rclone](https://rclone.org/).
Original purpose is to use them as pre and post scripts for [Borg](https://www.borgbackup.org/) backups using [Vorta](https://vorta.borgbase.com/).

## Scripts Overview

### 1. `mount_rclone.sh`

This script mounts a remote drive using Rclone. It includes features like automatic retries and daemonized mounting with options for advanced configurations.

#### Usage

```bash
mount_rclone.sh --mount-folder <folder> --remote-name <name> [--max-attempts <attempts>]
```

#### Arguments

- **`--mount-folder`, `-m`** (Required): The local folder where the remote drive will be mounted.
- **`--remote-name`, `-r`** (Required): The name of the remote drive to be mounted.
- **`--max-attempts`, `-a`** (Optional): The maximum number of retries for mounting. Default: `5`.
- **`--help`, `-h`**: Display the usage instructions.

#### Example

```bash
mount_rclone.sh -m ~/Mount/ -r BoxUM
```

#### Features

- Automatically retries mounting up to the specified number of attempts.
- Uses daemonized mounting to run Rclone in the background.
- Configures VFS caching for improved performance.

---

### 2. `umount_rclone.sh`

This script unmounts a previously mounted remote drive. It provides options for background detachment and ensures unmounting is performed only when the drive is not busy.

#### Usage

```bash
umount_rclone.sh --mount-folder <folder> --remote-name <name> [--max-attempts <attempts>] [--detach] [--detach-wait <seconds>] [--log-file <file>] [--initial-wait <seconds>]
```

#### Arguments

- **`--mount-folder`, `-m`** (Required): The local folder where the remote drive is mounted.
- **`--remote-name`, `-r`** (Required): The name of the remote drive to be unmounted.
- **`--max-attempts`, `-a`** (Optional): The maximum number of retries for unmounting. Default: `5`.
- **`--detach`, `-d`** (Optional): Run the unmount process in the background.
- **`--detach-wait`, `-W`** (Optional): Wait time before attempting to unmount when detached. Default: `30` seconds.
- **`--log-file`, `-l`** (Optional): Specify a log file for output. Default: outputs to console.
- **`--initial-wait`, `-w`** (Optional): Initial wait time before starting the unmount process. Default: `0` seconds.
- **`--help`, `-h`**: Display the usage instructions.

#### Example

```bash
umount_rclone.sh -m ~/Mount/ -r BoxUM -d -W 30
```

#### Features

- Ensures that the remote drive is not busy before unmounting.
- Supports background execution with logging.
- Provides detailed retry logic for reliable unmounting.

---

## Prerequisites

- **Rclone**: Install and configure [Rclone](https://rclone.org/downloads/).
- **daemonize**: Ensure `daemonize` is installed for background processes.

---

## Installation

Clone the repository and make the scripts executable:

```bash
git clone <repository-url>
cd rclone-mount-scripts
chmod +x mount_rclone.sh umount_rclone.sh
```

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
