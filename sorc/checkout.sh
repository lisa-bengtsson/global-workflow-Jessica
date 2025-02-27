#! /usr/bin/env bash

set +x
set -u

function usage() {
  cat << EOF
Clones and checks out external components necessary for
  global workflow. If the directory already exists, skip
  cloning and just check out the requested version (unless
  -c option is used).

Usage: ${BASH_SOURCE[0]} [-c][-h][-m ufs_hash]
  -c:
    Create a fresh clone (delete existing directories)
  -h:
    Print this help message and exit
  -m ufs_hash:
    Check out this UFS hash instead of the default
  -g:
    Check out GSI for GSI-based DA
  -u:
    Check out GDASApp for UFS-based DA
EOF
  exit 1
}

function checkout() {
  #
  # Clone or fetch repo, then checkout specific hash and update submodules
  #
  # Environment variables:
  #   topdir [default: $(pwd)]: parent directory to your checkout
  #   logdir [default: $(pwd)]: where you want logfiles written
  #   CLEAN [default: NO]:      whether to delete existing directories and create a fresh clone
  #
  # Usage: checkout <dir> <remote> <version> <cpus> <reccursive>
  #
  #   Arguments
  #     dir:     Directory for the clone
  #     remote:  URL of the remote repository
  #     version: Commit to check out; should always be a speciifc commit (hash or tag), not a branch
  #
  #   Returns
  #     Exit code of last failed command, or 0 if successful
  #

  dir="$1"
  remote="$2"
  version="$3"
  cpus="${4:-1}"  # Default 1 thread
  recursive=${5:-"YES"}

  name=$(echo "${dir}" | cut -d '.' -f 1)
  echo "Performing checkout of ${name}"

  logfile="${logdir:-$(pwd)}/checkout_${name}.log"

  if [[ -f "${logfile}" ]]; then
    rm "${logfile}"
  fi

  cd "${topdir}" || exit 1
  if [[  -d "${dir}" && ${CLEAN} == "YES" ]]; then
    echo "|-- Removing existing clone in ${dir}"
    rm -Rf "${dir}"
  fi
  if [[ ! -d "${dir}" ]]; then
    echo "|-- Cloning from ${remote} into ${dir}"
    git clone "${remote}" "${dir}" >> "${logfile}" 2>&1
    status=$?
    if ((status > 0)); then
      echo "    WARNING: Error while cloning ${name}"
      echo
      return "${status}"
    fi
    cd "${dir}" || exit 1
  else
    # Fetch any updates from server
    cd "${dir}" || exit 1
    echo "|-- Fetching updates from ${remote}"
    git fetch
  fi
  echo "|-- Checking out ${version}"
  git checkout "${version}" >> "${logfile}" 2>&1
  status=$?
  if ((status > 0)); then
    echo "    WARNING: Error while checking out ${version} in ${name}"
    echo
    return "${status}"
  fi
  if [[ "${recursive}" == "YES" ]]; then
    echo "|-- Updating submodules (if any)"
    git submodule update --init --recursive -j "${cpus}" >> "${logfile}" 2>&1
    status=$?
    if ((status > 0)); then
      echo "    WARNING: Error while updating submodules of ${name}"
      echo
      return "${status}"
    fi
  fi
  echo
  return 0
}

# Set defaults for variables toggled by options
export CLEAN="NO"
checkout_gsi="NO"
checkout_gdas="NO"

# Parse command line arguments
while getopts ":chgum:o" option; do
  case ${option} in
    c)
      echo "Received -c flag, will delete any existing directories and start clean"
      export CLEAN="YES"
      ;;
    g)
      echo "Received -g flag for optional checkout of GSI-based DA"
      checkout_gsi="YES"
      ;;
    h)  usage;;
    u)
      echo "Received -u flag for optional checkout of UFS-based DA"
      checkout_gdas="YES"
      ;;
    m)
      echo "Received -m flag with argument, will check out ufs-weather-model hash ${OPTARG} instead of default"
      ufs_model_hash=${OPTARG}
      ;;
    :)
      echo "option -${OPTARG} needs an argument"
      usage
      ;;
    *)
      echo "invalid option -${OPTARG}, exiting..."
      usage
      ;;
  esac
done
shift $((OPTIND-1))

topdir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
export topdir
export logdir="${topdir}/logs"
mkdir -p "${logdir}"

# Setup lmod environment
source "${topdir}/../workflow/gw_setup.sh"

# The checkout version should always be a speciifc commit (hash or tag), not a branch
errs=0
# Checkout UFS submodules in parallel
checkout "ufs_model.fd"    "https://github.com/ufs-community/ufs-weather-model" "${ufs_model_hash:-63a43d9}" "8" ; errs=$((errs + $?))

# Run all other checkouts simultaneously with just 1 core each to handle submodules.
checkout "wxflow"          "https://github.com/NOAA-EMC/wxflow"                 "528f5ab" &
checkout "gfs_utils.fd"    "https://github.com/NOAA-EMC/gfs-utils"              "a283262" &
checkout "ufs_utils.fd"    "https://github.com/ufs-community/UFS_UTILS.git"     "72a0471" &
checkout "verif-global.fd" "https://github.com/NOAA-EMC/EMC_verif-global.git"   "c267780" &

if [[ ${checkout_gsi} == "YES" ]]; then
  checkout "gsi_enkf.fd" "https://github.com/NOAA-EMC/GSI.git" "ca19008" "1" "NO" &
fi

if [[ ${checkout_gdas} == "YES" ]]; then
  checkout "gdas.cd" "https://github.com/NOAA-EMC/GDASApp.git" "7659c10" &
fi

if [[ ${checkout_gsi} == "YES" || ${checkout_gdas} == "YES" ]]; then
  checkout "gsi_utils.fd"    "https://github.com/NOAA-EMC/GSI-Utils.git"   "322cc7b" &
  checkout "gsi_monitor.fd"  "https://github.com/NOAA-EMC/GSI-Monitor.git" "45783e3" &
fi

# Go through each PID and verify no errors were reported.
for checkout_pid in $(jobs -p); do
  wait "${checkout_pid}" || errs=$((errs + $?))
done

# Temporary hack to check out a UPP verison that works on Orion
# This can be removed once the UFS UPP version advances to or beyond 78f369b
cd "${topdir}/ufs_model.fd/FV3/upp" || exit 1
git checkout 78f369b
cd "${topdir}" || exit 1
# End hack

if (( errs > 0 )); then
  echo "WARNING: One or more errors encountered during checkout process, please check logs before building"
fi
echo
exit "${errs}"
