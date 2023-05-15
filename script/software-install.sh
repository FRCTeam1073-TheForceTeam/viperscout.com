#!/bin/bash

set -e

if which apt &> /dev/null
then
	# When changing this list of installed software
	# PLEASE ALSO UPDATE the similar list in Dockerfile
	sudo apt-get install -y \
		apache2 \
		apache2-utils \
		git \
		;
fi
