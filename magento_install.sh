#!/bin/bash

# This script can be used to install Magento version 2.0 and up completely command line.
# Version from 1.9.3.7 and older the installer has be be run from the browser. But
# we prepare as much as possible.

# Specify here which version you would like to install.
  version=$1

  # Variables declared.
  application=magento
  zip_file="${application}-${version}.zip"

  # Path variables.
  cache="/shared/cache"

  # This is the root of the docker-client folder.
  root="/shared/httpd"
  system_files_dir="${root}/${version}.${application}/htdocs"
  db="${application}_${version//./}"

  # Database related.
  db_user="root"
  db_password=""
  db_host="127.0.0.1"

  # Binding URL for the etc/hosts.
  url="127.0.0.1   ${version}.${application}.loc"
  # URI used for the application itself.
  URI="http://${version}.${application}.loc"

  # Start downloading Magento version.
  magento_zip_url="https://github.com/OpenMage/magento-mirror/archive/${version}.zip"
  magento2_zip_url="https://github.com/magento/magento2/archive/${version}.zip"

  # Start Magento installation.
  echo "(Docker) Starting Magento ${version[@]} installation."

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


  # Checking if zip file exists. If not we're downloading it.
  echo "Checking if ZIP file exists. If not we're downloading it."
  if [ -f ${cache}/${version}.zip ]; then
      echo "File detected no need to download it again."
  else
      echo "No ZIP file detected for ${application} ${version} we'll start downloading it."
      echo "Checking if ${application} ${version} is available for download. If so, we'll start downloading it."
      if wget --spider ${magento_zip_url} 2>/dev/null ; then
          echo "Skip this for magento 1"
          # echo "Magento 1 detected as input. Downloading ${application} ${version}."
          # wget --no-verbose ${magento_zip_url} -O ${cache}/${version}.zip

      elif wget --spider ${magento2_zip_url} 2>/dev/null ; then
          # echo "Skip this for magento 2"
          echo "Magento 2 detected as input. Downloading ${application} ${version}."
          wget --no-verbose ${magento2_zip_url} -O ${cache}/${version}.zip
          # Extracting downloaded zip into system files directory.

      else
          echo "Download for ${zip_file} not available. Cannot download it."
          echo "Since download is not available we're deleting ${root}/${version}.${application}"
          rm -rf ${root}/${version}.${application}
      fi
  fi

  # Copy and paste system files in version target directory.
  # Magento 1 and 2 have different mappings.
  if [ ${version:0:1} = "1" ]; then
    echo "Skip this for magento 1"
    # # Extracting downloaded zip into system files directory.
    # echo "Extracting zip file to temp directory."
    # unzip -qq ${cache}/${version}.zip -d ${system_files_dir}
    # echo "Magento 1 detected. Copying system files in correct directory."
    # cp -rp ${system_files_dir}/${application}-mirror-${version}/. ${system_files_dir}
    # rm -fR ${system_files_dir}/${application}-mirror-${version}
  else
    # echo "Skip this for magento 2"
    echo "Extracting zip file to temp directory."
    unzip -qq ${cache}/${version}.zip -d ${system_files_dir}
    echo "Magento 2 detected. Copying system files in correct directory."
    cp -rp ${system_files_dir}/${application}2-${version}/. ${system_files_dir}
    rm -fR ${system_files_dir}/${application}2-${version}
  fi

  # Setting permissions for system files directory.
  chmod 777 -fR ${system_files_dir}

  # Release install commands. Based on Magento 1 or 2 the type of install commands determined.
  # Magento 1 and 2 have different install commands.
  echo "(Docker) Based on Magento 1 or 2 install commands are released."
  if [[ ${version:0:1} = "1" ]]
  then
    echo "(Docker) Magento 1 detected. Releasing install commands. magentoVersionByName=magento-mirror-${version}"

    # TODO CHECK IF A NEW VERSION IS OUT THAN REDOWNLOAD
    if [ -f ${root}/n98-magerun.phar ]; then
        echo "(Docker) File detected no need to download it again."
    else
      echo "(Docker) Downloading the newest magerun"
      wget https://files.magerun.net/n98-magerun.phar -O ${root}/n98-magerun.phar
      echo "(Docker) Setting the right permissions for n98-magerun.phar"
      chmod 777 ${root}/n98-magerun.phar
    fi

    ${root}/n98-magerun.phar install \
    --no-interaction \
    --magentoVersionByName="magento-mirror-${version}" \
    --installationFolder="${system_files_dir}" \
    --dbHost="${db_host}" \
    --dbUser="${db_user}" \
    --dbName="${db}" \
    --installSampleData=no \
    --useDefaultConfigParams=yes \
    --baseUrl="${URI}"

  else
    echo "(Docker) Magento 2 detected. Releasing install commands."

    # # TODO CHECK IF A NEW VERSION IS OUT THAN REDOWNLOAD
    # if [ -f ${root}/n98-magerun2.phar ]; then
    #     echo "File detected no need to download it again."
    # else
    #   echo "Downloading the newest magerun2"
    #   wget https://files.magerun.net/n98-magerun2.phar -O ${root}/n98-magerun2.phar
    #   echo "Setting the right permissions for n98-magerun2.phar"
    #   chmod 777 ${root}/n98-magerun2.phar
    # fi
    #
    # ${root}/n98-magerun2.phar install \
    # --no-interaction \
    # --dbHost="${db_host}" \
    # --dbUser="${db_user}" \
    # --dbName="${db}" \
    # --installSampleData=no \
    # --useDefaultConfigParams=yes \
    # --magentoVersionByName="magento-ce-${version}" \
    # --installationFolder="${system_files_dir}" \
    # --baseUrl="${URI}"


    # Magento needs composer in order to be installed.
    echo "(Docker) Installing composer first."
    # Creating auth.json file.
    touch ${system_files_dir}/auth.json

    echo -e "{\"http-basic\": {\"repo.magento.com\": {\"username\": \"9ac34099786fb9087f37c2d2b24ed845\", \"password\": \"a93f6eb6b272dc5316bae6311b2486aa\"}}}" > ${system_files_dir}/auth.json

    echo "(Docker) Install dependencies with Composer. This can take a while!"

    composer --quiet --no-interaction install -d ${system_files_dir}

    # Setting permissions for system files directory.
    chmod 777 -fR ${system_files_dir}/var

    if [ -f ${system_files_dir}/php.ini.sample ]; then
      # We need the configuration of the Magento shipped php.ini file.
      cp ${system_files_dir}/php.ini.sample ${system_files_dir}/php.ini
    fi

    php ${system_files_dir}/bin/magento setup:install \
    --backend-frontname=admin \
    --base-url=${URI} \
    --db-host=${db_host} \
    --db-name=${db} \
    --db-user=${db_user} \
    --admin-firstname=John \
    --admin-lastname=Doe \
    --admin-email=no-reply@patchman.co \
    --admin-user=admin \
    --admin-password=Admin123 \
    --language=en_US \
    --currency=EUR \
    --timezone=Europe/Amsterdam

    # Function to compare versions.
    function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

    # Version to compare needs to be hardcoded.
    command_line_version=2.2.0

    # Depending on the version we have to use a slightly different install command.
    if version_gt ${version} ${command_line_version} || [ "${command_line_version}" = "${version}" ] ; then
        echo "(Docker) Using install command for 2.2.0 >"
        ${system_files_dir}/bin/magento setup:static-content:deploy -f
      else
        echo "(Docker) Using install command for 2.2.0 <"
        ${system_files_dir}/bin/magento setup:static-content:deploy
      fi
      # Turn off static sign
      mysql -h 127.0.0.1 -e 'use '${db}'; INSERT INTO `core_config_data` (`config_id`, `scope`, `scope_id`, `path`, `value`) VALUES (NULL, "default", 0, "dev/static/sign", 0);'
      ${system_files_dir}/bin/magento cache:clean config

  fi

  chmod 777 -fR ${system_files_dir}
  echo "(Docker) Installation for ${application} version ${version} is completed."
  # echo "Visit this url to open the application: ${URI}"
