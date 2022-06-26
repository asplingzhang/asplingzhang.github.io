#!/bin/bash
SCRIPT_ABS_PATH="$(cd "$(dirname "$0")" && pwd)"

usage() {
    echo "Shell function:"
    echo "Update lastmod of sitemap.xml,used when modification made to already-existed file."
    echo ""
    echo "Usage:[-n name_of_file][-h help]"
    echo -e "\t-n:name of file,.md or .markdown is not needed."
    echo -e "\t    1.If this option is not passed,only update <lastmod> for the home index url which is \"https://asplingzhahg.github.io/\"."
    echo -e "\t    2.If the passed filename is not found create a new item for this filename in the sitemap.xml"
    echo -e "\t-h:show the usage"
}

cd $SCRIPT_ABS_PATH
cd ..
root_dir=$(pwd)
sitemap_xml="$root_dir/docs/sitemap.xml"

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

if [ ! -f $simtemap_xml ];then
    echo "Error:sitemap.xml is not existed at $sitemap_xml"
    exit 1
fi

# Get current date as yyyy-mm-dd format
date_yyyy_mm_dd=$(date '+%Y-%m-%d')
hh_mm_ss=$(date '+%H:%M:%S')

#Update sitemap.xml for specified url

#    <url>
#      <loc>https://asplingzhang.github.io/xxx/</loc>
#        <lastmod>2022-06-07T19:25:58+08:00</lastmod>
#    </url>
#   </urlset>

# The last item of sitemap.xml is always the home index url.
#    <url>
#      <loc>https://asplingzhang.github.io/</loc>
#        <lastmod>2022-06-07T19:25:58+08:00</lastmod>
#    </url>
#   </urlset>
function deleteHomeIndex() {
    # delete </urlset>
    gsed -i "/<\/urlset>/d" $sitemap_xml
    # delete </url>
    gsed -i '$d' $sitemap_xml
    # delete <lastmod> of home index url
    gsed -i '$d' $sitemap_xml
    # delete    <loc>https://asplingzhang.github.io/</loc>
    gsed -i '$d' $sitemap_xml
    #delete <url>
    gsed -i '$d' $sitemap_xml
}

# Add item for home index url with newest time.
function addHomeIndex() {
    echo "    <url>" >> $sitemap_xml
    echo "      <loc>https://asplingzhang.github.io/</loc>" >> $sitemap_xml
    hh_mm_ss=$(date '+%H:%M:%S')
    echo "      <lastmod>${date_yyyy_mm_dd}T${hh_mm_ss}+08:00</lastmod>" >> $sitemap_xml
    echo "    </url>" >> $sitemap_xml
    echo "</urlset>" >> $sitemap_xml
}

# Add new item rather than home index url.
function addNewItem() {
    echo "Add new item for:$filename"
    deleteHomeIndex

    echo "    <url>" >> $sitemap_xml
    echo "      <loc>https://asplingzhang.github.io/$filename/</loc>" >> $sitemap_xml
    hh_mm_ss=$(date '+%H:%M:%S')
    echo "      <lastmod>${date_yyyy_mm_dd}T${hh_mm_ss}+08:00</lastmod>" >> $sitemap_xml
    echo "    </url>" >> $sitemap_xml

    addHomeIndex
}

if [[ ! $filename == "" ]];then
    echo "Info:update sitemap.xml for item with partial url path:$filename,create a new one or update the existed one."
    filename_existed=$(grep -n $filename $sitemap_xml)
    if [[ $filename_existed == "" ]];then
        addNewItem
    else
        echo "Update item for:$filename"
        line_num=$(grep -n $filename $sitemap_xml | awk '{print $1}' | sed "s/://g")
        echo "line_num1:$line_num"
        line_num_next=$(($line_num+1))
        echo "line_num_next:$line_num_next"
        gsed -i "${line_num_next}d" $sitemap_xml
        gsed -i  "$line_num a \ \ \ \ \ \ <lastmod>${date_yyyy_mm_dd}T${hh_mm_ss}+08:00</lastmod>" $sitemap_xml
    fi
else
    echo "Warning:file name is empty.only update <lastmod> for the home index url which is \"https://asplingzhahg.github.io/\"."
    deleteHomeIndex
    addHomeIndex
fi

