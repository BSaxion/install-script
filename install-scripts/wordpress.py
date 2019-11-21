#!/usr/bin/python3
import sys
import os, tempfile
import shutil
import urllib.request
from io import BytesIO
from urllib.request import urlopen
from zipfile import ZipFile
print("installation started")
# parsing the version, application, and host
version = sys.argv[1]
application = sys.argv[2]
host = sys.argv[3]

# get host directory or path
root_dir = os.getcwd()
# temp_dir = os.mkdir(root_dir + '/tmp', mode=777)
# installation path
install_path = root_dir + '/' + version + '.' + application + '/htdocs'

# create a function to download an application
def get_url():
    url = {
        "wordpress": "https://wordpress.org/",
        "drupal": "https://drupal.org/"
    }
    file = application + '-' + version + '.zip'
    if application.lower() == "wordpress":
        url = url[application] + file
    else:
        print "application not found"
    download(url)

def download(url):
    with urlopen(url) as zipurl:
        with ZipFile(BytesIO(zipurl.read())) as zfile:
            files = zfile.extractall("temp")
            files = os.listdir(files)
            for f in files:
                if f == 'temp':
                    shutil.move(f, install_path)


def main():
    get_url()

# main()
# edit config file if any


# add database credentials


# create a function that installs the application
