#!/bin/bash
cd `dirname ${0}`

## -------------------------------------------------------------------------
##  Constants
## -------------------------------------------------------------------------

WVM_DIR=".wvm"
WVM_EXEC_NAME="${0}"



## -------------------------------------------------------------------------
##  Private functions
## -------------------------------------------------------------------------

wvm_check_init() {
    if ! [ -d "${WVM_DIR}" ]; then
        echo "Error: Warsow version manager was not initialized."
        echo "Do this so by running: wvm init"
        exit
    fi
}

wvm_get_current_version() {
    if [ -d "versions/${1}" ]; then
        cat ${WVM_DIR}/version
    fi
}

wvm_set_current_version() {
    echo ${1} > ${WVM_DIR}/version
}

wvm_get_current_profile() {
    local version=`wvm_get_current_version`
    if [ -d "profiles/${version}/${1}" ]; then
        cat ${WVM_DIR}/profile
    fi
}

wvm_set_current_profile() {
    echo ${1} > ${WVM_DIR}/profile
}

wvm_get_local_versions() {
    ls versions
}

wvm_string_to_local_version() {
    if [ -d "versions/${1}" ]; then
        echo ${1}
        return
    fi
    if [ -d "versions/v${1}" ]; then
        echo v${1}
        return
    fi
}

wvm_update_symlinks() {
    rm -f current
    rm -f profiles/current
    rm -f versions/current
    local profile=`wvm_get_current_profile`
    local version=`wvm_get_current_version`
    if [ -n "${profile}" ] && [ -d "profiles/${version}/${profile}" ]; then
        ln -s ${version}/${profile} profiles/current
        ln -s profiles/current current
    fi
    if [ -n "${version}" ] && [ -d "versions/${version}" ]; then
        ln -s ${version} versions/current
    fi
}

wvm_launch() {
    local version=`wvm_get_current_version`
    local profile=`wvm_get_current_profile`
    if [ -z "${version}" ]; then
        echo "Error: No version is in use!"
        return 1
    fi
    if [ -z "${profile}" ]; then
        echo "Error: No profile selected!"
        return 1
    fi
    local path_bin="./versions/${version}"
    local path_cd="./versions/${version}"
    local path_data="./profiles/${version}/${profile}"
    local arch=`uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc/ -e s/sparc64/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/alpha/axp/`
    local executable="`basename \"${1}\"`.$arch"

    shift

    if [ ! -e "${path_bin}/$executable" ]; then
        echo "Error: Executable for system '$arch' not found"
        return 1
    fi

    "${path_bin}/${executable}" \
        +set fs_basepath "${path_data}" \
        +set fs_cdpath "${path_cd}" \
        +set fs_usehomedir "0" \
        ${@}
}



## -------------------------------------------------------------------------
##  Public functions
## -------------------------------------------------------------------------

wvm_init() {
    mkdir -p ${WVM_DIR}
    mkdir -p versions
    mkdir -p profiles
    echo > ${WVM_DIR}/profile
    echo > ${WVM_DIR}/version
    wvm_update_symlinks
}

wvm_profile() {
    wvm_check_init
    if [ ${#} -lt 1 ]; then
        echo -n "Current profile: "
        wvm_get_current_profile
    else
        local profile="${1}"
        local version=`wvm_get_current_version`
        if [ "${version}" = "" ]; then
            echo "Can't create profile - no version is in use!"
            return 1
        fi
        mkdir -p profiles/${version}/${profile}
        wvm_set_current_profile ${profile}
        wvm_update_symlinks
        echo "Using profile '${profile}' on version '${version}'"
    fi
}

wvm_list() {
    wvm_check_init
    echo "Installed versions:"
    wvm_get_local_versions
}

wvm_current() {
    echo -n "Current version: "
    wvm_get_current_version
}

wvm_use() {
    if [ ${#} -lt 1 ]; then
        echo "Help not implemented yet"
        exit 2
    fi
    local version=`wvm_string_to_local_version ${1}`
    if [ -z "${version}" ]; then
        echo "Version ${version} was not found"
        exit 1
    fi
    wvm_set_current_version ${version}
    wvm_update_symlinks
    echo "Using version: ${version}"
}

wvm_run() {
    wvm_check_init
    if [ -n "${1}" ]; then
        wvm_use ${1}
        shift
    fi
    wvm_launch warsow ${@} || exit
}


wvm_help() {
    echo
    echo "Warsow Version Manager"
    echo
    echo "Usage:"
    echo "    wvm help          Show this help message"
    echo "    wvm init          Initialize this folder to use with wvm"
    echo "    wvm list          List installed versions"
    # echo "    wvm list remote   List remote versions available to install"
    # echo "    wvm install       Download and install a version of Warsow"
    # echo "    wvm uninstall     Uninstall a version of Warsow"
    echo "    wvm current       Show current version of Warsow"
    echo "    wvm use           Set current version of Warsow"
    # echo "    wvm run           Run a version of Warsow"
    echo "    wvm profile       Show profiles or switch a profile"
    # echo "    wvm server        Start/stop a Warsow server"
    # echo "    wvm tv            Start/stop a Warsow TV server"
    echo
    echo "Example:"
    # echo "    wvm install v1.6"
    echo "    wvm use 1.6"
    echo "    wvm profile sm"
    echo "    ./warsow"
    # echo
    # echo "Server example:"
    # echo "    wvm install v1.6"
    # echo "    wvm use 1.6"
    # echo "    wvm profile server-duel-1"
    # echo "    wvm profile server-duel-2"
    # echo "    (edit server configs for each profile)"
    # echo "    wvm server start server-duel-1"
    # echo "    wvm server start server-duel-2"
    # echo "    wvm server list"
    echo
}



## -------------------------------------------------------------------------
##  Main program switch case
## -------------------------------------------------------------------------

wvm() {
    if [ ${#} -lt 1 ]; then
        wvm help
        return
    fi

    case ${1} in
        "help" )
            wvm_help
            exit 127
        ;;
        "init" )
            shift 1
            wvm_init ${@}
            exit
        ;;
        "profile" )
            shift 1
            wvm_profile ${@}
            exit ${?}
        ;;
        "current" )
            shift 1
            wvm_current ${@}
            exit ${?}
        ;;
        "list" )
            shift 1
            wvm_list ${@}
            exit
        ;;
        "use" )
            shift 1
            wvm_use ${@}
            exit ${?}
        ;;
        "run" )
            shift 1
            wvm_run ${@}
            exit ${?}
        ;;
        * )
            wvm_help
            exit 127
        ;;
    esac
}



## -------------------------------------------------------------------------
##  Bootstrapping
## -------------------------------------------------------------------------

wvm ${@}
