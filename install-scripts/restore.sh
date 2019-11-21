#!/bin/bash

# Arguments
version="$2"
application="$1"

# Variables declared.
# pre="     \e[33m[Restore]\e[39m"
# pre_err="     \e[31m[Error]\e[39m "
pre=""
pre_err=""
root="/shared/httpd"
db="${application}_${version//./}"

# Backup folder
backup=${root}"/backup"

backup_app_dir="${backup}/${application}_${version}/${version}.${application}"
zip_file=${backup}/${application}_${version}.zip
sql_file=${backup}/${application}_${version}/${application}.${version}.sql

printf "${pre} Unzipping ${zip_file} file.\n"

if [[ -f ${zip_file} ]]; then
  # Extracting downloaded zip into system files directory.
  unzip -qq ${zip_file} -d ${backup}
  if [[ -f ${sql_file} ]]; then
    printf "${pre} Unzipping was successfull!\n"
    printf "${pre} Import the mysql from the backup for ${application} ${version}.\n"
    # Import frmo mysql dump
    mysql -h 127.0.0.1 -u root ${db} < ${sql_file}
  else
      printf "${pre_err} The ${sql_file} file was not found!\n"
  fi
  printf "${pre} Copying the unzipped folder to the right directory.\n"
  cp -rp ${backup_app_dir}/. ${root}/${version}.${application}
  printf "${pre} Cleaning up the unzipped folder!\n"
  rm -fR ${backup}/${application}_${version}
  chmod 777 -fR ${root}/${version}.${application}
else
    printf "${pre_err} The ${zip_file} file was not found!\n"
fi
