#!/bin/bash

## -------------------------------------------------------------------------
##  Constants
## -------------------------------------------------------------------------

## Directory for containing various persistent files
WVM_DIR=".wvm"

## Mirror list for package downloads
declare -a WVM_MIRROR_LIST=(
    "http://s1.smx.lt/wvm"
    "http://e1.smx.lt/wvm"
)



## -------------------------------------------------------------------------
##  Private functions
## -------------------------------------------------------------------------

## A silent version of `cat` in pure bash
wvm_cat() {
    local IFS=""
    (
        while read line; do
            echo "${line}"
        done < ${1}
    ) 2>/dev/null
}

wvm_is_sourced() {
    [[ "${FUNCNAME[1]}" == source ]]
}

wvm_check_init() {
    if ! [[ -d "${WVM_DIR}" ]]; then
        echo "Error: Warsow version manager is not initialized."
        echo "Do this so by running 'wvm init'"
        return 2
    fi
}

wvm_get_current_version() {
    if [[ -d "versions/${1}" ]]; then
        wvm_cat ${WVM_DIR}/version
    fi
}

wvm_set_current_version() {
    echo ${1} > ${WVM_DIR}/version
}

wvm_get_current_profile() {
    local version=`wvm_get_current_version`
    if [[ -d "profiles/${version}/${1}" ]]; then
        wvm_cat ${WVM_DIR}/profile
    fi
}

wvm_set_current_profile() {
    echo ${1} > ${WVM_DIR}/profile
}

wvm_get_local_versions() {
    pushd versions > /dev/null
    for server in */; do
        echo "${server:0:-1}"
    done
    popd > /dev/null
}

wvm_get_remote_versions() {
    wvm_cat ${WVM_DIR}/packages.txt | cut -d ' ' -f 1 | sort
}

wvm_init_server() {
    local version=`wvm_get_current_version`
    mkdir -p profiles/${version}/${1}/basewsw
    cat > profiles/${version}/${1}/basewsw/server.cfg <<EOF
set sv_ip ""
set sv_hostname "warsow server"
set sv_port "44400"
set password ""

set logconsole_append "1"

set sv_public "1"
set sv_maxclients "8"
set sv_skilllevel "1"

set sv_pure "1"
set sv_uploads "1"
set sv_autoupdate "0"

set sv_pps "25"

set g_operator_password ""
set rcon_password ""

set g_autorecord "1"
set g_autorecord_maxdemos "20"
set g_uploads_demos "1"

set sv_MOTD "0"
set sv_MOTDFile "motd.txt"

set g_gametype "duel"
set g_numbots "0"
set g_instagib "0"
set g_instajump "0"
set g_instashield "0"

set sv_defaultmap "wdm2"
set g_maplist "" // list of maps in automatic rotation
set g_maprotation "0"   // 0 = same map, 1 = in order, 2 = random
EOF
}

wvm_get_server() {
    local pid=`wvm_cat ${WVM_DIR}/servers/${1}.pid`
    if kill -0 ${pid} 2>/dev/null; then
        echo ${pid}
    else
        rm -f ${WVM_DIR}/servers/${1}.pid
    fi
}

wvm_save_server() {
    echo ${2} > ${WVM_DIR}/servers/${1}.pid
}

wvm_remove_server() {
    rm -f ${WVM_DIR}/servers/${1}.pid
}

wvm_list_servers() {
    pushd ${WVM_DIR}/servers > /dev/null
    for server in *.pid; do
        local pid=`cat ${server}`
        if kill -0 ${pid} 2>/dev/null; then
            echo "${server%.pid} (${pid})"
        else
            rm -f ${server}
        fi
    done
    popd > /dev/null
}

wvm_string_to_version() {
    if [[ ${1} =~ ^[0-9]+ ]]; then
        echo v${1}
    else
        echo ${1}
    fi
}

wvm_string_to_local_version() {
    local version=`wvm_string_to_version ${1}`
    if [[ -d "versions/${version}" ]]; then
        echo ${version}
    fi
}

wvm_string_to_remote_version() {
    local version=`wvm_string_to_version ${1}`
    for remote in `wvm_get_remote_versions`; do
        if [[ ${version} == ${remote} ]]; then
            echo ${version}
            return
        fi
    done
}

wvm_resolve_remote_version() {
    local version=`wvm_string_to_version ${1}`
    local IFS=$'\n'
    local -a fields
    for line in `wvm_cat ${WVM_DIR}/packages.txt`; do
        IFS=' ' fields=(${line})
        if [[ ${fields[0]} == ${version} ]]; then
            if [[ ${fields[1]} == "->" ]]; then
                echo `wvm_resolve_remote_version ${fields[2]}`
                return
            fi
            if [[ ${fields[1]} == "@" ]]; then
                echo "${fields[0]}"
                return
            fi
            return 1
        fi
    done
}

wvm_get_remote_version_link() {
    local version=`wvm_string_to_version ${1}`
    local IFS=$'\n'
    local -a fields
    for line in `wvm_cat ${WVM_DIR}/packages.txt`; do
        IFS=' ' fields=(${line})
        if [[ ${fields[0]} == ${version} ]]; then
            if [[ ${fields[1]} == "@" ]]; then
                echo "${fields[2]}"
                return
            fi
            return 1
        fi
    done
}

