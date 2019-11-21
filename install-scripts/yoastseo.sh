#!/bin/bash
# This script can be used to install yoast-seo versions.
wp_version=$1
plugin_version=$2

# Variables declared.
plugin_name="wordpress-seo"
pre="     \e[34m[Docker]\e[39m"

# Directories
root="/shared/httpd"
app_dir="${root}/${wp_version}.wordpress/htdocs"
app_plugin_dir="${app_dir}/wp-content/plugins/${plugin_name}"
app_theme_folder="${app_dir}/wp-content/themes"

#Cache direcory
cache="/shared/cache"

#WC zip file
file="wordpress-seo-${plugin_version}.zip"

file_url="https://github.com/Yoast/wordpress-seo/archive/${plugin_version}.zip"
http_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' ${file_url})

printf "\n############################################################################\n#\n"
printf "#   Installing yoast-seo \e[32m${plugin_version}\e[39m for Wordpress \e[32m${wp_version}\e[39m \n#\n"
printf "##############################################################################\n\n"

#Older WP versions does not have a cli and old yoast also cannot installed by cli
if [[ "$wp_version" != "3.6" ]] && [[ "$wp_version" != "3.6.1" ]] && [[ ${plugin_version:0:1} != "1" ]]; then
  printf "${pre} CLI: Install and activate ${plugin_name}\n"
  ( cd ${app_dir} && wp plugin install ${plugin_name} --version=${plugin_version} --activate --allow-root --quiet 1>/dev/null )

else
  # Manuall install START
  printf "${pre} WP-CLI is not available install ${plugin_name} manually\n"
  # Creat the folder for the plugin
  if [ -d ${app_plugin_dir} ]; then
    printf "${pre} Clear and re-create the ${plugin_name} plugin folder\n"
    rm -fR ${app_plugin_dir}
  fi

  printf "${pre} Create the ${plugin_name} plugin folder\n"
  mkdir ${app_plugin_dir}
  chmod 775 ${app_plugin_dir}

  if [ ! -d ${cache} ]; then
    printf "${pre} Cache dir not found. Create cache dir.\n"
    mkdir ${cache}
  fi

  # Checking if zip file exists. If not we're downloading it.
  printf "${pre} Checking if zip file exists. If not we're downloading it.\n"
  if [ -f ${cache}/${file} ]; then
    printf "${pre} File detected no need to download it again.\n"
  else
    printf "${pre} No ZIP file detected for ${application} ${version} we'll start downloading it.\n"
    if [ $http_status == "200" ] || [ $http_status == "300" ] || [ $http_status == "301" ] || [ $http_status == "302" ] ; then
      printf "${pre} ${plugin_name} detected as input. Downloading ${plugin_version} - ${file}.\n"
      wget --no-verbose ${file_url} -O ${cache}/${file}  >/dev/null
    else
      printf "${pre} ERROR: The ${plugin_name} ${plugin_version} not available. Cannot download it. HTTP-STATUS: $http_status \n"
    fi
  fi

  if [ -f ${cache}/${file} ]; then
    # Extracting downloaded zip into system files directory.
    printf "${pre} Start unzipping ${file}\n"
    unzip -qq ${cache}/${file} -d ${app_plugin_dir}
    printf "${pre} Copying the unzipped folder to the right directory.\n"
    cp -rp ${app_plugin_dir}/${plugin_name}-${plugin_version}/. ${app_plugin_dir}
    rm -fR ${app_plugin_dir}/${plugin_name}-${plugin_version}
    chmod 777 -fR ${app_plugin_dir}
  fi

  # Activate the plugin if the wp is new enough
  if [[ "$wp_version" != "3.6" ]] && [[ "$wp_version" != "3.6.1" ]]; then
    printf "${pre} CLI: Activate ${plugin_name}\n"
    ( cd ${app_dir} && wp plugin activate ${plugin_name} --allow-root --quiet 1>/dev/null )
  fi

fi
# yoast-seo specific install END

printf "${pre} Installation for ${plugin_name} version ${plugin_version} is completed.\n\n"
