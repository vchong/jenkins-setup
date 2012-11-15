#!/bin/bash

if [ -d build/downloads ]; then
	pushd build/downloads
		ls -l
		rm *.done
		rm -rf git2 svn cvs bzr # we publish files not SCM dirs
	popd
fi

if [ -d build/sstate-cache/ ]; then
	pushd build/sstate-cache/
		rm -f `find . -type l`
		ls -l
		mv */* .
		ls -l
		mv Ubuntu-*/*/* .
		ls -l
		rm -rf ?? Ubuntu-*
	popd
fi
