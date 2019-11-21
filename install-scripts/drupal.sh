#!/bin/bash
#Unified installation for drupal 7 and 8
version="$1"

# Variables declared.
application="drupal"
pre="     \e[34m[Docker]\e[39m"
pre_err="     \e[31m[Error]\e[39m "

# Directories
root="/shared/httpd"
system_files_dir="${root}/${version}.${application}/htdocs"

# Cache direcory
cache="/shared/cache"

# WP zip file
file="${version}.zip"
unzip_folder="${application}-${version}"
file_url="https://github.com/drupal/drupal/archive/${file}"
http_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' ${file_url})

# Database related.
db="${application}_${version//./}"
db_user="root"
db_host="127.0.0.1"

printf "\n############################################################################\n#\n"
printf "#   Installing ${application} \e[32m${version}\e[39m \n#\n"
printf "##############################################################################\n\n"

# Install the unzip if it's not available
if [ $(dpkg-query -W -f='${Status}' unzip 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  printf "${pre} unzip is not found on your docker enviroment. Intalling it.\n"
  apt-get update &>/dev/null;
  apt-get install unzip &>/dev/null;
  printf "${pre} Unzip installation is ended.\n"
fi

# Creating the cahce dir
if [ ! -d ${cache} ]; then
  mkdir ${cache}
  chmod -fR 777 ${cache}
fi

# Checking if system files directory exists for version.
if [ -d ${root}/${version}.${application} ]; then
  printf "${pre} Sytem files ${application} ${version} directory exists. Making sure it's clean.\n"
  rm -rf ${root}/${version}.${application}
fi

printf "${pre} Creating the directories for the ${application} ${version}.\n"
mkdir -p ${system_files_dir}
chmod 777 -fR ${system_files_dir}

# Start downloading Joomla version.
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
    printf "${pre_err} The ${application} ${version} not available. Cannot download it. HTTP-STATUS: $http_status \n"
    printf "${pre} Since download is not available we're deleting the direcory ${root}/${version}.${application} \n"
    rm -rf ${root}/${version}.${application}
  fi
fi

if [ -f ${cache}/${file} ]; then
  # Extracting downloaded zip into system files directory.
  unzip -qq ${cache}/${file} -d ${system_files_dir}
  printf "${pre} Copying the unzipped folder to the right directory.\n"
  cp -rp ${system_files_dir}/${unzip_folder}/. ${system_files_dir}
  rm -fR ${system_files_dir}/${unzip_folder}
  chmod 777 -fR ${system_files_dir}
fi

if [[ ${version:0:1} == "8" ]]; then
  printf "${pre} Installing composer...\n"
  ( cd ${system_files_dir} && composer install --quiet &>/dev/null )

fi

printf "${pre} Create the settings.php\n"
( cp ${system_files_dir}/sites/default/default.settings.php ${system_files_dir}/sites/default/settings.php )
chmod 777 ${system_files_dir}/sites/default/settings.php

( cd ${system_files_dir} && php -d display_errors=0 -d mbstring.http_input=pass /usr/local/bin/drush site-install --quiet \
     --yes \
     --db-url="mysql://root@127.0.0.1/${db}" \
     --account-name=admin \
     --account-pass="Admin123" \
     --site-name="Drupal ${version}" \
     standard \
     install_configure_form.update_status_module="array(FALSE,FALSE)" &>/dev/null )

chmod 777 -fR ${system_files_dir}

printf "${pre} Installation for ${application} version ${version} is completed.\n\n"
