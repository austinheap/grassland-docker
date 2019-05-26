#!/bin/bash

set -e

for include in /docker-*.sh; do
    if [ "$(basename "${include}")" != "$(basename "${BASH_SOURCE[0]}")" ]; then
        test -f "/.$(basename "${include}").md5" && md5sum --check --quiet "/.$(basename "${include}").md5" || echo "File corrupt: ${include}"
        source "${include}"
    fi
done

! is_empty "CONTAINER_DEBUG" && set -x
  is_empty "CONTAINER_QUIET" && printf "\n          grassland-docker  .:.  %s\n-----------------------------------------------------\n" "$(get_version)"

[ -f /opt/env.sh ]    && source /opt/env.sh
[ -d /opt/node_lite ] && cd /opt/node_lite

# cmd: exec
if [ -f "$1" ] && [ -x "$1" ];          then exec "$@"               || error "Command failed: ${@}"

# cmd: version/shell/start
elif [ "$1" = "default" ];              then do_default              || error "Command failed: ${@}"
elif [ "$1" = "version" ];              then do_version              || error "Command failed: ${@}"
elif [ "$1" = "shell" ];                then do_shell                || error "Command failed: ${@}"
elif [ "$1" = "start" ];                then do_start                || error "Command failed: ${@}"

# cmd: init:*
elif [ "$1" = "init" ];                 then do_init                 || error "Command failed: ${@}"
elif [ "$1" = "init:calibration" ];     then do_init_calibration     || error "Command failed: ${@}"
elif [ "$1" = "init:data" ];            then do_init_data            || error "Command failed: ${@}"
elif [ "$1" = "init:config" ];          then do_init_config          || error "Command failed: ${@}"
elif [ "$1" = "init:lambda" ];          then do_init_lambda          || error "Command failed: ${@}"
elif [ "$1" = "init:s3" ];              then do_init_s3              || error "Command failed: ${@}"

# cmd: destroy:*
elif [ "$1" = "destroy" ];              then do_destroy              || error "Command failed: ${@}"
elif [ "$1" = "destroy:calibration" ];  then do_destroy_calibration  || error "Command failed: ${@}"
elif [ "$1" = "destroy:data" ];         then do_destroy_data         || error "Command failed: ${@}"
elif [ "$1" = "destroy:lambda" ];       then do_destroy_lambda       || error "Command failed: ${@}"
elif [ "$1" = "destroy:s3" ];           then do_destroy_s3           || error "Command failed: ${@}"

# cmd: validate:*
elif [ "$1" = "validate" ];             then do_validate             || error "Command failed: ${@}"
elif [ "$1" = "validate:aws" ];         then do_validate_aws         || error "Command failed: ${@}"
elif [ "$1" = "validate:calibration" ]; then do_validate_calibration || error "Command failed: ${@}"
elif [ "$1" = "validate:camera" ];      then do_validate_camera      || error "Command failed: ${@}"
elif [ "$1" = "validate:data" ];        then do_validate_data        || error "Command failed: ${@}"
elif [ "$1" = "validate:lambda" ];      then do_validate_lambda      || error "Command failed: ${@}"
elif [ "$1" = "validate:s3" ];          then do_validate_s3          || error "Command failed: ${@}"
elif [ "$1" = "validate:variables" ];   then do_validate_variables   || error "Command failed: ${@}"
elif [ "$1" = "validate:versions" ];    then do_validate_versions    || error "Command failed: ${@}"

# cmd: help
else
    echo
    echo "help                 - Display this help"
    echo "version              - Display the version"
    echo "shell                - Open a shell"
    echo "start                - Start the service"
    echo
    echo "init                 - Initialize instance"
    echo "init:calibration     - Initialize calibration data"
    echo "init:config          - Initialize config files"
    echo "init:data            - Initialize data files"
    echo "init:lambda          - Initialize AWS Lambda stack"
    echo "init:s3              - Initialize AWS S3 buckets"
    echo
    echo "destroy              - Destroy instance"
    echo "destroy:calibration  - Destroy calibration data"
    echo "destroy:data         - Destroy data files"
    echo "destroy:lambda       - Destroy AWS Lambda stack"
    echo "destroy:s3           - Destroy AWS S3 buckets"
    echo
    echo "validate             - Validate instance"
    echo "validate:aws         - Validate AWS credentials"
    echo "validate:calibration - Validate calibration device"
    echo "validate:camera      - Validate camera device"
    echo "validate:data        - Validate downloaded data"
    echo "validate:lambda      - Validate AWS Lambda stack"
    echo "validate:s3          - Validate AWS S3 buckets"
    echo "validate:variables   - Validate environmental variables"
    echo "validate:versions    - Validate package versions"
    echo
    test "${1}" = "help" && exit 0 || exit 1
fi

is_empty "CONTAINER_QUIET" && (test ${#ERRORS[@]} -eq 0 && echo "${1}: TRUE (${#ERRORS[@]})" || (printf '[!] %s\n' "${ERRORS[@]}" && echo "${1}: FALSE (${#ERRORS[@]})"))

exit ${#ERRORS[@]}

### EOF ###
