#!/bin/bash
# This script can be used to install WooCOmmerce versions.
# Note: Versions older than 2.5.0 CANNOT be installed command line.
# Inc case it's an older version the script will prepare as much as possible.
wp_version="$1"
plugin_version="$2"

# Variables declared.
plugin_name="woocommerce"
pre="     \e[34m[Docker]\e[39m"
pre_err="     \e[31m[Error]\e[39m "

# Directories
root="/shared/httpd"
app_dir="${root}/${wp_version}.wordpress/htdocs"
app_plugin_dir="${app_dir}/wp-content/plugins/${plugin_name}"
app_theme_folder="${app_dir}/wp-content/themes"

#Cache direcory
cache="/shared/cache"

#WC zip file
file="wordpress-${plugin_version}.zip"
file_url="https://github.com/woocommerce/woocommerce/archive/${plugin_version}.zip"
http_status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' ${file_url})

printf "\n############################################################################\n#\n"
printf "#   Installing woocommerce \e[32m${plugin_version}\e[39m for Wordpress \e[32m${wp_version}\e[39m \n#\n"
printf "##############################################################################\n\n"

if [[ $wp_version != "3.6" ]] && [[ $wp_version != "3.6.1" ]]; then

  ( cd ${app_dir} && wp plugin install woocommerce --version=${plugin_version} --activate --allow-root --quiet &>/dev/null )

  # printf "${pre} WP-CLI: Install plugin: wordpress-importer\n"
  ( cd ${app_dir} && wp plugin install wordpress-importer --activate --quiet --allow-root &>/dev/null )

  printf "${pre} WP-CLI: Import sample_products for WooCommerce\n"
  ( cd ${app_dir} && wp import ${root}/dummy-data.xml --authors=create --quiet --allow-root &>/dev/null )

  printf "${pre} WP-CLI: Creating WooCommerce pages.\n"
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Cart' --post_content='[woocommerce_cart]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Checkout' --post_content='[woocommerce_checkout]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Checkout &rarr; Pay' --post_content='[woocommerce_pay]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Order Received' --post_content='[woocommerce_thankyou]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='My Account' --post_content='[woocommerce_my_account]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Change Password' --post_content='[woocommerce_change_password]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Edit My Address' --post_content='[woocommerce_edit_address]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Logout' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Lost Password' --post_content='[woocommerce_lost_password]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='View Order' --post_content='[woocommerce_view_order]' --quiet --allow-root )
  ( cd ${app_dir} && wp post create --post_type=page --post_status=publish --post_title='Shop' --quiet --allow-root )

  printf "${pre} WP-CLI: Creating menu for WooCommerce.\n"
  ( cd ${app_dir} && wp menu create 'WooCommerce Menu' --quiet --allow-root )
  ( cd ${app_dir} && wp menu item add-post 'WooCommerce Menu' 106 --title='Shop' --quiet --allow-root )
  ( cd ${app_dir} && wp menu item add-post 'WooCommerce Menu' 102 --title='Cart' --quiet --allow-root )
  ( cd ${app_dir} && wp menu item add-post 'WooCommerce Menu' 104 --title='My Account' --quiet --allow-root )
  ( cd ${app_dir} && wp menu item add-post 'WooCommerce Menu' 105 --title='Edit My Address' --quiet --allow-root )
  ( cd ${app_dir} && wp menu item add-post 'WooCommerce Menu' 2 --title='Blog' --quiet --allow-root )
  ( cd ${app_dir} && wp menu location assign woocommerce-menu primary --quiet --allow-root )

  # printf "${pre} WP-CLI: Setting front, blog and shop page.\n"
  # ( cd ${app_dir} && wp option update page_on_front 106 --quiet --allow-root )
  # ( cd ${app_dir} && wp option update page_for_posts 2 --quiet --allow-root )
  # ( cd ${app_dir} && wp option update show_on_front page --quiet --allow-root )
  # ( cd ${app_dir} && wp option update woocommerce_shop_page_id 106 --quiet --allow-root )
  # Some case this is not supported and than throwing errors to the terminal
  # ( cd ${app_dir} && wp wc coupon create --code='test-code' --amount='10' --quiet --allow-root )
  # ( cd ${app_dir} && wp wc customer create 123@123.nl --password='Admin123' --username='John Doe' --billing_address.email='123@123.nl' --billing_address.first_name='John' --billing_address.last_name='Doe' --billing_address.address_1='Street 1' --billing_address.postcode='7777 AA' --billing_address.city='Enschede' --billing_address.country='NL' --quiet --allow-root )
  # ( cd ${app_dir} && wp wc order create --customer_id='3' --line_items.0.product_id=93 --line_items.0.quantity=1 --status='completed' --quiet --allow-root )
  # ( cd ${app_dir} && wp wc tax create --country='NL' --rate='21' --class='standard' --type='percent' --quiet --allow-root )

  # #START install theme
  # theme_name="storefront"
  # theme_version="2.3.3"
  # theme_zip="storefront.${theme_version}.zip"
  # theme_url="https://downloads.wordpress.org/theme/${theme_zip}"
  # theme_http_status=$(curl -o &>/dev/null --silent --head --write-out '%{http_code}' ${theme_url})
  #
  # # Checking if zip file exists. If not we're downloading it.
  # printf "${pre} Install ${theme_name} - ${theme_version}\n"
  # if [ -f ${cache}/${theme_zip} ]; then
  #   printf "${pre} File detected no need to download it again.\n"
  # else
  #   printf "${pre} No ZIP file detected for ${theme_name} ${theme_version} we'll start downloading it.\n"
  #   if [[ ${theme_http_status:0:1} == "2" ]] || [[ ${theme_http_status:0:1} == "3" ]]; then
  #     printf "${pre} Downloading ${theme_version} - ${theme_zip}.\n"
  #      --no-verbose ${theme_url} -O ${cache}/${theme_zip} &>/dev/null
  #   else
  #     printf "${pre_err} The ${theme_name} ${theme_version} not available. Cannot download it.\n"
  #   fi
  # fi
  #
  # if [ -f ${cache}/${theme_zip} ]; then
  #   # Extracting downloaded zip into system files directory.
  #   printf "${pre} Start unzipping ${theme_zip}\n"
  #   unzip -qq ${cache}/${theme_zip} -d ${app_theme_folder}
  #   printf "${pre} Copying the unzipped folder to the right directory.\n"
  #   chmod 777 -fR ${app_theme_folder}
  #   printf "${pre} Activate theme: ${theme_name}\n"
  #   ( cd ${app_dir} && wp --allow-root theme activate ${theme_name} --quiet &>/dev/null )
  # fi
  #END install theme
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
    printf "${pre} ${plugin_name} ${plugin_version} (cached)\n"
  else
    printf "${pre} File not cached. Checking if ${plugin_name} ${plugin_version} is available for download.\n"
    if [[ ${http_status:0:1} == "2" ]] || [[ ${http_status:0:1} == "3" ]]; then
      printf "${pre} ${plugin_name} detected as input. Downloading ${plugin_version} - ${file}.\n"
      wget --no-verbose ${file_url} -O ${cache}/${file} -q
    else
      printf "${pre_err} The ${plugin_name} ${plugin_version} not available. Cannot download it.\n"
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

fi
# WooCommerce specific install END
printf "${pre} Installation for ${plugin_name} version ${plugin_version} is completed.\n\n"
