#!/bin/bash

if [ -d build/downloads ]; then
	pushd build/downloads
		rm *.done
		rm -rf git2 svn cvs bzr # we publish files not SCM dirs
	popd
fi

if [ -d build/sstate-cache/ ]; then
	pushd build/sstate-cache/
		rm -f `find . -type l`
		mv */* .
		mv Ubuntu-*/*/* .
		rm -rf ?? Ubuntu-*
	popd
fi
