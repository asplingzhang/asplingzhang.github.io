---
layout: default
title:  "Code snippets of shell script"
date:   2022-06-02 14:31:33 +0800
categories: shell
---

# Abstract
Code snippets of shell scipts.

# Checking file is existed or not

```Shell
if [ -f "$file_path" ];then
fi
```

# Append output to end of file
~~~
echo "output" >> dst_file
~~~

# Substring in shell

```Shell
string='My long string'
if [[ $string == *"My long"* ]]; then
  echo "It's there!"
fi
```

More details please see [substring](http://c.biancheng.net/view/1120.html)

Get string from first ocurrance for "chars"
```Shell
 ${string#*chars}
```
Get string from last ocurrance for "chars"
```Shell
${string##*chars}
```

# Rename all files in direcotry

```Shell
renameFileNameInDirRecursively(){
     if [[ $1 == "" ]]; then
       echo "Error:root_path is empty "
       exit
     elif [[ $2 == "" ]];then
       echo "Error:src file name is not set"
       exit
     elif [[ $3 == "" ]];then
       echo "Error:dst file name is not set"
       exit
     else
         cd $1
         for file in $(find . -type f -name $2); do
             mv $file $(echo "$file" | sed "s/$2/$3/");
         done
     fi
 }
```

# Checking if file has specific string

```Shell
#Usually,if header file exists "namespace ",it means this file has been changed to C++. So remove them.
if [ $(grep -c "namespace " $file) -ne 0 ];then
    regex=$(echo $file|sed "s#\/#\\\/#g")
    sed -i "/$regex/d" $PureC_file
fi
```

### Checking character is uppper or lower

```Shell
cat $symbols_file_uniq | while read symbol;do
       # First, get the first character.
       first=${symbol:0:1}
       #echo $first
       #echo $symbol
       case $first in
       [[:upper:]])
         #echo "upper"
         addPrefixToExactString.sh $1 $symbol $UpperPrefix
         ;;
       [[:lower:]])
         #echo "lower"
         addPrefixToExactString.sh $1 $symbol $LowerPrefix
         ;;
       *)
           echo -e "${RED}Error${NOCOLOR}:unexpected character "
           exit
           ;;
       esac
```

# Get absolute path of executed script

```Shell
ABS_PATH=$(readlink -f $0)
ABS_DIR=$(dirname $ABS_PATH)
```

# Import another script in shell

```Shell
source absolute_path/import.sh
```

# Insert string at index of string

Insert at index 1 of string $string
~~~
sed -i "s/${string:0:1}\(${string:1}\)/${string:0:1}$insert\1/g"
~~~

# Use alias in shell scripts

```Shell
OS_TYPE=$(uname)
echo -e ${GREEN} Current OS is:$OS_TYPE${NOCOLOR}
if [[ $OS_TYPE == "Darwin" ]]; then
  echo "It's OSX!"
  #macOS MUST use gsed rather than sed.
  gsed_installed=$(which gsed)
  if [[ $gsed_installed == *"not found"* ]]; then
    echo -e "${RED}Error:gsed is not installed,please install gsed firstly.${NOCOLOR}"
    exit
  fi
  #To make the scripts as same as possible on different platform(linux/darwin),use alias here
  shopt -s expand_aliases
  alias sed='gsed'
fi

```

# Make git using language of english in shell scripts

```Shell
LANG=en_US.UTF-8
```

# Get multi lines string into a variable

If you're trying to get the string into a variable, another easy way is something like this:
```shell
USAGE=$(cat <<-END
    This is line one.
    This is line two.
    This is line three.
END
)
```

If you indent your string with tabs (i.e., '\t'), the indentation will be stripped out. If you indent with spaces, the indentation will be left in.

NOTE: It is significant that the last closing parenthesis is on another line. The END text must appear on a line by itself.

# Append variable to shell

```shell
params=("")
if [[ $enable_phpl == "true" ]];then
    params+=(-p)
fi
if [[ $enable_file_video_capturer == "true" ]];then
    params+=(-f)
fi
echo -e "Parameters  is:${params[@]}"
xxx.sh ${params[@]}

```

