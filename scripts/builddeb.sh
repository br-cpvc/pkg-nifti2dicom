#!/usr/bin/env bash
set -e

BUILD_NUMBER=$1

script_dir=$(dirname "$0")
cd ${script_dir}/..

outputdir=output

old_method=true
if [[ "$old_method" == true ]]; then
    # use a hardcoded version of itk, downloaded
    # as a tar ball and compiled from source
    #itk_version="4.5.0"
    #itk_version="4.7.2"
    itk_version=4.8.2
    itk_dir_prefix="InsightToolkit"
    source ${script_dir}/dwn_itk.sh $itk_dir_prefix $itk_version $outputdir

    itk_dir="$outputdir/$itk_dir_prefix-$itk_version"
else
    # use git submodule checkout version of itk,
    # needs to have added itk as git submodule deps/ITK
    itk_dir="deps/ITK"
fi

# build dependencies
source ${script_dir}/build_itk.sh $itk_dir


srcdir="nifti2dicom-0.4.8"
if [ -d $srcdir ]
then
    rm -rf $srcdir
fi

if [ ! -e nifti2dicom_0.4.8.orig.tar.gz ]
then
wget https://launchpad.net/ubuntu/+archive/primary/+files/nifti2dicom_0.4.8.orig.tar.gz
fi
md5sum -c nifti2dicom_0.4.8.orig.tar.gz.md5sum
tar -zxf nifti2dicom_0.4.8.orig.tar.gz

if [ ! -e nifti2dicom_0.4.8-1build2.debian.tar.xz ]
then
# from: http://old-releases.ubuntu.com/ubuntu/pool/universe/n/nifti2dicom/
wget https://launchpad.net/ubuntu/+archive/primary/+files/nifti2dicom_0.4.8-1build2.debian.tar.xz
fi
md5sum -c nifti2dicom_0.4.8-1build2.debian.tar.xz.md5sum
tar -xf nifti2dicom_0.4.8-1build2.debian.tar.xz --directory=$srcdir
mkdir -p original
cp -r $srcdir/debian original/
cp debian/{changelog,control,nifti2dicom-noreorient.install,nifti2dicom.install} $srcdir/debian/
cp debian/patches/precise-disable-gui.patch $srcdir/debian/patches/
set +e
diff -r original/debian $srcdir/debian  # print the changes made
set -e

version="0.4.8-1build3"
package="nifti2dicom-noreorient"
arch="amd64"

#date=`date -u +%Y%m%d`
#echo "date=$date"

#gitrev=`git rev-parse HEAD | cut -b 1-8`
gitrevfull=`git rev-parse HEAD`
gitrevnum=`git log --oneline | wc -l | tr -d ' '`
#echo "gitrev=$gitrev"

buildtimestamp=`date -u +%Y%m%d-%H%M%S`
hostname=`hostname`
echo "build machine=${hostname}"
echo "build time=${buildtimestamp}"
echo "gitrevfull=$gitrevfull"
echo "gitrevnum=$gitrevnum"

debian_revision="${gitrevnum}"
upstream_version="${version}"
echo "upstream_version=$upstream_version"
echo "debian_revision=$debian_revision"

packageversion="${upstream_version}-github${debian_revision}"
packagename="${package}_${packageversion}_${arch}"
echo "packagename=$packagename"
packagefile="${packagename}.deb"
echo "packagefile=$packagefile"

rm -f ${package}_*.deb
sed -i 's/nifti2dicom ('${upstream_version}'/nifti2dicom ('${packageversion}'/' $srcdir/debian/changelog

echo "Creating .deb file: $packagefile"
cd $srcdir
patch -p0 < debian/patches/precise-disable-gui.patch
ITK_DIR=${script_dir}/../${itk_dir}/build fakeroot debian/rules binary
cd ..

dpkg -I $packagefile
