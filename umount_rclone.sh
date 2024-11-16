#!/bin/bash

# Define the usage message
usage="Usage: $0 --mount-folder <folder> --remote-name <name> [--max-attempts <attempts>] [--detach] [--detach-wait <seconds>] [--log-file <file>] [--initial-wait <seconds>] [--help]

Unmounts a remote Rclone drive using umount.

Required arguments:
  --mount-folder, -m   The folder where the remote drive should be unmounted.
  --remote-name, -r    The name of the remote drive to be unmounted.

Optional arguments:
  --max-attempts, -a   The maximum number of times the 'umount' command should be attempted. Default is 5.
  --detach, -d          Detach the unmount process and run it in the background.
  --detach-wait, -W    The number of seconds to wait before attempting to unmount when detaching. Default is 30.
  --log-file, -l        The file to log output to. If not specified, output will be sent to the console.
  --initial-wait, -w    The number of seconds to wait before attempting to unmount. Default is 0.
  --help, -h           Display this help message.

Example:
  umount_rclone.sh -m ~/Mount/ -r BoxUM"

# Set default values for optional parameters
max_attempts=5
detach=false
initial_wait=0
detach_wait=30

# Parse command line arguments
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -m|--mount-folder)
        mount_folder="$2"
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
        -d|--detach)
        detach=true
        shift # past argument
        ;;
        -W|--detach-wait)
        detach_wait="$2"
        shift # past argument
        shift # past value
        ;;
        -l|--log-file)
        log_file="$2"
        shift # past argument
        shift # past value
        ;;
        -w|--initial-wait)
        initial_wait="$2"
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

# Redirect output to log file if specified
if [ -n "$log_file" ]; then
    exec > "$log_file" 2>&1
fi

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

function wait_for_file_update {
    while true; do
        last_two_lines=$(tail -n 2 "/tmp/${remote_name}-stderr")
        line1=$(echo "$last_two_lines" | sed -n '1p')
        line2=$(echo "$last_two_lines" | sed -n '2p')
        if [[ $line1 == *"in use 0, to upload 0, uploading 0"* && $line2 == *"in use 0, to upload 0, uploading 0"* ]]; then
            echo "Mount is not busy"
            echo "${last_two_lines}"
            break
        else
            echo "Mount is busy. Waiting..."
            echo "${last_two_lines}"
            sleep 60s # Wait for 1 minute before checking again.
        fi
    done
}

function unmount_rclone {
    echo "Unmounting..."
    attempt=1
    while [ $attempt -le $max_attempts ]
    do
        umount ${mount_folder}${remote_name}
        if ! is_mounted_with_rclone; then
            echo "${mount_folder}${remote_name} is now unmounted."
            exit 0
        else
            echo "Failed to unmount ${mount_folder}${remote_name}. Attempt $attempt of $max_attempts."
            attempt=$(( attempt + 1 ))
            sleep 5s # Wait for 5 seconds before trying again.
        fi
    done
    echo "Failed to unmount ${mount_folder}${remote_name} after $max_attempts attempts."
    exit 1
}

# Call the function to check if the directory is mounted with rclone.
if is_mounted_with_rclone; then
    echo "${mount_folder}${remote_name} is mounted with rclone."
    if [ $initial_wait -gt 0 ]; then
        echo "Waiting $initial_wait seconds before attempting to unmount..."
        sleep $initial_wait
    fi
    echo "Waiting for file update..."
    if $detach; then
        if [ -z "$log_file" ]; then
            log_file="/tmp/${remote_name}-`date +%Y-%m-%d-%H-%M-%S`-detach.log"
            echo "Logging output to $log_file"
        fi
        nohup "$0" --log-file "$log_file" --mount-folder "$mount_folder" --remote-name "$remote_name" --initial-wait "$detach_wait" &
        echo "Unmount process detached. Exiting..."
        exit 0
    else
        wait_for_file_update
        unmount_rclone
    fi
else
    echo "${mount_folder}${remote_name} is not mounted with rclone."
fi