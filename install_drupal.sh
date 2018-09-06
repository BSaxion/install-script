#!/bin/bash

# This script can be used to install multiple versions of drupal 7 and 8.

# Specify here which version you would like to install.
ver=(
"8.6.0"
#"8.5.7"
#"8.5.6"
#"8.5.4"
#"8.5.0"
#"7.59"
#"7.0.0"
)

for version in "${ver[@]}"
do

  # Variables declared.
  application="drupal"
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
  echo "Starting Drupal ${version[@]} installation."

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

  echo "Installing Drupal in the dockerenv_php_1"
  docker exec devilbox_php_1 sh -c "./drupal_install.sh '${version}'"
done
