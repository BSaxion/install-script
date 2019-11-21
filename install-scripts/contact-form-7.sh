#!/bin/bash

# This script can be used to install Contact Form 7 versions.
# Note: Versions older than 2.5.0 CANNOT be installed command line.
# Inc case it's an older version the script will prepare as much as possible.

wp_version="$1"
plugin_version="$2"

pre="     \e[34m[Docker]\e[39m"

# Variables declared.
plugin_name="contact-form-7"

# Directories
root="/shared/httpd"
app_dir="${root}/${wp_version}.wordpress/htdocs"
app_plugin_dir="${app_dir}/wp-content/plugins/${plugin_name}"
app_theme_folder="${app_dir}/wp-content/themes"
app_uploads="${app_dir}/wp-content/uploads"

# Cache direcory
cache="/shared/cache"

# WC zip file
file="${plugin_name}-${plugin_version}.zip"
file_url="https://github.com/wp-plugins/contact-form-7/archive/${file}"
http_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' ${file_url})

printf "\n############################################################################\n#\n"
printf "#    Installing Contact Form 7 \e[32m${plugin_version}\e[39m for Wordpress \e[32m${wp_version}\e[39m \n#\n"
printf "#############################################################################\n\n"

# Detect version and execute corresponding actions.
if [ $wp_version != "3.6" ] && [ $wp_version != "3.6.1" ]; then

  printf "${pre} Install plugin: ${plugin_name} and activate\n"
  ( cd ${app_dir} && wp plugin install ${plugin_name} --version=${plugin_version} --activate --quiet --allow-root 2>/dev/null )

  printf "${pre} Install plugin: Really Simple CAPTCHA.\n"
  ( cd ${app_dir} && wp plugin install 'Really Simple CAPTCHA' --activate --quiet --allow-root 2>/dev/null )

  printf "${pre} Create the Contact page and insert the CF7 shortcode.\n"
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Contact' --post_content='[contact-form-7 id="3" title="CF7"]' --quiet --allow-root 2>/dev/null )

else
  # WP-CLI not available installing manually
  # Create the folder for the plugin
  if [ -d ${app_plugin_dir} ]; then
    printf "${pre} Clear the ${plugin_name} plugin folder.\n"
    rm -fR ${app_plugin_dir}
  fi

  printf "${pre} Create the ${plugin_name} plugin folder.\n"
  mkdir ${app_plugin_dir}
  chmod 775 ${app_plugin_dir}

  printf "${pre} Cache dir not found. Create cache dir.\n"
  mkdir -p ${cache}

  # Checking if zip file exists. If not we're downloading it.
  printf "${pre} Checking if zip file exists. If not we're downloading it.\n"
  if [ -f ${cache}/${file} ]; then
    printf "${pre} File detected no need to download it again.\n"
  else
    printf "${pre} No zip file detected for ${plugin_name} ${plugin_version} we'll start downloading it.\n"
    printf "${pre} Checking if ${plugin_name} ${plugin_version} is available for download.\n"
    if [ ${http_status:0:1} == "2" ] || [ ${http_status:0:1} == "3" ]; then
      printf "${pre} ${plugin_name} detected as input. Downloading ${plugin_version} - ${file}.\n"
      wget --no-verbose ${file_url} -O ${cache}/${file} &>/dev/null
    else
      printf "${pre} \e[31mError:\e[39m The ${plugin_name} ${plugin_version} not available. Cannot download it.\n"
    fi
  fi

  if [ -f ${cache}/${file} ]; then
    # Extracting downloaded zip into system files directory.
    printf "${pre} Start unzipping ${file}\n"
    unzip -qq ${cache}/${file} -d ${app_plugin_dir} &>/dev/null
    printf "${pre} Copying the unzipped folder to the right directory.\n"
    cp -rp ${app_plugin_dir}/${plugin_name}-${plugin_version}/. ${app_plugin_dir}
    rm -fR ${app_plugin_dir}/${plugin_name}-${plugin_version}
    chmod 777 -fR ${app_plugin_dir}
  fi

fi

# Add permuission to the upload folder (because the additional plugins)
chmod 777 -fR ${app_uploads}

# WooCommerce specific install END
printf "${pre} Installation for CF7 version ${plugin_version} is completed.\n\n"
