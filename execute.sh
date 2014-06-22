#!/bin/bash

echo Installing required tools
apt-get install -y aptitude
aptitude install squashfs-tools genisoimage

echo Create
mkdir ~/livecdtmp
