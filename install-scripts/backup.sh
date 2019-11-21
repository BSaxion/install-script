#!/bin/bash

# Arguments
version="$2"
application="$1"

# Variables declared.
pre="     \e[33m[Backup]\e[39m"
pre_err="     \e[31m[Error]\e[39m "

root="/shared/httpd"
db="${application}_${version//./}"

# Backup folder
backup=${root}"/backup"

# Check if the old backup folder are exist
if [[ -d ${backup}/${application}_${version} ]]; then
  printf "${pre} Sytem files ${application} ${version} directory exists. Making sure it's clean.\n"
  rm -rf ${backup}/${application}_${version}
fi

# Delete the old backup if it's exists
if [[ -f ${backup}/${application}_${version}.zip ]]; then
  rm ${backup}/${application}_${version}.zip
fi

# Create the folder if it's not exists
mkdir -p ${backup}
mkdir -p ${backup}/${application}_${version}

printf "${pre} Creating the mysql backup for the ${application} ${version}.\n"

# Copy the folder
cp -r ${root}/${version}.${application} ${backup}/${application}_${version}

# Create a mysql dump
mysqldump -h 127.0.0.1 -u root ${db} > ${backup}/${application}_${version}/${application}.${version}.sql; &>/dev/null;

# Create a backup zip
printf "${pre} Creating the folder backup for the ${application} ${version}.\n"
( cd ${backup} && zip -r -T ${application}_${version}.zip ${application}_${version} &>/dev/null )

# Remove the folder
rm -rf ${backup}/${application}_${version}

# Done
printf "${pre} Backup for the ${application} ${version} done.\n"
