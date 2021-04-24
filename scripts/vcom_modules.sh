#!/bin/sh
#
# Compiles all modules using `vcom` in HDL library and optionally launches vsim
#

usage() { echo -e 'Usage: vcom_modules.sh -c <files.list> [-s <entity_to_vsim>]\n\t-c,\tcompiles all files in given file list parameter\n\t-s,\t[optional] launches vsim simulation on entity given as parameter\n\nClean all: vcom_modules.sh -r' 1>&2; exit 1; }

file_list=""
sim_entity=""

while getopts ":c:s:r" o; do
  case "${o}" in
    c)
      file_list=${OPTARG}
      ;;
    s)
      sim_entity=${OPTARG}
      ;;
    r)
      echo "Deleting vcom/vsim files..."
      rm -f ./modelsim.ini
      rm -f ./transcript
      rm -f ./vsim.wlf
      rm -f ./vlog.opt
      rm -rf ./.hdl_sha1/
      rm -rf ./work/
      exit 0
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${file_list}" ]; then
  echo "Pass a file list to compile!"
  usage
fi

# create hidden folder for SHA-1 file sums for already-compiled file checks
mkdir -p .hdl_sha1/

