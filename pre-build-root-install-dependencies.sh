#!/bin/bash

apt-get update
apt-get install -y --force-yes sed wget cvs subversion git bzr coreutils \
		unzip bzip2 tar gzip cpio gawk python patch diffstat make \
		build-essential gcc g++ desktop-file-utils chrpath autoconf automake \
		libgl1-mesa-dev libglu1-mesa-dev libsdl1.2-dev texi2html texinfo \
		realpath

# Get latest repo script and install it in PATH (use our mirror of repo)
test -d /usr/local/bin || mkdir -p /usr/local/bin
wget -cq --no-check-certificate "http://android.git.linaro.org/gitweb?p=tools/repo.git;a=blob_plain;f=repo;hb=refs/heads/stable" -O /usr/local/bin/repo
chmod a+x /usr/local/bin/repo
