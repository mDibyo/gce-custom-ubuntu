#!/bin/bash

echo Installing required tools
apt-get install -y aptitude
aptitude install squashfs-tools genisoimage

echo Setting up working directory
mkdir ~/livecdtmp
mv ubuntu-11.04-desktop-amd64.iso ~/livecdtmp/
cd ~/livecdtmp

echo Extracting contents of image
mkdir mnt
mount -o loop ubuntu-9.04-desktop-i386.iso mnt
mkdir extract-cd
rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

unsquashfs mnt/casper/filesystem.squashfs
mv squashfs-root edit