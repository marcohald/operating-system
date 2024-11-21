#!/bin/bash
set -e

#!/bin/bash

# Define variables
DISK_IMAGE="sshkey.img"
DISK_SIZE_MB=10
MOUNT_POINT="$HOME/mnt/config"
LOOP_DEVICE=$(sudo losetup -f)

# Function for cleanup
cleanup() {
    if [ -n "$LOOP_DEVICE" ]; then
        echo "Unmounting the partition..."
        sudo umount "$MOUNT_POINT" 2>/dev/null
        echo "Detaching loop device..."
        sudo losetup -d "$LOOP_DEVICE" 2>/dev/null
    fi
    echo "Cleaning up..."
    [ -d "$MOUNT_POINT" ] && rmdir "$MOUNT_POINT"
}

# Set trap to cleanup on exit or error
trap cleanup EXIT

if [ -f $DISK_IMAGE ] ; then
    rm $DISK_IMAGE
fi
# Create a blank disk image
echo "Creating a blank disk image of ${DISK_SIZE_MB}MB..."
dd if=/dev/zero of=$DISK_IMAGE bs=1M count=$DISK_SIZE_MB

# Setup loop device
echo "Setting up loop device..."
sudo losetup -fP $DISK_IMAGE

# Get the loop device name
LOOP_DEVICE=$(losetup -l | grep "$DISK_IMAGE" | awk '{print $1}')

# Partition the disk image
echo "Creating a FAT32 partition..."
(
echo n    # new partition
echo p    # primary
echo 1    # partition number
echo      # default - start at first sector
echo      # default - end at last sector
echo t    # change partition type
echo b    # W95 FAT32
echo w    # write changes
) | sudo fdisk $LOOP_DEVICE

# Format the partition as FAT32
echo "Formatting the partition as FAT32..."
sudo mkfs.fat -F 32 -n CONFIG ${LOOP_DEVICE}p1

# Create mount point
echo "Creating mount point at $MOUNT_POINT..."
mkdir -p $MOUNT_POINT

# Mount the partition
echo "Mounting the partition..."
sudo mount -o umask=000 ${LOOP_DEVICE}p1 $MOUNT_POINT



# Check if the public key exists and copy it
if [ -f ~/.ssh/id_rsa.pub ]; then
    # Copy the public key to authorized_keys
    cat ~/.ssh/id_rsa.pub > "$MOUNT_POINT/authorized_keys"
else
    echo "Public key not found at ~/.ssh/id_rsa.pub. Exiting."
    exit 1
fi


# Display authorized_keys content
echo "Display authorized_keys content..."
cat $MOUNT_POINT/authorized_keys

# Unmount and detach loop device
echo "Unmounting the partition..."
sudo umount $MOUNT_POINT
echo "Detaching loop device..."
sudo losetup -d $LOOP_DEVICE

# Clean up
echo "Cleaning up..."
rmdir $MOUNT_POINT

echo "Disk image creation complete: $DISK_IMAGE"

