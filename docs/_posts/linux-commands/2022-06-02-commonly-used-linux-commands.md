---
layout: default
title:  "Commonly used linux commands"
date:   2022-06-02 14:31:33 +0800
categories: linux-commands
---

# Abstract
Commonly used linx commands.

# find . exclude directory

Use the -prune switch. For example, if you want to exclude the misc directory just add a -path ./misc -prune -o to your find command:
```shell
$ find . -path ./misc -prune -false -o -name '*.txt'
```
Here is an example with multiple directories:
```shell
$ find . -type d \( -path dir1 -o -path dir2 -o -path dir3 \) -prune -false -o -name '*.txt'
```

# List all unique third_party libraries

```shell
$ cd third_party
$ ls -d \*/ > all_libs_m91.txt
$ sort all_libs_m91.txt | uniq > all_libs_m91_uniq.txt
```


# Delete all git history

```shell
$ cd src
$ find . -name ".git"|xargs rm -rf
```

Delete .gitignore file,except one in src.
```shell
$ find . -name ".gitignore"|xargs rm -rf
```

# Find files and append something to the end if it

```shell
$ find . -name "test.txt"|xargs sed -i '$a #VS code\t_'
```

# ls only files not directories

ls -p lets you show / after the folder name, which acts as a tag for you to remove.
```shell
$ ls -p dir |grep -v /
```

# Upgrade git to newest stable version in ubuntu

For Ubuntu, this PPA provides the latest stable upstream Git version
```shell
$ sudo add-apt-repository ppa:git-core/ppa
$ sudo apt update
$ sudo apt install git
```

# sed
##  sed remove lines not match the reglex pattern

Remove lines not start with a-z|A-Z|0-9|_
```shell
$  gsed -i '/[^a-z\|A-Z\|0-9\|_]/d' ddd
```

## sed remove lines not start with specific string

Remove lines not started with "namespace" in file "ddd"
```shell
$ gsed -i '/^namespace/!d' ddd
```

## sed delete leading whitespace

[sed_remove_whitespace](https://linuxhint.com/sed_remove_whitespace/)
```shell   
$ gsed -i "s/^[ \t]*//g" filename
```

## Delete all the whitespace at the tail
```shell
$ gsed -i "s/[ \t]*$//g" filename
```

## sed replace whole words
Whole word surrounded with "\<word\>"
For example,replace webrtc:: to xwebrtc::
```shell
$ gsed -i 's/\<webrtc::\>/xwebrtc::/g' ddd
```

## sed delete empty lines
```shell
$ sed -i "/^$/d" filename
```

## sed find and replace with string which has slashes

For example,string="src/xx/xx/aa",we need replacing it to "src\/xx\/xx\/aa"
```
regex=$(echo string|sed "s#\/#\\\/$dst#g")
sed -i "/$regex/d" filename
```

## sed delete lines not containing specific string
```shell
$ sed -i '/$string/!d' file
```
## sed delete first line of file 
```shell
sed -i '1d' filename
```

# Read .dwo file or DWARF
```shell
$ readelf -ahW xx.dwo
```


# Trust all source at macOS

问题：无法打开xxx，因为无法验证开发者...
```shell
$  sudo spctl --master-disable
```

# Add sudo permission for user in linux
```shell
$ sudo usermod -a -G sudo 用户名
```

# ssh login without password for linux

```shell
$ ssh-copy-id -i ~/.ssh/id_rsa.pub username@30.19.109.131
```

