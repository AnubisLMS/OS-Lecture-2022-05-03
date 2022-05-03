#!/bin/bash

# Set the path (this carries down to the container)
export PATH=/bin:/sbin:/usr/bin

# Make mounts private. Otherwise the mounts will be
# visible to the rest of the system
mount --make-rprivate /
cd /mnt

# Grab the alpine docker image filesystem
mkdir alpine
CID=$(docker run -d alpine true)
docker export $CID | tar -C alpine -xf-

cd alpine

# Create a file at the root of the container filesystem
# so that we can easily check to see if we are in the
# container
touch THIS_IS_THE_CONTAINER

# Test out the alpine linux filesystem (just make sure it works)
sudo chroot alpine /bin/sh

# Put me in all the namespaces except for user
sudo unshare --mount --uts --ipc --net --pid --fork bash

# Change hostname of container
hostname container
exec bash

# Only see processes in container
# PIDs will be off (not start at 1)
ps aux

# Mount a proc filesystem
mount -t proc none /proc

# Fixes pids from being off. They will
# start at 1
ps aux

# Go into container
cd alpine

# Do pivot_root to put me on the container
# filesystem
## Need to make the container directory a bind mount! ##
mkdir oldroot
pivot_root . oldroot

# Show that all the mounts from host system
# is still visible
mount

# Unmount everything (including the proc we mounted)
umount -a

# Mount a new proc filesystem
mount -t proc none /proc

# Unmount old root
umount -l /oldroot

# Really go into container. This is basically handing off
# execution to the container. Before we were running bash
# from the host
exec chroot / sh
