#!/bin/bash
# This script can be used to install plugins with a specific versions.
wp_version="$1"
plugin_name="$2"
plugin_version="$3"

# Variables declared.
pre="     \e[34m[Docker]\e[39m"
pre_err="     \e[31m[Error]\e[39m "

# Directories
root="/shared/httpd"
app_dir="${root}/${wp_version}.wordpress/htdocs"
app_plugin_dir="${app_dir}/wp-content/plugins/${plugin_name}"
app_uploads="${app_dir}/wp-content/uploads"

db="wordpress_${wp_version//./}"

# Cache direcory
cache="/shared/httpd/cache"

#Plugin specific variables can be set here
case ${plugin_name} in
  "all-in-one-seo-pack")
    file="${plugin_name}-${plugin_version}.zip"
    file_url="https://github.com/semperfiwebdesign/all-in-one-seo-pack/archive/${plugin_version}.zip"
    ;;
  "contact-form-7")
    file="${plugin_name}-${plugin_version}.zip"
    file_url="https://github.com/wp-plugins/contact-form-7/archive/${plugin_name}-${plugin_version}.zip"
    ;;
  "jetpack")
    file="${plugin_name}-${plugin_version}.zip"
    file_url="https://github.com/Automattic/jetpack/archive/${plugin_version}.zip"
    ;;
  "wordpress-seo")
    file="${plugin_name}-${plugin_version}.zip"
    file_url="https://github.com/Yoast/wordpress-seo/archive/${plugin_version}.zip"
    ;;
  "google-sitemap-generator")
    file="${plugin_name}-${plugin_version}.zip"
    file_url="https://downloads.wordpress.org/plugin/google-sitemap-generator.${plugin_version}.zip"
    ;;
  "tinymce-advanced")
    file="${plugin_name}-${plugin_version}.zip"
    file_url="https://downloads.wordpress.org/plugin/tinymce-advanced.${plugin_version}.zip"
    ;;
  *)
    # Plugin zip file name
    file="${plugin_name}-${plugin_version}.zip"
    # Plugin zip file url
    file_url="https://downloads.wordpress.org/plugin/${plugin_name}.${plugin_version}.zip"
    ;;
esac

http_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' ${file_url})

printf "\n##############################################################################\n#\n"
printf "#   Installing ${plugin_name} \e[32m${plugin_version}\e[39m for Wordpress \e[32m${wp_version}\e[39m \n#\n"
printf "##############################################################################\n\n"

if [[ ! -d ${app_dir} ]]; then
  printf "${pre_err} The plugin dir not exist, installation stopping...\n"
  printf "${pre_err} Good bye!\n"
  exit
fi

# Older WP versions does not have a cli and old plugin also cannot installed by cli
if [[ $wp_version != "3.5" ]] && [[ $wp_version != "3.6" ]] && [[ $wp_version != "3.6.1" ]]; then
  printf "${pre} CLI: Install and activate ${plugin_name}\n"
  ( cd ${app_dir} && wp plugin install ${plugin_name} --version=${plugin_version} --activate --allow-root --quiet &>/dev/null )
else
  # Manuall install START
  printf "${pre} WP-CLI is not available install ${plugin_name} manually\n"
  # Creat the folder for the plugin
  if [[ -d ${app_plugin_dir} ]]; then
    printf "${pre} Clear and re-create the ${plugin_name} plugin folder\n"
    rm -fR ${app_plugin_dir}
  fi

  printf "${pre} Create the ${plugin_name} plugin folder\n"
  mkdir ${app_plugin_dir}
  chmod 775 ${app_plugin_dir}

  if [[ ! -d ${cache} ]]; then
    printf "${pre} Cache dir not found. Create cache dir.\n"
    mkdir ${cache}
  fi

  # Checking if zip file exists. If not we're downloading it.
  printf "${pre} Checking if zip file exists. If not we're downloading it.\n"
  if [[ -f ${cache}/${file} ]]; then
    printf "${pre} File detected no need to download it again.\n"
  else
    printf "${pre} No ZIP file detected for ${plugin_version} ${plugin_version} we'll start downloading it.\n"
    if [[ ${http_status:0:1} == "2" ]] || [[ ${http_status:0:1} == "3" ]]; then
      printf "${pre} ${plugin_name} detected as input. Downloading ${plugin_version} - ${file}.\n"
      wget --no-verbose ${file_url} -O ${cache}/${file} -q
    else
      printf "${pre_err} The ${plugin_name} ${plugin_version} not available. Cannot download it. HTTP-STATUS: $http_status \n"
      printf "${pre_err} Script stopping..."
      printf "${pre_err} Good bye!\n"
      exit
    fi
  fi

  if [[ -f ${cache}/${file} ]]; then
    # Extracting downloaded zip into system files directory.
    printf "${pre} Start unzipping ${file}\n"
    unzip -qq ${cache}/${file} -d ${app_plugin_dir}

    if [[ -d ${app_plugin_dir}/${plugin_name} ]]; then
      printf "${pre} Copying the unzipped folder to the right directory.\n"
      cp -rp ${app_plugin_dir}/${plugin_name}/. ${app_plugin_dir}
      rm -fR ${app_plugin_dir}/${plugin_name}
    fi

    if [[ -d ${app_plugin_dir}/${plugin_name}-${plugin_version} ]]; then
      printf "${pre} Copying the unzipped folder to the right directory.\n"
      cp -rp ${app_plugin_dir}/${plugin_name}-${plugin_version}/. ${app_plugin_dir}
      rm -fR ${app_plugin_dir}/${plugin_name}-${plugin_version}
    fi
    chmod 777 -fR ${app_plugin_dir}
  fi

fi

# Activate the plugin if the wp is new enough
if [[ $wp_version != "3.5" ]] && [[ $wp_version != "3.6" ]] && [[ $wp_version != "3.6.1" ]]; then
  printf "${pre} CLI: Activate ${plugin_name}\n"
  ( cd ${app_dir} && wp plugin activate ${plugin_name} --allow-root --quiet &>/dev/null )
fi

# Jetpack specific install
# This token key needs to be replaced every now and than because this can be differ
if [[ ${plugin_name} == "jetpack" ]]; then
  printf "${pre} Activate ${plugin_name}\n"
  mysql -h 127.0.0.1 -e 'use '${db}'; UPDATE `wp_options` SET `option_value` = "a:9:{s:7:\"version\";s:14:\"3.0:1551868573\";s:11:\"old_version\";s:14:\"3.0:1551868573\";s:28:\"fallback_no_verify_ssl_certs\";i:0;s:9:\"time_diff\";i:-32;s:2:\"id\";i:157730477;s:10:\"blog_token\";s:65:\"4!ta$Ff2pX6E6BHR$L9O%G*WQ88uhPkV.o#$36S)WlZQ9(6AWK4N)IFk8dk0HVXBi\";s:6:\"public\";i:1;s:11:\"user_tokens\";a:1:{i:1;s:67:\"xS3zu177*x!%han!80rnzECslCaej#12.7LzA7rqof9WB#wnONJujYKBrytfDL2&Z.1\";}s:11:\"master_user\";i:1;}" WHERE `wp_options`.`option_name` = "jetpack_options";'
fi

# Add permission to the upload folder
chmod 777 -fR ${app_uploads}

printf "${pre} Installation for ${plugin_name} version ${plugin_version} is completed.\n\n"
