#!/bin/bash
# 
# Description: 
# Check if the expected file can be found on the sftp server
#
# User manual: 
# Add the script to crontab: 
# min time * * * 
# bash verify-sftp-file-exists.sh -e uat -p /sub/path/ -f base_filename 
#
# The script will terminate abruptly if:
# the number of parameters is incorrect 
# the arg environment is not in the envlist 
# the sftp is not found
# the properties file is not found
# the identity key is not found
#

# 
# displays the correct usage of script
# @return: exit code 1
#
usage () {
  echo "Usage: $0 -e environment -p path -f filename"
  exit 1;
}

#
# check if value is contained in list
# @param: $1, the list of values
# @param: $2, a string value
# @return: 0 if value is found, 1 otherwise
#
is_contained_in_list () {
  local _result=1
  for word in $("$1"); 
  do
    echo "${word}"
    if [[ "${word}" = "$2" ]];
    then 
      _result=0
    fi
  done
  echo "${_result}"
  return ${_result}       
}

#
# log message with timestamp and thread pid
# @param: $1, the message
#
log () {
  echo -e "$(date +%y-%m-%d-%H:%M:%S-%s) [Thread-$$] \\t$1"
}

# 
# default variables initialization
# 
_props_filename=$(echo "$0"|cut -d'.' -f1)".properties"
_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/" 

clear 

# 
# read the options and arguments provided by the command line
# options: -e -p -f -n
# see: usage
#
while getopts ":e:p:f:" o; do
  case "${o}" in
  e)
    _env=${OPTARG}
    ;;
  p)
    _subpath=${OPTARG}
    ;;
  f)
    _filename=${OPTARG}
    ;;
  *)
    usage
    ;;
  esac
done

# 
# manage the number of arguments 
# if the number of arguments is less than 8 
# the script displays the usage message
#
if [ $# -ne 6 ];
then
  echo "Illegal number of parameters."
  usage
fi

# 
# load the key values from the properties file 
# @return: exit code 1 if the properties cannot be found.
#
[[ ! -f $_props_filename ]] && {
  log "[Error] the properties file ${_dir}${_props_filename} could not be found. Script exiting." && 
  exit 1
}
# shellcheck disable=SC1090
. "$(_props_filename)"

# 
# check if the environment value is in the list of environments: test, uat and prod allowed.
# @param: envlist property = "test prod"
# @param: -e [value] is in envlist
# @return: 1 if the env value cannot be found.
#
# shellcheck disable=SC2154
is_contained_in_list "${envlist}" "${_env}"
( ! is_contained_in_list "${envlist}" "${_env}" ) && {
  log "[Error] ${_env} value is not in the env list ${!envlist}. Check properties file. Script exiting." && 
  exit 1 
}

#
# create the property keys to access the values of the properties file
#
_host_user=${_env}"_user"
_host_ip=${_env}"_ip"
_host_folder=${_env}"_folder"
# shellcheck disable=SC2034
_host_port=${_env}"_port"
_host_key=${_env}"_privatekey"

#
# log entry parameters 
#
log "--------------------------------------------------------------------------"
log "Starting $0\\n version 0.1 in Bash v. $BASH_VERSION"
log "Current dir: ${_dir}"
log "Loading the properties file: ${_props_filename} for environment: ${_env}"
log "Script arg env: ${_env}"
log "Script arg subpath: ${_subpath}"
log "Script arg filename: ${_filename}"
# shellcheck disable=SC2154
log "Script arg nb days: ${_nb_days}\\n"

#
# log the env properties for the remote host
#
log "--------------------------------------------------------------------------"
log "Environment: ${_env}"
log "Remote user: ${!_host_user}"
log "Remote host: ${!_host_ip}"
log "Remote key: ${!_host_key}\\n"

# 
# initialize dependent variables
# full remote path: parent path on host/sub path/
_full_remote_path="${!_host_folder}${_subpath}/"
# shellcheck disable=SC2034,SC2154
_fullpath_filename=${_full_remote_path}${_remote_filename}

log "--------------------------------------------------------------------------"
log "Remote filename: ${_remote_filename}"
# shellcheck disable=SC2154
log "Remote file: ${_fullpath_file}\\n"

# 
# if the identity is not found, exit 
[[ ! -f ${_dir}${!_host_key} ]] && {
  log "[Error] the identity key ${_dir}${!_host_key} could not be found. Script exiting." && 
  exit 1
}

#
# set up permissions for the security key and install curl
chmod 600 "${_dir}${!_host_key}"
log "--------------------------------------------------------------------------"
log "Installing curl"
apt-get -q -y install curl 

# 
# list the remote file on the sftp remote host and
# @return: exit code 1 if the file is not found
#   
log "--------------------------------------------------------------------------"
log "checking the existence of the sftp file with ls -l\\n"

echo "ls -l ${_fullpath_file}
quit" | sftp -b -  -oStrictHostKeyChecking=no -i "${_dir}${!_host_key}" "${!_host_user}@${!_host_ip}" 2>&1

#
# sftp manage return codes 126, 127
_exit_code=$?
echo -e "\\nExit code returned from sftp: ${_exit_code}\\n"
([[ ${_exit_code} = 127 ]] || [[ ${_exit_code} = 126 ]]) && {

  log "[Error] Exit code 126: could not execute sftp command. Please review its permissions." 
  log "[Error] Exit code 127: could not find the sftp command. Please make sure it is installed."
  log "Script exiting."
  exit 1
}

#
# manage the exit code if the file exists
[[ ${_exit_code} -ne 0 ]] && {
  log "[Error] the file ${_fullpath_file} does not exist on the sftp."
}

[[ ${_exit_code} = 0 ]] && {
  log "File ${_fullpath_file} exists on remote ${!_host_ip}" 
  log "Exit code 0: Script terminating normally."
}

# end
