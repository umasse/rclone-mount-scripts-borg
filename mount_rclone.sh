#!/bin/bash

# Set default values for optional parameters
max_attempts=5

# Define the usage message
usage="Usage: $0 --mount-folder <folder> --remote-name <name> [--max-attempts <attempts>]

Mounts a remote drive using Rclone.

Required arguments:
  --mount-folder, -m   The folder where the remote drive should be mounted.
  --remote-name, -r    The name of the remote drive to be mounted.

Optional arguments:
  --max-attempts, -a   The maximum number of times the 'rclone mount' command should be attempted. Default is 5.
  --help, -h           Display this help message.

Example:
  mount_rclone.sh -m ~/Mount/ -r BoxUM"

# Parse command line arguments
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -m|--mount-folder)
        mount_folder="$(realpath $2)/"
        echo "mount_folder: ${mount_folder}"
        shift # past argument
        shift # past value
        ;;
        -r|--remote-name)
        remote_name="$2"
        shift # past argument
        shift # past value
        ;;
        -a|--max-attempts)
        max_attempts="$2"
        shift # past argument
        shift # past value
        ;;
        -h|--help)
        echo "$usage"
        exit 0
        ;;
        *)    # unknown option
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Check if mandatory parameters are set
if [ -z "$mount_folder" ] || [ -z "$remote_name" ]; then
    echo "$usage"
    exit 1
fi

function is_mounted_with_rclone {
    if mount | grep -q "${remote_name}.*on ${mount_folder}${remote_name}.*rclone"; then
        return 0
    else
        return 1
    fi
}

# Call the function to check if the directory is mounted with rclone.
if is_mounted_with_rclone; then
    echo "${mount_folder}${remote_name} is mounted with rclone."
else
    echo "${mount_folder}${remote_name} is not mounted with rclone."
    attempt=1
    while [ $attempt -le $max_attempts ]
    do
        echo "Mounting... Attempt $attempt"
        mkdir -p ${mount_folder}${remote_name}
        daemonize -c ${mount_folder} -e /tmp/${remote_name}-stderr -o /tmp/${remote_name}-stdout -p /tmp/${remote_name}-pid -l /tmp/${remote_name}-lock /usr/bin/rclone mount ${remote_name}: ${mount_folder}${remote_name} --vfs-cache-mode full --vfs-cache-max-age 72h --vfs-cache-max-size 10G -v
        sleep 5s
        if is_mounted_with_rclone; then
            echo "${mount_folder}${remote_name} is now mounted with rclone."
            exit 0
        else
            echo "Failed to mount ${mount_folder}${remote_name} with rclone. Sleeping for $((attempt * 5))s"
            sleep $((attempt * 5))s # Wait for 5 seconds before trying again.
            attempt=$(( attempt + 1 ))
        fi
    done
    echo "Failed to mount ${mount_folder}${remote_name} with rclone after $max_attempts attempts."
    exit 1
fi
