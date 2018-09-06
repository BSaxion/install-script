#!/bin/bash

# This script can be used to install Magento version 2.0 and up completely command line.
# Version from 1.9.3.7 and older the installer has be be run from the browser. But
# we prepare as much as possible.

# Specify here which version you would like to install.
ver=(
"2.2.5"
#"2.2.4"
#"2.2.3"
#"2.2.2"
#"2.2.1"
#"2.2.0"
#"2.1.14"
#"2.1.13"
#"2.1.12"
#"2.1.11"
#"2.1.10"
#"2.1.9"
#"2.1.8"
#"2.1.7"
#"2.1.6"
#"2.1.5"
#"2.1.4"
#"2.1.3"
#"2.1.2"
#"2.1.1"
#"2.1.0"
#"2.0.0"
#"2.0.16"
#"2.0.15"
#"1.9.3.9"
#"1.9.3.8"
#"1.9.3.7"
#"1.9.3.6"
#"1.9.3.4"
#"1.9.3.3"
#"1.9.3.2"
#"1.9.3.1"
#"1.9.3.0"
#"1.9.2.4"
#"1.9.2.3"
#"1.9.2.2"
#"1.9.2.1"
#"1.9.2.0"
 # "1.9.1.1"
)

for version in "${ver[@]}"
do

  # Variables declared.
  application="magento"
  file="${application}-${version}.zip"


  # This is the root of the docker-client folder.
  db="${application}_${version//./}"

  # Database related.
  db_user="root"
  db_password=""
  db_host="127.0.0.1"

  # Binding URL for the etc/hosts.
  url="127.0.0.1   ${version}.${application}.loc"
  # URI used for the application itself.
  URI="http://${version}.${application}.loc"

  # Start Magento installation.
  echo "Starting Magento ${version[@]} installation."

  # Creating new database.
  echo "Creating database and making sure it's a fresh one."
  docker exec devilbox_mysql_1 sh -c 'exec mysql -h 127.0.0.1 -e "DROP DATABASE IF EXISTS '${db}';"'
  docker exec devilbox_mysql_1 sh -c 'exec mysql -h 127.0.0.1 -e "CREATE DATABASE IF NOT EXISTS '${db}';"'

  echo "Updating etc/hosts for new URL ${version}.${application}.loc"
  # Checking in etc/hosts if url is already added. If not we're adding it.

  SUCCESS=0
  needle="${url}"
  hostline="${url}"
  filename=/etc/hosts

  # Determine if the line already exists in /etc/hosts
  echo "Checking if the line "${url}" hostline already exists in /etc/hosts."
  grep -q "${needle}" "${filename}"

  # Grep's return error code can then be checked. No error=success
  if [ $? -eq $SUCCESS ]
  then
    echo "${needle} FOUND in ${filename} skip adding."
  else
    echo "${needle} NOT found in ${filename}. Adding line."
    # If the line wasn't found, add it using an echo append >>
    echo "${url}" >> "${filename}"
    echo "${hostline} added to ${filename}"
  fi

  echo "Installing magento in the dockerenv_php_1"
  docker exec devilbox_php_1 sh -c "./magento_install.sh '${version}'"
done
