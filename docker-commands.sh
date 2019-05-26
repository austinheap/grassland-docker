#!/bin/bash

# support: do_default
do_default() {
    do_command "${FUNCNAME[0]:3}" || return 1

    do_validate_calibration && do_start || do_init
}

# command: do_version
do_version() {
    do_command "${FUNCNAME[0]:3}" && echo "$(get_version)"
}

# command: do_shell
do_shell() {
    do_command "${FUNCNAME[0]:3}" || return 1

    if do_validate; then
        /bin/bash || true
    else
        error "Sub-command failed: validate" && return 1
    fi
}

# command: do_start
do_start() {
    do_command "${FUNCNAME[0]:3}" || return 1

    do_validate && do_validate_lambda && do_validate_s3 && do_validate_calibration && test -f "${ENV_FILE}" && source "${ENV_FILE}"

    { cd /opt/node_lite/gui && npm run dev-external; } &
    { cd /opt/node_lite     && python3 multi_object_tracking.py --mode ONLINE --display 0 --num_workers $(nproc); } &
    wait -n
    pkill -P $$
}

# command: do_validate
do_validate() {
    do_command "${FUNCNAME[0]:3}" || return 1

    if   ! do_validate_variables; then error "Sub-command failed: validate:variables" && return 1;
    elif ! do_validate_versions;  then error "Sub-command failed: validate:versions"  && return 1;
    elif ! do_validate_aws;       then error "Sub-command failed: validate:aws"       && return 1;
    elif ! do_validate_camera;    then error "Sub-command failed: validate:camera"    && return 1;
    elif ! do_validate_data;      then error "Sub-command failed: validate:data"      && return 1;
    fi
}

# command: do_validate_variables
do_validate_variables() {
    do_command "${FUNCNAME[0]:3}" "VALIDATE_VARIABLES" || return 1

    local variables=(${1:-${VALIDATE_VARIABLES[@]}})
    local pass=0
    local none=1

    for variable in "${variables[@]}"; do
        if is_empty "${variable}"; then
            error "Variable '${variable}' is absent!"
            pass=1
        fi
        none=0
    done

    return $pass
}

# command: do_validate_versions
do_validate_versions() {
    do_command "${FUNCNAME[0]:3}" "VALIDATE_VERSIONS" || return 1

    local versions=(${1:-${VALIDATE_VERSIONS[@]}})
    local pass=0

    for version in "${versions[@]}"; do
        if is_empty "${version}"; then
            error "Version '${version}' is absent!" && return 1
        else
            case "${version}" in
                AWS_VERSION)
                    if ! aws --version | grep "aws-cli/${!version}" > /dev/null 2>&1; then
                        error "Invalid version: ${version}" && pass=1
                    fi
                    ;;
                NODE_VERSION)
                    if ! node --version | grep "${!version}" > /dev/null 2>&1; then
                        error "Invalid version: ${version}" && pass=1
                    fi
                    ;;
                NVM_VERSION)
                    true # intentionally skipped: 'nvm' not used after build
                    ;;
                OPENCV_VERSION)
                    if ! printf "import cv2\nprint(cv2.__version__)" | python3 | grep "${!version:0:4}" > /dev/null 2>&1; then
                        error "Invalid version: ${version}" && pass=1
                    fi
                    ;;
                SERVERLESS_VERSION)
                    if ! serverless --version | grep "${!version:-INVALID}" > /dev/null 2>&1; then
                        error "Invalid version: ${version}" && pass=1
                    fi
                    ;;
                *)
                    error "Version '${version}' not understood!" && pass=1
                    ;;
            esac
        fi
    done

    return $pass
}

# command: do_validate_camera
do_validate_camera() {
    local device="${1:-/dev/video0}"

    do_command "${FUNCNAME[0]:3}" && ls "${device}" > /dev/null 2>&1 && v4l2-ctl --list-devices | grep "${device}" > /dev/null 2>&1
}

# command: do_validate_aws
do_validate_aws() {
    do_command "${FUNCNAME[0]:3}" "AWS_DEFAULT_REGION" "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY"
}

# command: do_validate_data
do_validate_data() {
    do_command "${FUNCNAME[0]:3}" "EON_PATH" "EON_URL" "EON_HASH" "VENDORED_PATH" "VENDORED_URL" "VENDORED_HASH" || return 1

    local pass=1

    if [ -f "${EON_PATH}" ] && [ -f "${VENDORED_PATH}" ] ; then
        echo "${VENDORED_HASH}  ${VENDORED_PATH}" > "${VENDORED_PATH}.md5" && md5sum --check --quiet --strict "${VENDORED_PATH}.md5" &&
        echo "${EON_HASH}  ${EON_PATH}" > "${EON_PATH}.md5"                && md5sum --check --quiet --strict "${EON_PATH}.md5"      &&
        unzip -qq -t "${VENDORED_PATH}"

        pass=$?

        rm -f "${VENDORED_PATH}.md5" "${EON_PATH}.md5"
    fi

    return $pass
}

