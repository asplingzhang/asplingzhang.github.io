---
layout: default
title: "How to upload webrtc source code to custom git repository using git submodule"
date: 2022-06-30 19:26:44 +0800
categories: webrtc
---

# Abstract
The source code of WebRTC is too large to upload it as one git repository,as there is a size limit for single git repository.
This document describes uploading source code of WebRTC to your own git repository using git submodule.

# Strategy
1. Upload codes rather than `third_party` to one git repository,named `rtc.git`.
2. Upload codes of `third_party` to other git repositories,creating a git repository for each sub-directory of `third_party`.
3. Create a git repository named `third_party.git` and make it as the submodule of `rtc.git`.
4. Make git repositories created in step 2 as git submodules of `third_party.git`.

```c++
rtc.git
|---src
|     |----third_party(git submodule)
|          |----opus(git submodule)
|          |----libyuv(git submodule)
|          |----libaom(git submodule)
|          |----..... and so on(git submodule)
```

# Add git submodules
## Add `thir_party.git` as submodule of rtc.git
```shell
 cd root_of_rtc.git
 git submodule add -b branch_name url_of_third_party.git src/third_party
```
- specify your branch name by `-b` option
- specify the location of `third_party.git`.

## Add other git repositories as git submodules of third_party.git
For example,we add `libyuv.git` as submodule of `third_party.git` using commands below.
```shell
 cd root_of_third_party.git
 git submodule add -b branch_name url_of_libyuv.git libyuv
```

As there are too many repositorires we need adding,so write a helper shell to finish the job.
```shell
#!/bin/bash
#this script do things below
#1) add git submodule for all third party libraries
#2) at the mean time ,config a spesific branch name for all the libraries

#parameter define
#$1:dir of third_party
#$2:file contailing names of all third party libraries
#$3:branch name for submodules
if [[ $1 == "" ]]; then
  echo -e "${RED}Error${NOCOLOR}:root_path is empty "
  exit 1
elif [[ $2 == "" ]];then
  echo -e "${RED}Error${NOCOLOR}:file containing names of libraries is not set"
  exit 1
elif [[ $3 == "" ]];then
  echo -e "${RED}Error${NOCOLOR}:new branch name is not set"
  exit
elif [[ $1 == *"third_party"* ]];then
 echo -e "${GREEN}Start adding git submodule for all libraries under directory${NOCOLOR} :$1"
 root_path=$1
 runForSuccess "cd $root_path"
 cat $2 | while read Line;do
   echo -e "${ORANGE}Now adding git submodule $Line${NOCOLOR}"
   git submodule add -f git@code.alipay.com:MRTC-Third-Party/$Line.git
   git config -f .gitmodules submodule.$Line.branch $3
 done
   echo -e "${GREEN}Adding git submodule for all libraries under directory${NOCOLOR}:$1 ${GREEN}finished${NOCOLOR}"
else
  echo -e "${RED}Error${NOCOLOR}:MUST be processed at third_party directory"
fi

```

Here is the shell listing all the names of directories under `src/third_party`,the name of each directory is the same with the name of git repository we created for it.
```shell
cd third_party
ls -d \*/ > all_names_of_libs.txt
sort all_names_of_libs.txt | uniq > all_names_of_libs_uniq.txt
```

# Update git submodules
When we cloned `rtc.git`,all the git submodules are not cloned.we need initlializing all git submodules and updating them.
```shell
cd root_of_rtc.git
git submodule update --init
```

Then all submodules are initliazed and updated.it may take a long time to clone all of them.

However,the checked out commit of submodules may not be the one we expected as the original updating triggled by the initialization.
We can update then once again to avoid this problem.
```shell
git submodule update  --remote --recursive 

```

# Copyright notice
All Rights Reserved.Any reprint/reproduce/redistribution of this article MUST indicate the source. 