wvm_unpack() {
    local package=`wvm_get_remote_version_link ${1}`
    tar -xzf ${WVM_DIR}/${package} -C versions
}

wvm_update_symlinks() {
    rm -f current
    rm -f profiles/current
    rm -f versions/current
    local profile=`wvm_get_current_profile`
    local version=`wvm_get_current_version`
    if [[ -n "${profile}" ]] && [[ -d "profiles/${version}/${profile}" ]]; then
        ln -s ${version}/${profile} profiles/current
        ln -s profiles/current current
    fi
    if [[ -n "${version}" ]] && [[ -d "versions/${version}" ]]; then
        ln -s ${version} versions/current
    fi
}



## -------------------------------------------------------------------------
##  Functions to work with remote
## -------------------------------------------------------------------------

## Gets data from remote. Shows a progressbar.
wvm_remote_get() {
    local args
    for mirror in "${WVM_MIRROR_LIST[@]}"; do
        if hash curl 2>/dev/null; then
            [[ ${1} == "-q" ]] && args="-s" && shift
            curl -fo - --progress-bar ${args} "${mirror}/${1}" \
                && return || continue
        fi
        if hash wget 2>/dev/null; then
            [[ ${1} == "-q" ]] && args="-q" && shift
            wget -O - --progress=bar ${args} "${mirror}/${1}" \
                && return || continue
        fi
        ## If none of these tools exists
        return 1
    done
}

wvm_remote_download_package_list() {
    wvm_remote_get -q packages.txt > ${WVM_DIR}/packages.txt
    if [[ ${?} -ne 0 ]]; then
        echo "Error: Could not download a package list!"
        return 1
    fi
}

wvm_remote_download_package() {
    local package=`wvm_get_remote_version_link ${1}`
    wvm_remote_get ${package} > ${WVM_DIR}/${package}
    if [[ ${?} -ne 0 ]]; then
        echo "Error: Could not download the package!"
        return 1
    fi
}



## -------------------------------------------------------------------------
##  Launchers and stuff
## -------------------------------------------------------------------------

wvm_launch() {
    local version=${1}
    local profile=${2}
    if [[ -z ${version} ]]; then
        echo "Error: No version is in use!"
        return 1
    fi
    if [[ -z ${profile} ]]; then
        profile="default"
    fi
    shift 2

    local path_bin="./versions/${version}"
    local path_cd="./versions/${version}"
    local path_data="./profiles/${version}/${profile}"
    local arch=`uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc/ -e s/sparc64/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/alpha/axp/`
    local executable="`basename \"${1}\"`.${arch}"
    shift

    if [[ ! -e "${path_bin}/${executable}" ]]; then
        echo "Error: Executable for system '${arch}' not found"
        return 1
    fi

    exec "${path_bin}/${executable}" \
        +set fs_basepath "${path_data}" \
        +set fs_cdpath "${path_cd}" \
        +set fs_usehomedir "0" \
        "${@}"
}



## -------------------------------------------------------------------------
##  Public functions
## -------------------------------------------------------------------------

wvm_init() {
    mkdir -p ${WVM_DIR}/{logs,servers,versions}
    mkdir -p versions
    mkdir -p profiles
    echo > ${WVM_DIR}/profile
    echo > ${WVM_DIR}/version
    wvm_update_symlinks
}

