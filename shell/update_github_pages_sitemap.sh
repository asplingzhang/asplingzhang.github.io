#!/bin/bash
usage() {
    echo "Shell function:"
    echo "Update lastmod of sitemap.xml,used when modification made to already-existed file."
    echo ""
    echo "Usage:[-n name_of_file][-h help]"
    echo -e "\t-n:name of file,.md or .markdown is not needed."
    echo -e "\t-h:show the usage"
}

sitemap_xml="/Users/klaus/dev/src/github/asplingzhang.github.io/docs/sitemap.xml"

filename=""
while getopts "n:h" arg; do
  case $arg in
    n)
      filename=${OPTARG}
      title=$filename
      if [[ $filename == "" ]] ;then
          echo "Error:file name is empty."
          exit 1
      fi
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done

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

line_num=$(grep -n $filename $sitemap_xml | awk '{print $1}' | sed "s/://g")
line_num_next=$(($line_num+1))
echo $line_num
echo $line_num_next
gsed -i "${line_num_next}d" $sitemap_xml
# Get current date as yyyy-mm-dd format
date_yyyy_mm_dd=$(date '+%Y-%m-%d')
hh_mm_ss=$(date '+%H:%M:%S')
gsed -i  "$line_num a \ \ \ \ \ \ <lastmod>${date_yyyy_mm_dd}T${hh_mm_ss}+08:00</lastmod>" $sitemap_xml
