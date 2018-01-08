#!/bin/bash

# Copyright 2018 Caicloud Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

echo "Start to build charts into $OUTPUT_DIR from $INPUT_DIR"
echo "Template: $TEMPLATES_DIR/$TEMPLATE_VERSION"
echo "Image domain: $IMAGE_DOMAIN"
echo "Force update: $FORCE_UPDATE"
tmp=/tmp/charts/
templates=$TEMPLATES_DIR/$TEMPLATE_VERSION/templates

function packChart() {
  chartPath=$1
  chart=$(basename $chartPath)
  for versionPath in $chartPath/*; do
    version=$(basename $versionPath)
    output=$OUTPUT_DIR/$chart/$version
    if [[ ! -d $output || $FORCE_UPDATE == "true" ]]; then
      echo "Packing $chart/$version"

      if [[ $IMAGE_DOMAIN != "" ]]; then
        sed -i -E "s|(image:.*)cargo.caicloudprivatetest.com(.*)|\1$IMAGE_DOMAIN\2|g" $versionPath/values.yaml
      fi

      mkdir -p $output
      cp -R $templates $versionPath/templates
      tar -czf $output/chart.tgz -C $versionPath .
      cat $versionPath/Chart.yaml | ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load(ARGF))' >$output/metadata.dat
      cat $versionPath/values.yaml | ruby -ryaml -rjson -e 'puts JSON.generate(YAML.load(ARGF))' >$output/values.dat
      echo -n "SUCCESS" >$output/.status

      echo "Packed $chart-$version.tgz"
    else
      echo "Ignore $chart/$version"
    fi
  done
}

function generate() {
  # Copy input to tmp dir.
  mkdir -p $tmp
  mkdir -p $OUTPUT_DIR
  cp -R $INPUT_DIR/* $tmp
  for chartPath in $tmp/*; do
    packChart $chartPath
  done
  rm -rf $tmp
}

generate
