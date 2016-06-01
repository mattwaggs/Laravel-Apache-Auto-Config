#!/bin/bash

# check to see if project name was supplied 
if [ "$#" -ne 1 ]
then
	echo 'project name required. Usage: auto-config-laravel <my-application-name>'
	exit 1
fi

# ensure project name is a directory
if [ ! -d "$1" ]
then
	echo "$1 is not a directory"
	exit 1
fi

# set up helper vars
projName=$(basename $1)
fullPath=$(readlink -f $1)
documentRoot="${fullPath}/public"

# get timestamp to add to filename to ensure uniqueness in apache2/sites-available
date=$(date +%s) 
fileName="${projName}_${date}"


# if reached this point, assume supplied project name was is good
echo "Auto configuring apache2 for laravel project: $projName"

# set the permissions on the laravel folder
echo "Changing ${projName}'s group permissions"

chgrp -R www-data $1
result=$?

if [ $result -ne 0 ] 
then
	echo 'Could not modify project folder group. Check permissions?'
	exit 1
fi

# successfully changed project folder group ownership

echo "Creating virtual host file for ${projName}"

# now create an new virtual hostfile and put it in /etc/apache2/sites-available
# and delete all the currently enabled sites and enable only this site
cat > "./${fileName}.conf" <<_EOF_

# Auto Generated with mattwaggs' laravel apache config helper
# For details visit https://github.com/mattwaggs/laravel-apache-auto-config

<Directory $fullPath>
	Options Indexes FollowSymLinks
	AllowOverride All 
	Require all granted
</Directory>
<VirtualHost *:80>
	# ServerName localhost
	DocumentRoot $documentRoot
	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

_EOF_
result=$?

if [ $result -ne 0 ]
then
	echo "Could not create virtual host file at /etc/apache2/sites-available/${fileName}.conf"
	exit 1
fi

# remove other virtual host files
# find /etc/apache2/sites-enabled/ -type l -exec rm {} \;
echo "Removing all other enabled virtual hosts"
find /etc/apache2/sites-enabled/ -type l | 
while IFS= read -r lnkName;
do
	# Delete only the sym links that lead to sites-available
	if [ $(readlink -f "$lnkName") = "/etc/apache2/sites-available/$(basename $lnkName)" ];
	then
		rm -- "$lnkName"
	fi
done


# put virtual host file in place

mv "./${fileName}.conf" /etc/apache2/sites-available/ >/dev/null 2>&1
result=$?

if [ $result -ne 0 ]
then
	echo "Failed to move ${fileName}.conf to destination /etc/apache2/sites-available/"
	rm "./${fileName}.conf"
	exit 1
fi

# move was successfull
# enable the site and restart apache2 service

cd /etc/apache2
a2ensite ${fileName} >/dev/null 2>&1
result=$?

if [ $result -ne 0 ]
then
	echo "Failed to enable site ${fileName}.conf. Try manually enabling it."
	exit 1
fi

# restart the apache2 service
echo 'Restarting apache2 service'
service apache2 restart >/dev/null 2>&1
result=$?

if [ $result -ne 0 ]
then
	echo "Failed to restart apache2 service"
	exit 1
fi

printf "\nCreated virtual host ${fileName}\n"
