#!/bin/bash

# global: shared
declare -a ERRORS=()

# global: validation
declare -a VALIDATE_VARIABLES=("AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_DEFAULT_REGION" "LAMBDA_DETECTION_URL" "GRASSLAND_FRAME_S3_BUCKET" "MapboxAccessToken")
declare -a VALIDATE_VERSIONS=("OPENCV_VERSION" "NODE_VERSION" "NVM_VERSION" "SERVERLESS_VERSION" "AWS_VERSION")

### EOF ###
