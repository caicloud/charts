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

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in pipeline.
set -o pipefail

echo ">>>> Testing build charts"

export OUTPUT_DIR=./bin/release
export INPUT_DIR=./stable/release
export APPLICATION_OUTPUT_DIR=./bin/application
export APPLICATION_INPUT_DIR=./stable/application
export TEMPLATES_DIR=./templates
export TEMPLATE_VERSION="1.0.0"
export IMAGE_DOMAIN=cargo.caicloudprivatetest.com
export FORCE_UPDATE=true

build/charts/build.sh
