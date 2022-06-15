#!/bin/bash
usage() {
    echo "Shell function:"
    echo "Use template to create a markdown file under the current directory for writting articles powered by github pages"
    echo ""
    echo "Usage:[-n name_of_file][-h help]"
    echo -e "\t-n:name of file,.md or .markdown is not needed."
    echo -e "\t-h:show the usage"
}

sitemap_xml_path="/Users/klaus/dev/src/github/asplingzhang.github.io/docs/sitemap.xml"

filename=""
title=""
while getopts "n:h" arg; do
  case $arg in
    n)
      filename=${OPTARG}
      title=$filename
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

#Update sitemap.xml

#    <url>
#      <loc>https://asplingzhang.github.io/</loc>
#        <lastmod>2022-06-07T19:25:58+08:00</lastmod>
#    </url>
#   </urlset>

if [ ! -f $simtemap_xml_path ];then
    echo "Error:sitemap.xml is not existed at $sitemap_xml_path"
    exit 1
fi
gsed -i "/<\/urlset>/d" $sitemap_xml_path
echo "    <url>" >> $sitemap_xml_path
echo "      <loc>https://asplingzhang.github.io/$title</loc>" >> $sitemap_xml_path
hh_mm_ss=$(date '+%H:%M:%S')
echo "      <lastmod>${date_yyyy_mm_dd}T${hh_mm_ss}+08:00</lastmod>" >> $sitemap_xml_path
echo "    </url>" >> $sitemap_xml_path
echo "</urlset>" >> $sitemap_xml_path
