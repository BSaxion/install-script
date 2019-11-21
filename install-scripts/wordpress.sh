#!/bin/bash
# This script can be used to install any WordPress version. From 3.7 and up it can be installed commpletely command line.
# Version older than 3.7 CANNOT be installed command line. But this script will prepare as much as possible.
# Specify here which version you would like to install.
version="$1"

# Variables declared.
application="wordpress"
pre="     \e[34m[Docker]\e[39m"

# Directories
root="/shared/httpd"
system_files_dir="${root}/${version}.${application}/htdocs"

#Cache direcory
cache="/shared/cache"

#WP zip file
file="${application}-${version}.zip"
file_url="https://wordpress.org/${file}"
http_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' ${file_url})

# URI used for the application itself.
URI="http://${version}.${application}.loc"

# Database related.
db="${application}_${version//./}"
db_user="root"
db_password=""
db_host="127.0.0.1"

config_file=${system_files_dir}/wp-config.php

printf "\n############################################################################\n#\n"
printf "#   Installing Wordpress \e[32m${version}\e[39m \n#\n"
printf "##############################################################################\n\n"

#Install the unzip if it's not available
if [ $(dpkg-query -W -f='${Status}' unzip 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  printf "${pre} Unzip is not found on your docker container. Intalling it.\n"
  apt-get update &>/dev/null;
  apt-get install unzip &>/dev/null;
  printf "${pre} Unzip installation is ended.\n"
fi

#Creating the cahce dir
if [ ! -d ${cache} ]; then
  mkdir ${cache}
  chmod -fR 777 ${cache}
fi

# Checking if system files directory exists for version.
if [ -d ${root}/${version}.${application} ]; then
  printf "${pre} System files ${application} ${version} directory exists. Making sure it's clean.\n"
  rm -rf ${root}/${version}.${application}
fi

printf "${pre} Creating the directories for the ${application} ${version}.\n"
mkdir -p ${system_files_dir}
chmod 777 -fR ${system_files_dir}

# Start downloading WordPress version.
printf "${pre} Start downloading ${application} ${version}\n"

# Checking if zip file exists. If not we're downloading it.
printf "${pre} Checking if ZIP file exists. If not we're downloading it.\n"
if [ -f ${cache}/${file} ]; then
    printf "${pre} File detected no need to download it again.\n"
else
    printf "${pre} No ZIP file detected for ${application} ${version} we'll start downloading it.\n"
  if [[ ${http_status:0:1} == "2" ]] || [[ ${http_status:0:1} == "3" ]]; then
    printf "${pre} ${application} is available for download. Downloading ${version} - ${file}.\n"
    wget --no-verbose ${file_url} -O ${cache}/${file} -q
  else
    printf "${pre} Download for ${zip_file} not available. Cannot download it.\n"
    printf "${pre} Since download is not available we're deleting the direcory ${root}/${version}.${application} \n"
    rm -rf ${root}/${version}.${application}
  fi
fi

if [ -f ${cache}/${file} ]; then
  # Extracting downloaded zip into system files directory.
  unzip -qq ${cache}/${file} -d ${system_files_dir}
  printf "${pre} Copying the unzipped folder to the right directory.\n"
  cp -rp ${system_files_dir}/${application}/. ${system_files_dir}
  rm -fR ${system_files_dir}/${application}
  chmod 777 -fR ${system_files_dir}
fi

# Create wp-config.php.
printf "${pre} Creating wp-config.php and configuring it.\n"

if [ -f !${cache}/${file} ]; then
  rm ${config_file}
fi

echo "<?php" > ${config_file}
echo "define('DB_NAME', '${db}');" >> ${config_file}
echo "define('DB_USER', '${db_user}');" >> ${config_file}
echo "define('DB_PASSWORD', '');" >> ${config_file}
echo "define('DB_HOST', '${db_host}');" >> ${config_file}
echo "define('DB_CHARSET', 'utf8');" >> ${config_file}
echo "define('DB_COLLATE', '');" >> ${config_file}
echo "\$table_prefix  = 'wp_';" >> ${config_file}
echo "define('WP_DEBUG', true);" >> ${config_file}
echo "define( 'AUTOMATIC_UPDATER_DISABLED', true );" >> ${config_file}
echo "define( 'WP_AUTO_UPDATE_CORE', true );" >> ${config_file}
echo "if ( !defined('ABSPATH') ) define('ABSPATH', dirname(__FILE__) . '/');" >> ${config_file}
echo "require_once(ABSPATH . 'wp-settings.php');" >> ${config_file}
#This will be allow to install plugins trough the admin dashboard
echo "define('FS_METHOD', 'direct');" >> ${config_file}
#This enables the jetpack dev mode
echo "define( 'JETPACK_DEV_DEBUG', true );" >> ${config_file}

chmod 777 ${config_file}

# WordPress version > 3.7 can be installed command line.
printf "${pre} Checking version in order to determine whether we can install it command line.\n"

# Detect version and execute corresponding actions.
if [[ $version != "3.6" ]] && [[ $version != "3.6.1" ]]; then
  printf "${pre} Starting command line installation of ${application} ${version}.\n"
 ( cd ${system_files_dir} && wp --allow-root core install --path="${system_files_dir}" --url="${URI}" --title="Patchman" --admin_user="admin" --admin_password="Admin123" --admin_email="no-reply@patchman.co" &>/dev/null)

 printf "${pre} Check for updates and update if newer version available.\n"
 ( cd ${system_files_dir} && wp cli update --stable --yes --quiet &>/dev/null)
else
  printf "${pre} Version ${version} detected is older than 3.7 so we cannot install it command line.\n"
  printf "${pre} We have prepared as much as possible. You have to finish installation manually.\n"
  printf "${pre} Open ${URI} in your browser to continue installation.\n"
  printf "${pre} Settings you can use are:\n"
  printf "${pre} Database host: ${db_host}\n"
  printf "${pre} Database Name: ${db}\n"
  printf "${pre} Username: ${db_user}\n"
  printf "${pre} Password: leave blank\n"
fi

printf "${pre} Installation for ${application} version ${version} is completed.\n\n"
