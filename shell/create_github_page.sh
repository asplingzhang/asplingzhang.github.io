#!/bin/bash
SCRIPT_ABS_PATH="$(cd "$(dirname "$0")" && pwd)"

usage() {
    echo "Shell function:"
    echo "Use template to create a markdown file under the current directory for writting articles powered by github pages"
    echo ""
    echo "Usage:[-n name_of_file][-h help]"
    echo -e "\t-n:name of file,.md or .markdown is not needed."
    echo -e "\t-h:show the usage"
}

filename=""
title=""
url_without_date=""
while getopts "n:h" arg; do
  case $arg in
    n)
      filename=${OPTARG}
      title=$filename
      url_without_date=$filename
      if [[ $filename == "" ]] ;then
          echo "Error:file name is empty."
          exit 1
      fi
      #Append .md to the name.
      filename="$filename.md"
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done

# Template for jekyll
#---
#layout: default
#title:  "Why static_cast void(or (void)0) and LogMessageVoidify are needed in logging macros"
#date:   2022-06-14 14:25:33 +0800
#categories: [webrtc,logging]
#---

# Get current date as yyyy-mm-dd format
date_yyyy_mm_dd=$(date '+%Y-%m-%d')
filename="$date_yyyy_mm_dd-$filename"
if [ -f $filename ];then
    echo "Error:file $filename already exists."
    exit 1
fi
echo "---" > $filename
echo "layout: default" >> $filename
#Replace - to blank for the title
title_split=$(echo $title | gsed "s/-/ /g")
echo "title: \"$title_split\"" >> $filename
# Put current date as yyyy-mm-dd HH:MM:SS in $date
date=$(date '+%Y-%m-%d %H:%M:%S')
echo "date: $date +0800" >> $filename
echo "categories: webrtc" >> $filename
echo "---" >> $filename

# Abstract
echo "" >> $filename
echo "# Abstract" >> $filename
# Copyrights
echo "" >> $filename
echo "# Copyright notice" >> $filename
echo "All Rights Reserved.Any reprint/reproduce/redistribution of this article MUST indicate the source. " >> $filename

#Update sitemap.xml for new added article and the `lastmod` of home index `https://asplingzhang.github.io/`

$SCRIPT_ABS_PATH/update_github_pages_sitemap.sh -n "$url_without_date"
