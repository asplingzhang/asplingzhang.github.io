---
layout: default
title:  "Code snippets of shell script"
date:   2022-06-02 14:31:33 +0800
categories: shell
---

# Abstract
Code snippets of shell scripts.

# Checking file is existed or not

```shell
if [ -f "$file_path" ];then
fi
```

# Append output to end of file
```shell
echo "output" >> dst_file
```

# Substring in shell

```shell
string='My long string'
if [[ $string == *"My long"* ]]; then
  echo "It's there!"
fi
```

More details please see [substring](http://c.biancheng.net/view/1120.html)

Get string from first ocurrance for "chars"
```shell
 ${string#*chars}
```
Get string from last ocurrance for "chars"
```shell
${string##*chars}
```

# Rename all files in direcotry

```shell
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

```shell
#Usually,if header file exists "namespace ",it means this file has been changed to C++. So remove them.
if [ $(grep -c "namespace " $file) -ne 0 ];then
    regex=$(echo $file|sed "s#\/#\\\/#g")
    sed -i "/$regex/d" $PureC_file
fi
```

# Checking character is uppper or lower

```shell
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

```shell
ABS_PATH=$(readlink -f $0)
ABS_DIR=$(dirname $ABS_PATH)
```

# Import another script in shell

```shell
source absolute_path/import.sh
```

# Insert string at index of string

Insert at index 1 of string $string
```shell
sed -i "s/${string:0:1}\(${string:1}\)/${string:0:1}$insert\1/g"
```

# Use alias in shell scripts

```shell
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

```shell
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

# Append parameters(options) to shell
Sometimes,we need appending parameters(options) to a shell script.
- first of all,we decide which parameter(option) needed to be added to the target shell script.
- we use an array to contain all the parameters(options) and then pass it to the target shell script by calling `xxx.sh ${params[@]}`
```shell
params=("")
if [[ $enable_xx == "true" ]];then
    params+=(-x)
fi
if [[ $enable_xx_2 == "true" ]];then
    params+=(-f)
fi
echo -e "Parameters  is:${params[@]}"
xxx.sh ${params[@]}

```

# Define usage function and accpept user-input parameters(options) for shell
We can define parameters(options) for shell script.
- shell script accepts paramters(options) with or without specific value.

## Parameter(Option) without value
```shell
function usage() {
    echo "Shell function:It's an exmaple"
    echo ""
    echo "Usage:[-i input_parameters][-h help]"
    echo -e "\t-i:explaination for input parameter"
    echo -e "\t-h:show the usage"
    exit 1;
}


input_param_i_set="false"
while getopts "ih" arg; do
  case $arg in
    i)
      input_param_i_set="true"
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done

```

**NOTE:** take care about things below
- Define parameter(option) without colon followed
```shell
while getopts "ih" arg; do
```

## Parameter(Option) with value
```shell
function usage() {
    echo "Shell function:It's an exmaple"
    echo ""
    echo "Usage:[-i input_parameters][-h help]"
    echo -e "\t-i:explaination for input parameter"
    echo -e "\t-h:show the usage"
    exit 1;
}


input_param_i_value=""
while getopts "i:h" arg; do
  case $arg in
    i)
      input_param_i_value=${OPTARG}
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done

```

**NOTE:** take care about two things below
- Define parameter(option) with colon followed
```shell
while getopts "i:h" arg; do
```
- Get value of parameter(option) by
```shell
input_param_i_value=${OPTARG}
```

# echo with colorful fonts
Use `echo -e` to print colorful fonts.
```shell
echo -e "${RED}Error:${NOCOLOR}error happened,OMG."
```

## Color definitions
A list of values of color used in shell script.
```shell
#!/bin/bash
# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
```

# Get result of the last run shell script
Use `$?` to get the result of last run shell script.
```shell
last_runned_shell.sh
if [ $? -eq 0 ]; then
    echo "last shell run successfully."
fi

```

# Check if a string is empty in shell scrpit
Use `-z $string` to check if a string in shell scrpit is empty or not.
```shell
# check if string length is zero.
if [ -z $info ] ;then
    echo -e "${RED}Error:${NOCOLOR}info is empty."
    exit 1
fi
```

# Split a string to array in shell script
Split a string to array ,with a specific separator `$separator`
For exmaple,`separator="."`
```shell
info="10.2.3"
array=(${info//./ })
for num in ${array[@]}
do
    print_debug_info $num
done
```

# Define an array in sehll script
```shell
#list variables which defined all arches
all_arches=("arm64"
"armv7"
"i386"
"x86_64"
)

```

# Iterate an array in shell script
Use `${array[@]}` for iterating over an array in shell script.
```shell
for num in ${array[@]}
do
    print_debug_info $num
done
```

# Pass a multi-lines string to shell script
- Define a multi-lines string as below
- Use `''"$argrs"''` to pass it to the target shell script,otherwise,it will be failed.

```shell
args=$(cat <<-END
target_os="ios"
target_cpu="arm64"
END
)

gn gen out/ios --args=''"$args"'' --ide=xcode --script-executable=$python_path
```

# Handle result of command of which in shell script
- Command 'which python' may retrun zero string when executed in shell,so we need check the size of result firstly.

```shell
# command 'which python' may retrun zero string when executed in shell.
if [ -z $python_path ] || [[ $python_path == *"not found"* ]];then
   echo "python not found."
fi

```
