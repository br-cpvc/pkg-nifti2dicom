#!/usr/bin/env bash
set -e
#set -x

cwd=`pwd`
itk_dir_prefix=$1
itk_version=$2
outputdir=$3
itk_dir="$outputdir/$itk_dir_prefix-$itk_version"
itk_pkg="$itk_dir_prefix-$itk_version.tar.gz"

url=https://github.com/InsightSoftwareConsortium/ITK/archive/refs/tags
if [ ! -f $itk_pkg ]; then
	wget $url/v$itk_version.tar.gz -O $itk_pkg
fi
#md5sum $itk_pkg > $itk_pkg.md5sum
md5sum -c $itk_pkg.md5sum

if [ ! -d $itk_dir ]; then
	mkdir -p ${itk_dir}
	tar -zxf ${itk_pkg} --directory ${itk_dir} --strip-components=1
fi
