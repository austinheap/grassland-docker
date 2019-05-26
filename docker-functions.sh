#!/bin/bash

# support: get_version
get_version() {
    echo -n "${VERSION:-dev-master}"
}

# support: do_command
do_command() {
    local name="$(echo -n "${1/_/:}")"
    shift
    local variables=($@)

    echo "do_command(${name}): ${variables[@]:-<empty>}"

    for variable in "${variables[@]}"; do
        if is_empty "${variable}"; then
            error "FAIL Variable '${variable}' is missing, invalid, or contains the default value: ${!variable:-(empty)}"
            return 1
        fi
    done

    return 0
}

# support: error
error() {
    ERRORS+=("${1}")
}

# support: is_declared
is_declared() {
    { [[ -n ${!1+anything} ]] || declare -p $1 &>/dev/null;}
}

# support: is_unset
is_unset() {
    { [[ -z ${!1+anything} ]] && ! declare -p $1 &>/dev/null;} 
}

# support: is_empty
is_empty() {
    is_unset "${1}" && ! is_declared "${1}"
}

### EOF ###
