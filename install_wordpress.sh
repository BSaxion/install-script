#!/bin/bash
# Unified installation script for devilbox for Mac
ver=( "4.4" )

# Grep local correct container name.
mysql_container=$(docker ps | grep "cytopia/mariadb" | awk '{print $1}')
php_container=$(docker ps | grep "devilbox/php-fpm" | awk '{print $1}')

# WP and WC version list change it in pairs
# e.g.: (wp 4.9.7 -> wc 3.4.0) and (wp 4.2 -> wc 2.1.0)
wp_v=( "5.1"   "5.0"  "4.9.8" "4.9.7" "4.9.6" "4.9"   "4.8.2" "4.8"   "4.7.7"   "4.7"    "4.6.4"    "4.6"   "4.5"   "4.0"   "4.3"   "4.4"   "3.8"   "3.8", "3.6"   )
wc_v=( "3.6.4" "3.6.3" "3.5.8" "3.4.0" "3.4.0" "3.3.2" "3.3.1" "3.3.0" "3.2.4" "3.4.0"  "3.3.0"     "2.6.0" "4.5"   "2.4.0" "3.2.0" "2.6.0" "2.1.0" "2.1.0" )
cf_v=( "5.1"   "5.0.4" "5.0.3" "5.0.2" "4.9.2" "4.9"   "4.9"   "4.9"    "4.9"    "4.6.1"    "4.6"   "4.5"   "4.5"   "4.4"   "3.9"   "3.6"     "3.6"   )
yc_v=( "9.5"   "10.0"   "9.3"   "9.2"   "9.2.1" "10.1"  "9.0"   "8.0"   "11.0"    "8.2"    "7.0"    "5.0"    "7.4"    "6.1"  "3.5"  "1.7" "2.0"   "3.5"  "1.6.1"   "2.2" "1.5.6" )
jp_v=( "6.9"   "6.8"   "6.6"   "6.5"   "6.3"   "6.2"   "6.1"   "5.8"    "4.8"    "4.7"      "4.5"   "4.4"   "4.4" "3.4"     "3.1"   "2.8"   "2.8"   )
sp_v=( "2.12"  "2.10"  "2.9.1" "2.8"   "2.7.2" "2.6"   "2.5"   "2.3.16" "2.3.12" "2.3.10.1" "2.3.9" "2.3.5" "2.10" "2.3.5" "2.3.9.2" "2.3.3" "2.3.1" )
gs_v=( "4.0.9" "4.0.1" "4.0"   "3.4.1" "3.3.1" "3.3"   "3.2"   "3.1.9"  "4.0.7"  "3.0.2"    "3.0.1" "3.0"   "2.7.1" "2.7"   "2.6"   "2.6"   "2.5"   )
ta_v=( "4.0.9" "4.0.1" "4.0"   "3.4.1" "3.3.1" "3.3"   "3.2"   "3.1.9"  "4.0.7"  "3.0.2"    "3.0.1" "3.0"   "3.5.9" "3.5.9" "2.6"   "4.0"   "3.5.9" )
#Set the default plugin versions
wc_version="3.0.0"
cf_version="4.4"
yc_version="5.0"
jp_version="5.0"
sp_version="2.4"
gs_version="4.0"
tma_version="4.0"

function set_plugin_versions() {
  #Set the corresponding plugin version if it exist using the array index number
  for i in "${!wp_v[@]}"; do
    if [ ${wp_v[$i]} = $1 ] ; then
      #WP versions
      if  [ ${wc_v[$i]} ] ; then
        wc_version=${wc_v[$i]}
      fi
      #CF7 versions
      if  [ ${cf_v[$i]} ] ; then
        cf_version=${cf_v[$i]}
      fi
      #Yoast versions
      if  [ ${yc_v[$i]} ] ; then
        yc_version=${yc_v[$i]}
      fi
      #Jetpack versions
      if  [ ${jp_v[$i]} ] ; then
        jp_version=${jp_v[$i]}
      fi
      #All in one SEO Pack versions
      if  [ ${sp_v[$i]} ] ; then
        sp_version=${sp_v[$i]}
      fi
      #Google XML Sitemaps versions
      if  [ ${gs_v[$i]} ] ; then
        gs_version=${gs_v[$i]}
      fi
      #TinyMCE Advanced versions
      if  [ ${ta_v[$i]} ] ; then
        tma_version=${ta_v[$i]}
      fi
    fi
  done
}

# Variables declared.
host="127.0.0.1"
application="wordpress"

for version in "${ver[@]}"; do
  #Set the set_plugin_versions
  set_plugin_versions "${version}"
  # Database name
  db="${application}_${version//./}"
  docker exec ${mysql_container} sh -c 'exec mysql -h '${host}' -e "DROP DATABASE IF EXISTS '${db}';"'
  docker exec ${mysql_container} sh -c 'exec mysql -h '${host}' -e "CREATE DATABASE IF NOT EXISTS '${db}';"'
  # Install wordpress
  docker exec ${php_container} sh -c "./wordpress.sh ${version}"
  # Install woocommerce
  docker exec ${php_container} sh -c "./woocommerce.sh ${version} ${wc_version}"
  # # Install contact-form-7
  # docker exec ${php_container} sh -c "./wp-plugin-install.sh ${version} contact-form-7 ${cf_version}"
  # Install Yoast SEO
  #docker exec ${php_container} sh -c "./wp-plugin-install.sh ${version} wordpress-seo ${yc_version}"
  # Install JetPack
  # docker exec ${php_container} sh -c "./wp-plugin-install.sh ${version} jetpack ${jp_version}"
  # # Install All in one SEO Pack
  # docker exec ${php_container} sh -c "./wp-plugin-install.sh ${version} all-in-one-seo-pack ${sp_version}"
  # # Install Google XML Sitemaps
  # docker exec ${php_container} sh -c "./wp-plugin-install.sh ${version} google-sitemap-generator ${gs_version}"
  # # Install TinyMCE Advanced
  # docker exec ${php_container} sh -c "./wp-plugin-install.sh ${version} tinymce-advanced ${tma_version}"

done