wvm_profile() {
    wvm_check_init || return
    if [[ ${#} -lt 1 ]]; then
        echo -n "Current profile: "
        wvm_get_current_profile
    else
        local profile="${1}"
        local version=`wvm_get_current_version`
        if [[ -z ${version} ]]; then
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
    wvm_check_init || return

    if [[ ${1} == "remote" ]]; then
        wvm_remote_download_package_list || return
        echo "Versions available to install:"
        wvm_get_remote_versions
        return
    fi

    echo "Installed versions:"
    wvm_get_local_versions
}

wvm_current() {
    echo -n "Current version: "
    wvm_get_current_version
}

wvm_install() {
    wvm_check_init || return

    if [[ ${#} -lt 1 ]]; then
        echo
        echo "Usage:"
        echo "    wvm install <version>"
        echo
        echo "Example:"
        echo "    wvm install latest"
        echo
        echo "You can get a list of remote versions with 'wvm list remote'"
        echo
        return 2
    fi

    wvm_remote_download_package_list || return

    local version=`wvm_string_to_version ${1}`
    local remote_version=`wvm_resolve_remote_version ${1}`
    if [[ ${?} -ne 0 ]]; then
        echo "Error: Could not find remote version ${version}"
        return 1
    fi
    
    wvm_remote_download_package ${remote_version} || return
    echo "Unpacking..."
    wvm_unpack ${remote_version} || return
    echo "Done!"
    wvm_use ${remote_version}
}

wvm_use() {
    if [[ ${#} -lt 1 ]]; then
        echo
        echo "Usage:"
        echo "    wvm use <version>"
        echo
        echo "Example:"
        echo "    wvm use v1.6"
        echo
        echo "You can get a list of installed versions with 'wvm list'"
        echo
        return 2
    fi
    local version=`wvm_string_to_local_version ${1}`
    if [[ -z ${version} ]]; then
        echo "Error: Version '${1}' was not found!"
        return 1
    fi
    wvm_set_current_version ${version}
    wvm_update_symlinks
    echo "Using version: ${version}"
}

wvm_run() {
    wvm_check_init || return
    if [[ -n ${1} ]]; then
        wvm_use ${1}
        shift
    fi
    local version=`wvm_get_current_version`
    local profile=`wvm_get_current_profile`
    wvm_launch ${version} ${profile} warsow "${@}" || return
}

wvm_server() {
    wvm_check_init || return

    if [[ ${#} -lt 1 ]]; then
        echo "Help not implemented yet"
        return 2
    fi

    if [[ ${1} == "list" ]]; then
        echo "Running servers:"
        wvm_list_servers
        return
    fi

    if [[ ${1} == "init" ]]; then
        if [[ ${#} -lt 2 ]]; then
            echo "Usage: wvm server init <server_name>"
            return 1
        fi
        local version=`wvm_get_current_version`
        wvm_init_server ${2}
        echo "Server '${2}' was initialized."
        echo
        echo "Edit 'profiles/${version}/${2}/basewsw/server.cfg' config to your liking."
        echo "Then you can start server with:"
        echo "    wvm server start ${2}"
        echo
        return
    fi

    local version=`wvm_get_current_version`
    if [[ -z ${version} ]]; then
        echo "Error: No version is in use!"
        return 1
    fi

    if [[ ${#} -eq 2 ]]; then
        local profile=${2}
        mkdir -p profiles/${version}/${profile}
    else
        local profile=`wvm_get_current_profile`
        if [[ -z ${profile} ]]; then
            echo "Error: No profile selected!"
            return 1
        fi
    fi

    if [[ ${1} == "start" ]]; then
        local pid=`wvm_get_server ${profile}`
        if [[ -n ${pid} ]]; then
            echo "Already running! (${pid})"
            return
        fi
        wvm_launch ${version} ${profile} wsw_server \
            +exec server.cfg "${@}" \
            2>&1 >${WVM_DIR}/logs/warsow.log <&- \
            & local pid=${!}
        disown ${pid}
        wvm_save_server ${profile} ${pid}
        echo "Running: '${profile}', pid ${pid}"
        return
    fi

    if [[ ${1} == "stop" ]]; then
        local pid=`wvm_get_server ${profile}`
        if [[ -z ${pid} ]]; then
            echo "Not running!"
        else
            echo "Stopping server '${profile}' (${pid})..."
            kill ${pid}
            sleep 1
            if [[ -z `wvm_get_server ${profile}` ]]; then
                echo "OK!"
            else
                echo "Can't stop server. Try stopping manually (kill -9 ${pid})."
            fi
        fi
        return
    fi
}


wvm_help() {
    echo
    echo "Warsow Version Manager"
    echo
    echo "Usage:"
    echo "    wvm help          Show this help message"
    echo "    wvm init          Initialize this folder to use with wvm"
    echo "    wvm list          List installed versions"
    echo "    wvm list remote   List remote versions available to install"
    echo "    wvm install       Download and install a version of Warsow"
    # echo "    wvm uninstall     Uninstall a version of Warsow"
    echo "    wvm current       Show current version of Warsow"
    echo "    wvm use           Set current version of Warsow"
    echo "    wvm run           Run a version of Warsow"
    echo "    wvm profile       Show profiles or switch a profile"
    echo "    wvm server        Start/stop a Warsow server"
    # echo "    wvm tv            Start/stop a Warsow TV server"
    echo
    echo "Example:"
    echo "    wvm install latest"
    echo "    wvm profile foo"
    echo "    ./warsow"
    echo
    echo "Server example:"
    echo "    wvm install latest"
    echo "    wvm server init foo (then edit server.cfg)"
    echo "    wvm server start foo"
    echo "    wvm server list"
    echo "    wvm server stop foo"
    echo
    return 127
}



## -------------------------------------------------------------------------
##  Main program switch case
## -------------------------------------------------------------------------

wvm() {
    if [[ ${#} -lt 1 ]]; then
        wvm help
        return
    fi

    local action=${1}
    shift

    case ${action} in
        help)       wvm_help ;;
        init)       wvm_init "${@}" ;;
        profile)    wvm_profile "${@}" ;;
        current)    wvm_current "${@}" ;;
        list)       wvm_list "${@}" ;;
        use)        wvm_use "${@}" ;;
        install)    wvm_install "${@}" ;;
        server)     wvm_server "${@}" ;;
        run)        wvm_run "${@}" ;;
        *)          wvm_help ;;
    esac
}



## -------------------------------------------------------------------------
##  Bootstrapping
## -------------------------------------------------------------------------

if ! wvm_is_sourced; then
    cd `dirname ${0}`
    wvm "${@}"
    exit ${?}
fi
