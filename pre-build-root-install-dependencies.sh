#!/bin/bash

apt-get update
apt-get install -y --force-yes sed wget cvs subversion git bzr coreutils \
		unzip bzip2 tar gzip cpio gawk python patch diffstat make \
		build-essential gcc g++ desktop-file-utils chrpath autoconf automake \
		libgl1-mesa-dev libglu1-mesa-dev libsdl1.2-dev texi2html texinfo \
		realpath
