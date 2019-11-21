#!/bin/bash
version="$1"

# Variables declared.
application="magento"
# pre="     \e[34m[Docker]\e[39m"
pre=" "
# This is the root of the   - [Docker]-client folder.
root="/shared/httpd"
mkdir ~/.composer
touch ~/.composer/auth.json
system_files_dir="${root}/${version}.${application}/htdocs"
db="${application}_${version//./}"

# URI used for the application itself.
URI="https://${version}.${application}.loc"

zip_file="/shared/httpd/backup/${application}_${version}.zip"

printf "\n##############################################################################\n#\n"
printf "#   Installing Magento \e[32m${version}\e[39m \n#\n"
printf "##############################################################################\n\n"

# Install the unzip if it's not available
if [ $(dpkg-query -W -f='${Status}' unzip 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  printf "${pre} Unzip is not found on your docker container. Intalling it.\n"
  apt-get update &>/dev/null;
  apt-get install unzip &>/dev/null;
  apt-get install zip &>/dev/null;
  printf "${pre} Unzip installation is ended.\n"
fi

# Start Magento installation.
printf "${pre} Starting Magento ${version[@]} installation.\n"

# Checking if system files directory exists for version.
if [ -d ${root}/${version}.${application} ]; then
  printf "${pre} Sytem files ${application} ${version} directory exists. Making sure it's clean.\n"
  rm -rf ${root}/${version}.${application}
fi

printf "${pre} Creating the directories for the ${application} ${version}.\n"
mkdir -p ${system_files_dir}
chmod 777 -fR ${system_files_dir}

if [ -f ${zip_file} ]; then

  ( ./restore.sh ${application} ${version} )

else

  # Release install commands. Based on Magento 1 or 2 the type of install commands determined.
  printf "${pre} Based on Magento 1 or 2 install commands are released.\n"

  if [[ ${version:0:1} == "1" ]]; then
    printf "${pre} Magento 1 - Start installing.\n"
    if [ -f ${root}/n98-magerun.phar ]; then
        printf "${pre} Magerun Detected no need to download it again.\n"
    else
      printf "${pre} Magerun downloading...\n"
      wget https://files.magerun.net/n98-magerun.phar -O ${root}/n98-magerun.phar -q
      # Setting the right permissions for n98-magerun.phar"
      chmod 777 ${root}/n98-magerun.phar
    fi

    cp ${root}/n98-magerun.yaml ~/.n98-magerun.yaml

    ${root}/n98-magerun.phar install \
    --no-interaction \
    --magentoVersionByName="magento-mirror-${version}" \
    --installationFolder="${system_files_dir}" \
    --dbHost="127.0.0.1" \
    --dbUser="root" \
    --dbName="${db}" \
    --installSampleData=no \
    --useDefaultConfigParams=yes \
    --baseUrl="${URI}"

    # Create a backup
    ( ./backup.sh ${application} ${version} )

  else

    printf "${pre} Magento 2 - Start installing.\n"

    echo -e "{
        \"github-oauth\": {
          \"github.com\": \"e02418fe641c26db0b3b7aaab7b1df925474978e\"
        },
        \"http-basic\":
         {
           \"repo.magento.com\":
           {
             \"username\": \"e3594ea2622c773ab41f0c53b3dd6e9c\",
             \"password\": \"dc19cd9fac7b745bca007132dbfebb02\"
           }
         }
     }" > ~/.composer/auth.json

    if [ -f ${root}/n98-magerun2-${version}.phar ]; then
      printf "${pre} Magerun 2 - Detected no need to download it again.\n"
      printf "${pre} Updating magerun2..."
      ${root}/n98-magerun2-${version}.phar self-update
    else
      printf "${pre} Magerun 2 - downloading...\n"
      wget https://files.magerun.net/n98-magerun2-${version}.phar -O ${root}/n98-magerun2-${version}.phar -q
      # Setting the right permissions for the n98-magerun2.phar"
      chmod 777 ${root}/n98-magerun2-${version}.phar
    fi

    cp ${root}/n98-magerun2.yaml ~/.n98-magerun2.yaml

    printf "${pre} Magerun 2 - Run n98-magerun2.phar install command\n"

    ${root}/n98-magerun2-${version}.phar install \
    --no-interaction \
    --dbHost="127.0.0.1" \
    --dbUser="root" \
    --dbName="${db}" \
    --installSampleData=yes \
    --useDefaultConfigParams=yes \
    --magentoVersionByName="magento-ce-${version}" \
    --installationFolder="${system_files_dir}" \
    --baseUrl="${URI}" \
    --skip-root-check

    chmod 777 -fR ${system_files_dir}

    # Function to compare versions.
    function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

    # Version to compare needs to be hardcoded.
    command_line_version="2.2.0"

    # Depending on the version we have to use a slightly different install command.
    if version_gt ${version} ${command_line_version} || [ ${command_line_version} == ${version} ] ; then
      printf "${pre} Magerun 2 - Using install command for 2.2.0 >\n"
      ${system_files_dir}/bin/magento setup:static-content:deploy -f
    else
      printf "${pre} Magerun 2 - Using install command for 2.2.0 <\n"
      ${system_files_dir}/bin/magento setup:static-content:deploy
    fi

    # Turn off static sign
    mysql -h 127.0.0.1 -e 'use '${db}'; INSERT INTO `core_config_data` (`config_id`, `scope`, `scope_id`, `path`, `value`) VALUES (NULL, "default", 0, "dev/static/sign", 0);'
    printf "${pre} Clearing the config cache. \n"
    ${system_files_dir}/bin/magento cache:clean config

    chmod 777 -fR ${system_files_dir}

    printf "${pre} Enabling display errors in Magento 2.x\n"
    cp ${system_files_dir}/pub/errors/local.xml.sample ${system_files_dir}/pub/errors/local.xml

    #installing sample database
    printf "Installing magento sample data"
    ${system_files_dir}/bin/magento sampledata:deploy

    printf "${pre} Create the backup\n"
    # Create a backup
    ( ./backup.sh ${application} ${version} )

  fi

fi

printf "${pre} Installation for ${application} version ${version} is completed.\n\n"
