#!/bin/bash

# This script can be used to install multiple Drupal versions of  8 and 7.


# Specify here which version you would like to install.
  version=$1

  # Variables declared.
  application=drupal
  gzip_file="${application}-${version}.tar.gzip"

  # Path variables.
  cache="/shared/cache"

  # This is the root of the docker-client folder.
  root="/shared/httpd"
  system_files_dir="${root}/${version}.${application}/htdocs"
  db="${application}_${version//./}"

  # Database related.
  mysql="mysql"
  db_user="root"
  db_password=""

  # Binding URL for the etc/hosts.
  url="127.0.0.1   ${version}.${application}.loc"
  # URI used for the application itself.
  URI="http://${version}.${application}.loc"

  # Start downloading Magento version.
  drupal_gz_url="http://ftp.drupal.org/files/projects/drupal-${version}.tar.gz"


  # Start Drupal installation.
  echo "(Docker) Starting Drupal ${version[@]} installation."

  # Checking if system files directory exists for version.
  echo "(Docker) Checking if system files directory exists for ${application} ${version}."
  if [ ! -d ${root}/${version}.${application} ]; then
    echo "(Docker) System files directory does not exists for ${application} ${version}. Creating it."
    mkdir ${root}/${version}.${application}
    mkdir ${system_files_dir}
    echo "(Docker) Setting correct permissions for system files ${application} ${version} directory."
    chmod 777 -fR ${system_files_dir}
  else
    echo "(Docker) Sytem files ${application} ${version} directory exists. Making sure it's clean."
    rm -rf ${root}/${version}.${application}
    mkdir ${root}/${version}.${application}
    mkdir ${system_files_dir}
    echo "(Docker) Setting correct permissions for system files ${application} ${version} directory."
    chmod 777 -fR ${root}/${version}.${application}/
  fi

  echo "Checking if cache directory exists for ${cache}."
  if [ ! -d ${cache} ]; then
    echo "System cache directory does not exists for ${cache}. Creating it."
    mkdir ${cache}
    echo "Setting correct permissions for cache ${cache}/${version}.${application} directory."
    chmod 777 -fR ${cache}
  fi

  # Creating fresh cache directory which could cause otherwise potentially issues.
  echo "Checking if cache directory exists for ${application} ${version}."
  if [ ! -d ${cache}/${version}.${application} ]; then
    echo "System cache directory does not exists for ${cache}/${version}.${application}. Creating it."
    mkdir ${cache}/${version}.${application}
    echo "Setting correct permissions for cache ${cache}/${version}.${application} directory."
    chmod 777 -fR ${cache}/${version}.${application}
  else
    echo "Sytem files ${application} ${version} directory exists."
    echo "Setting correct permissions for cache ${cache}/${version}.${application} directory."
    chmod 777 -fR ${cache}/${version}.${application}
  fi


  # Checking if file exists. If not we're downloading it.
  echo "Checking if gzip file exists. If not we're downloading it."
  if [ -f ${cache}/${version}.tar ]; then
      echo "File detected no need to download it again."
  else
      echo "No ZIP file detected for ${application} ${version} we'll start downloading it."
      echo "Checking if ${application} ${version} is available for download. If so, we'll start downloading it."

      if [ "7.0" = "`echo -e "${version}\n7.0" | sort -V | head -n1`" ]; then
        echo " Downloading ${application} ${version}."
        wget --no-verbose ${drupal_gz_url} -O ${cache}/${version}.tar.gz
        #Extracting downloaded file into the system directory
        tar --strip-components=1 -C  ${system_files_dir} -xf  ${cache}/${version}.tar.gz

      else
          echo "Download for drupal ${version} not available. Cannot download it."
          echo "Since download is not available we're deleting ${root}/${version}.${application}"
          rm -rf ${root}/${version}.${application}
      fi
  fi


  # Setting permissions for system files directory.
  chmod 777 -fR ${system_files_dir}

    # Drupal 8 needs composer in order to be installed.
   if [ ${version:0:1} = "8" ]; then
    cd ${system_files_dir}
    echo "(Docker) Install dependencies with Composer. This can take a while!"

    composer --quiet --no-interaction install -d ${system_files_dir}
    echo "Installing drupal 8 using drush"

    echo "Making sites/default/files writable."

    # (cd ${system_files_dir} && mkdir sites)
    chmod -fR 777 ${system_files_dir}/sites

    # (cd ${system_files_dir}/sites && mkdir default)
    chmod -fR 777 ${system_files_dir}/sites/default

    # (cd ${SYSTEM_FILES_DIR}/sites/default && mkdir files)
    chmod -fR 777 ${system_files_dir}/sites/default/files
    echo "Permissions done!"
   else
    echo "Installing drupal 7 using drush"
    cd ${system_files_dir}
    echo "Making sites/default/files writable."
    mkdir sites
    chmod -fR 777 ${system_files_dir}/sites

    cd ${system_files_dir}/sites && mkdir default
    chmod -fR 777 ${system_files_dir}/sites/default

    cd ${system_files_dir}/sites/default && mkdir files
    chmod -fR 777 ${system_files_dir}/sites/default/files

   fi

    # Setting permissions for system files directory.
    chmod 777 -fR ${system_files_dir}/var

   echo "Copy settings.php into ./sites/default."
   cp -f ${system_files_dir}/sites/default/default.settings.php ${system_files_dir}/sites/default/settings.php
   chmod -f 777 ${system_files_dir}/sites/default/settings.php
   php \
    -d display_errors=0 \
    -d mbstring.http_input=pass \
    /usr/local/bin/drush site-install \
        --quiet \
        --yes \
        --db-url="mysql://root@127.0.0.1/${db}" \
        --account-name=admin \
        --account-pass="Admin123" \
        --site-name="Drupal ${version}" \
        standard \
        install_configure_form.update_status_module="array(FALSE,FALSE)"


  chmod 777 -fR ${system_files_dir}
  echo "(Docker) Installation for ${application} version ${version} is completed."
  # echo "Visit this url to open the application: ${URI}"
