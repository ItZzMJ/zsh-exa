#!/usr/bin/env zsh

#####################
# COMMONS
#####################
autoload colors is-at-least

#########################
# CONSTANT
#########################
BOLD="bold"
NONE="NONE"

#########################
# PLUGIN MAIN
#########################
[[ -z "$EXA_HOME" ]] && export EXA_HOME="$HOME/.exa"

# temp
export EXA_HOME="$(pwd)/.exa"
echo $EXA_HOME
mkdir ${EXA_HOME}

UNZIP_PATH=${EXA_HOME}/unzip
mkdir ${UNZIP_PATH}


ZSH_EXA_VERSION_FILE=${EXA_HOME}/version.txt

#########################
# Functions
#########################

_zsh_exa_log() {
  local font=$1
  local color=$2
  local msg=$3

  if [ $font = $BOLD ]
  then
    echo $fg_bold[$color] "[zsh-exa-plugin] $msg" $reset_color
  else
    echo $fg[$color] "[zsh-exa-plugin] $msg" $reset_color
  fi
}

_zsh_exa_install_unzip() {
  _zsh_exa_log $NONE "blue" "Download and install unzip"
  curl -o ${UNZIP_PATH}/unzip.deb -fsSL http://ftp.de.debian.org/debian/pool/main/u/unzip/unzip_6.0-28_amd64.deb
  dpkg -x ${UNZIP_PATH}/unzip.deb ${UNZIP_PATH}
  rm -rf  ${UNZIP_PATH}/unzip.deb
  path+=${UNZIP_PATH}/usr/bin/
  _zsh_exa_log $NONE "blue" "Finished Installing unzip"
}

_zsh_exa_latest_version_download_link() {
  echo $(curl -s https://api.github.com/repos/ogham/exa/releases/latest | grep "tarball_url" | cut -d '"' -f 4)
}

_zsh_exa_last_version() {
  echo $(curl -s https://api.github.com/repos/ogham/exa/releases/latest | grep "tag_name" | cut -d '"' -f 4)
}

_zsh_exa_download_install() {
   local version=$(_zsh_exa_last_version)
   local link=$1
   local machine
     case "$(uname -m)" in
       x86_64)
         machine=x86_64
         # if on Darwin, set $OSTYPE to match the exa release
         [[ "$OSTYPE" == "darwin"* ]] && local OSTYPE=macos
         ;;
       *)
         _zsh_exa_log $BOLD "red" "Machine $(uname -m) not supported by this plugin"
         return 1
     ;;
     esac
   _zsh_exa_log $NONE "blue" "  -> download and install exa ${version}"
   curl -o "${EXA_HOME}/exa.zip" -fsSL https://github.com/ogham/exa/releases/download/${version}/exa-${OSTYPE%-*}-${machine}-${version}.zip || (_zsh_exa_log $BOLD "red" "Error while downloading exa release" ; return)
   unzip -o ${EXA_HOME}/exa.zip -d ${EXA_HOME} 2>&1 > /dev/null
   rm -rf ${EXA_HOME}/exa.zip
   rm -rf ${UNZIP_PATH}
   echo ${version} > ${ZSH_EXA_VERSION_FILE}
  _zsh_exa_log $BOLD "green" "Install OK"
}

_zsh_exa_install() {
  _zsh_exa_log $NONE "blue" "#############################################"
  _zsh_exa_log $BOLD "blue" "Installing exa..."
  _zsh_exa_log $NONE "blue" "-> creating exa home dir : ${EXA_HOME}"
  mkdir -p ${EXA_HOME} || _zsh_exa_log $NONE "green" "dir already exist"
  local last_version=$(_zsh_exa_last_version)
  _zsh_exa_log $NONE "blue" "-> retrieve last version of exa..."
  _zsh_exa_download_install ${last_version}
  _zsh_exa_log $NONE "blue" "#############################################"
}

update_zsh_exa() {
  _zsh_exa_log $NONE "blue" "#############################################"
  _zsh_exa_log $BOLD "blue" "Checking new version of exa..."

  local current_version=$(cat ${ZSH_EXA_VERSION_FILE})
  local last_version=$(_zsh_exa_last_version)

  if is-at-least ${last_version#v*} ${current_version#v*}
  then
    _zsh_exa_log $BOLD "green" "Already up to date, current version : ${current_version}"
  else
    _zsh_exa_log $NONE "blue" "-> Updating exa..."
    _zsh_exa_download_install ${last_version}
    _zsh_exa_log $BOLD "green" "Update OK"
  fi
  _zsh_exa_log $NONE "blue" "#############################################"
}

_zsh_exa_load() {
    # export PATH if needed
    local -r plugin_dir=${EXA_HOME}/bin
    # Add the plugin bin directory path if it doesn't exist in $PATH.
    if [[ -z ${path[(r)$plugin_dir]} ]]; then
        path+=($plugin_dir)
    fi
}

# install local unzip if it isnt already installed
if command -v unzip  &> /dev/null
then
  _zsh_exa_install_unzip
fi

# install exa if it isnt already installed
[[ ! -f "${ZSH_EXA_VERSION_FILE}" ]] && _zsh_exa_install

# load exa if it is installed
if [[ -f "${ZSH_EXA_VERSION_FILE}" ]]; then
    _zsh_exa_load
fi


########################################################
##### ALIASES
########################################################
alias ll='exa -lbF --git'
alias la='exa -lbhHigmuSa --time-style=long-iso --git --color-scale'
alias lx='exa -lbhHigmuSa@ --time-style=long-iso --git --color-scale'
alias llt='exa -l --git --tree'
alias lt='exa --tree --level=2'
## Sorts
alias llm='exa -lbGF --git --sort=modified'
alias lld='exa -lbhHFGmuSa --group-directories-first'

unset -f _zsh_exa_install _zsh_exa_load
