#!/bin/sh

currentPath=$(pwd -P)
rootPath=$(cd "$(dirname "$0")";pwd -P)
echo "Root path: $rootPath"
cd $rootPath

function pack() {
	chartPath=$1
	chart=$(basename $chartPath)
	for versionPath in $chartPath/*;
	do
		version=$(basename $versionPath)
		echo "Packing $chart/$version"
		cp -R ./templates/1.0.0/templates $versionPath/templates
		cd $versionPath
		tar -czf ../../../packages/$chart-$version.tgz ./
		rm -rf ./templates
		cd - > /dev/null
		echo "Packed $chart-$version.tgz"
	done
}

for chartPath in ./stable/*;
do
	pack $chartPath
done

cd $currentPath