# command: do_validate_s3
do_validate_s3() {
    do_command "${FUNCNAME[0]:3}" "GRASSLAND_FRAME_S3_BUCKET" "GRASSLAND_MODEL_S3_BUCKET" &&
    sleep 5.0s                                                                            &&
    aws s3 ls s3://${GRASSLAND_FRAME_S3_BUCKET} > /dev/null 2>&1                          &&
    aws s3 ls s3://${GRASSLAND_MODEL_S3_BUCKET} > /dev/null 2>&1                          &&
    aws s3api get-bucket-lifecycle-configuration --bucket "${GRASSLAND_FRAME_S3_BUCKET}" > /dev/null 2>&1
}

# command: do_validate_lambda
do_validate_lambda() {
    do_command "${FUNCNAME[0]:3}"       &&
    cp "${ENV_FILE}.orig" "${ENV_FILE}" &&
    cd /opt/node_lite_object_detection  &&
    serverless info > /dev/null 2>&1    &&
    echo "export LAMBDA_DETECTION_URL=$(serverless info | grep "GET - https://" | rev | cut -d" " -f1 | rev)" > "${ENV_FILE}" &&
    source "${ENV_FILE}"
}

# command: do_validate_calibration
do_validate_calibration() {
    do_command "${FUNCNAME[0]:3}" "HOME"      &&
    test -d "${HOME}/.grassland"              &&
    test -d "${HOME}/.grassland/node_db"      &&
    test -f "${HOME}/.grassland/node_db/LOCK" &&
    printf "import plyvel\ndb = plyvel.DB('${HOME}/.grassland/node_db')\nfor key, value in db:\n    print(\"{0} : {1}\".format(key, value))\n" | python3 | grep "b'calibration'" > /dev/null 2>&1
}

# command: do_init
do_init() {
    do_command "${FUNCNAME[0]:3}" || return 1

    if   ! do_validate;         then error "Sub-command failed: validate"         && return 1;
    elif ! do_init_config;      then error "Sub-command failed: init:config"      && return 1;
    elif ! do_init_s3;          then error "Sub-command failed: init:s3"          && return 1;
    elif ! do_init_lambda;      then error "Sub-command failed: init:lambda"      && return 1;
    elif ! do_init_calibration; then error "Sub-command failed: init:calibration" && return 1;
    fi
}

# command: do_init_config
do_init_config() {
    do_command "${FUNCNAME[0]:3}" "AWS_DEFAULT_REGION" "GRASSLAND_MODEL_S3_BUCKET" "GRASSLAND_FRAME_S3_BUCKET"  &&

    # node_lite_object_detection: serverless.yml
    cd /opt/node_lite_object_detection && git show HEAD:./serverless.yml > serverless.yml.tmp                   &&
    sed -i -e 's/region\: ca-central-1/region\: '${AWS_DEFAULT_REGION}'/' serverless.yml.tmp                    &&
    sed -i -e 's/\[REPLACE_ME\: GRASSLAND_MODEL_BUCKET\]/'${GRASSLAND_MODEL_S3_BUCKET}'/' serverless.yml.tmp    &&
    sed -i -e 's/\[REPLACE_ME\: GRASSLAND_FRAME_S3_BUCKET\]/'${GRASSLAND_FRAME_S3_BUCKET}'/' serverless.yml.tmp &&
    sed -i -e 's/\[REPLACE_ME\: path\/to\/model\/file\/inside\/bucket\/\]//' serverless.yml.tmp                 &&
    mv serverless.yml.tmp serverless.yml                                                                        &&

    # node_lite_object_detection: env_var.sh
    cd /opt/node_lite_object_detection && git show HEAD:./env_var.sh > env_var.sh.tmp                           &&
    sed -i -e 's/\[REPLACE_ME\: GRASSLAND_MODEL_BUCKET\]/'${GRASSLAND_MODEL_S3_BUCKET}'/' env_var.sh.tmp        &&
    sed -i -e 's/\[REPLACE_ME\: path\/to\/model\/file\/inside\/bucket\/\]//' env_var.sh.tmp                     &&
    chmod +x env_var.sh.tmp && mv env_var.sh.tmp env_var.sh
}

