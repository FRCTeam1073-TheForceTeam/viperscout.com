#!/bin/sh

set -e

./script/software-install.sh
./script/cgi-setup.sh
./script/apache-config.sh
