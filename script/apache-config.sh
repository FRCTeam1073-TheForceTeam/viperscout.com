#!/bin/bash

set -e

SERVER_NAME=${SERVER_NAMES%% *}
SERVER_ALIASES=${SERVER_NAMES#* }
DOCUMENT_ROOT=`pwd`/www
DOCUMENT_ROOT=${DOCUMENT_ROOT/#\/c\//C:\/}
APACHE_SITE_NAME="viperscout"
HTTPS_INCLUDE="include/oster-ssl.conf"

if [[ `hostname -f ` == *osteraws.ostermiller.org ]]
then
	SERVER_NAME=viperscout.com
    HTTPS=0
else
	SERVER_NAME="viperscout.`hostname -f`"
    HTTPS=1
fi

TMPCONF=`mktemp /tmp/$APACHE_SITE_NAME-XXXXXXXXXX.conf`

APACHE_DIR=""
if [ -e /etc/apache2 ]
then
    APACHE_DIR=/etc/apache2
elif [ -e /c/xampp/apache/conf ]
then
    APACHE_DIR=/c/xampp/apache/conf
fi

if [ "z$APACHE_DIR" == "z" ]
then
    echo "Apache conf directory not found."
    exit 1
fi

APACHE_DIR_CONF=$APACHE_DIR
APACHE_DIR_CONF=${APACHE_DIR_CONF/#\/c\//C:\/}

if [ $HTTPS == 1 ]
then
    echo '<VirtualHost *:80>' > $TMPCONF
    echo "	Servername $SERVER_NAME" >> $TMPCONF
    echo "	ServerAlias *.$SERVER_NAME" >> $TMPCONF
    echo "	Redirect / https://$SERVER_NAME/" >> $TMPCONF
    echo '</VirtualHost>' >> $TMPCONF
fi
if [ $HTTPS == 1 ]
then
    echo '<VirtualHost *:443>' >> $TMPCONF
else
    echo '<VirtualHost *:80>' >> $TMPCONF
fi
echo "	Servername www.$SERVER_NAME" >> $TMPCONF
echo "	ServerAlias *.$SERVER_NAME" >> $TMPCONF
if [ $HTTPS == 1 ]
then
    echo "	Include $HTTPS_INCLUDE" >> $TMPCONF
fi
echo "	Redirect / https://$SERVER_NAME/" >> $TMPCONF
echo '</VirtualHost>' >> $TMPCONF
if [ $HTTPS == 1 ]
then
    echo '<VirtualHost *:443>' >> $TMPCONF
else
    echo '<VirtualHost *:80>' >> $TMPCONF
fi
echo "	Servername $SERVER_NAME" >> $TMPCONF
if [ $HTTPS == 1 ]
then
    echo "	Include $HTTPS_INCLUDE" >> $TMPCONF
fi
echo "	DocumentRoot $DOCUMENT_ROOT" >> $TMPCONF
echo "	<Directory $DOCUMENT_ROOT/>" >> $TMPCONF
echo '		AllowOverride All' >> $TMPCONF
echo '		Require all granted' >> $TMPCONF
echo '	</Directory>' >> $TMPCONF
echo '</VirtualHost>' >> $TMPCONF

SUDO=""
if which sudo &> /dev/null
then
  SUDO=sudo
fi

$SUDO mkdir -p $APACHE_DIR/sites-available/
$SUDO mkdir -p $APACHE_DIR/sites-enabled/

RELOAD_NEEDED=0
$SUDO touch $APACHE_DIR/sites-available/$APACHE_SITE_NAME.conf
$SUDO chmod a+r $APACHE_DIR/sites-available/$APACHE_SITE_NAME.conf
if ! cmp $TMPCONF $APACHE_DIR/sites-available/$APACHE_SITE_NAME.conf >/dev/null 2>&1
then
    $SUDO cp -v $TMPCONF $APACHE_DIR/sites-available/$APACHE_SITE_NAME.conf
    RELOAD_NEEDED=1
fi
rm -f $TMPCONF

if [ ! -e $APACHE_DIR/sites-enabled/$APACHE_SITE_NAME.conf ]
then
    if which a2ensite &> /dev/null
    then
        $SUDO a2ensite $APACHE_SITE_NAME
    else
        $SUDO ln -s $APACHE_DIR/sites-available/$APACHE_SITE_NAME.conf $APACHE_DIR/sites-enabled/$APACHE_SITE_NAME.conf
    fi
    RELOAD_NEEDED=1
fi

if [ -e $APACHE_DIR/sites-enabled/000-default.conf ]
then
    $SUDO a2dissite 000-default
    RELOAD_NEEDED=1
fi

if which a2enmod &> /dev/null
then
    for mod in headers.load rewrite.load cgid.load alias.load
    do
        if [ ! -e $APACHE_DIR/mods-enabled/$mod ]
        then
            $SUDO a2enmod $mod
            RELOAD_NEEDED=1
        fi
    done
else
    sed -i -E 's/^\#(.*((mod_headers\.so)|(mod_rewrite\.so)|(mod_cgi\.so)|(mod_alias\.so)))$/\1/g' $APACHE_DIR/httpd.conf
fi

if [ -e /c/xampp/apache/conf/httpd.conf ]
then
    perl -i -pe 'BEGIN { $/=undef } s/\<Directory \"C\:\/xampp\/htdocs\"\>.*?\<\/Directory\>/Include conf\/sites-available\/\*\.conf/gs' /c/xampp/apache/conf/httpd.conf
    RELOAD_NEEDED=1
fi

if [ "$RELOAD_NEEDED" == "1" ]
then
    if which service &> /dev/null
    then
        $SUDO service apache2 reload
        echo "Webserver configuration reloaded"
    elif [ -e /c/xampp/xampp_stop.exe ]
    then
        /c/xampp/xampp_stop.exe || true
        /c/xampp/xampp_start.exe
        echo "Webserver configuration reloaded"
    else
        echo "Could not find a command to restart web server"
        exit 1
    fi
fi

if [ -e /c/xampp/perl/bin/perl.exe ]
then
    find www/ -name *.cgi -exec sed -E -i 's|^#!/usr/bin/perl|#!C:/xampp/perl/bin/perl.exe|g' {} \;
else
    find www/ -name *.cgi -exec sed -E -i 's|^#!C:/xampp/perl/bin/perl.exe|#!/usr/bin/perl|g' {} \;
fi