# command: do_init_s3
do_init_s3() {
    do_command "${FUNCNAME[0]:3}" "GRASSLAND_FRAME_S3_BUCKET" "GRASSLAND_MODEL_S3_BUCKET" "EON_PATH" &&
    do_destroy_s3                                                                                    &&
    aws s3 mb s3://${GRASSLAND_FRAME_S3_BUCKET} --region "${AWS_DEFAULT_REGION}" > /dev/null 2>&1    &&
    aws s3 mb s3://${GRASSLAND_MODEL_S3_BUCKET} --region "${AWS_DEFAULT_REGION}" > /dev/null 2>&1    &&
    sleep 5.0s                                                                                       &&
    aws s3 cp "${EON_PATH}" s3://${GRASSLAND_MODEL_S3_BUCKET}/ --quiet --no-progress --only-show-errors --acl public-read                     &&
    echo '{"Rules":[{"ID": "expire-frames-after-24-hrs","Status": "Enabled","Filter": {},"Expiration":{"Days": 1}}]}' > /tmp/lifecycle.json   &&
    aws s3api put-bucket-lifecycle-configuration --bucket "${GRASSLAND_FRAME_S3_BUCKET}" --lifecycle-configuration file:///tmp/lifecycle.json &&
    rm -f /tmp/lifecycle.json &&
    do_validate_s3
}

# command: do_init_data
do_init_data() {
    do_command "${FUNCNAME[0]:3}" "EON_PATH" "EON_URL" "VENDORED_PATH" "VENDORED_URL"                   &&
    do_destroy_data                                     &&
    mkdir -p "$(dirname "${VENDORED_PATH}")"            && mkdir -p "$(dirname "${EON_PATH}")"          &&
    curl -s -o "${VENDORED_PATH}.tmp" "${VENDORED_URL}" && mv "${VENDORED_PATH}.tmp" "${VENDORED_PATH}" &&
    curl -s -o "${EON_PATH}.tmp" "${EON_URL}"           && mv "${EON_PATH}.tmp" "${EON_PATH}"           &&
    do_validate_data                                    &&
    rm -rf "/opt/node_lite_object_detection/vendored"   &&
    unzip -qq "${VENDORED_PATH}" -d "/opt/node_lite_object_detection"
}

# command: do_init_lambda
do_init_lambda() {
    do_command "${FUNCNAME[0]:3}"       &&
    do_destroy_lambda                   &&
    cd /opt/node_lite_object_detection  &&
    serverless deploy  > /dev/null 2>&1 &&
    do_validate_lambda
}

# command: do_init_calibration
do_init_calibration() {
    do_command "${FUNCNAME[0]:3}" || return 1

    do_validate && do_validate_lambda && do_validate_s3 && do_destroy_calibration && test -f "${ENV_FILE}" && source "${ENV_FILE}"

    { cd /opt/node_lite/gui && npm run dev-external; } &
    { cd /opt/node_lite     && python3 multi_object_tracking.py --mode CALIBRATING --display 1 --num_workers $(nproc); } &
    wait -n
    pkill -P $$

    do_validate_calibration
}

# command: do_destroy
do_destroy() {
    do_command "${FUNCNAME[0]:3}" || return 1

    if   ! do_destroy_lambda;      then error "Sub-command failed: destroy:lambda"      && return 1;
    elif ! do_destroy_s3;          then error "Sub-command failed: destroy:s3"          && return 1;
    elif ! do_destroy_data;        then error "Sub-command failed: destroy:data"        && return 1;
    elif ! do_destroy_calibration; then error "Sub-command failed: destroy:calibration" && return 1;
    fi
}

# command: do_destroy_calibration
do_destroy_calibration() {
    do_command "${FUNCNAME[0]:3}" "HOME"

    rm -rf "/tmp/gl_tmp_tracklets_db" "${HOME}/.grassland/gl_tracklets_db" "${HOME}/.grassland/node_db"

    ! do_validate_calibration
}

# command: do_destroy_data
do_destroy_data() {
    do_command "${FUNCNAME[0]:3}" "EON_PATH" "VENDORED_PATH" || return 1

    rm -rf "${EON_PATH}" "${VENDORED_PATH}"
    rm -rf "$(dirname "${EON_PATH}")" "$(dirname "${VENDORED_PATH}")"

    ! do_validate_data
}

# command: do_destroy_s3
do_destroy_s3() {
    do_command "${FUNCNAME[0]:3}" "GRASSLAND_FRAME_S3_BUCKET" "GRASSLAND_MODEL_S3_BUCKET" || return 1

    if aws s3 ls s3://${GRASSLAND_FRAME_S3_BUCKET} > /dev/null 2>&1; then aws s3 rb s3://${GRASSLAND_FRAME_S3_BUCKET} --force > /dev/null 2>&1; fi
    if aws s3 ls s3://${GRASSLAND_MODEL_S3_BUCKET} > /dev/null 2>&1; then aws s3 rb s3://${GRASSLAND_MODEL_S3_BUCKET} --force > /dev/null 2>&1; fi

    ! do_validate_s3
}

# command: do_destroy_lambda
do_destroy_lambda() {
    do_command "${FUNCNAME[0]:3}" "AWS_DEFAULT_REGION" "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" || return 1

    if do_validate_lambda; then
        cd /opt/node_lite_object_detection && serverless remove > /dev/null 2>&1
    fi

    ! do_validate_lambda
}

### EOF ###
