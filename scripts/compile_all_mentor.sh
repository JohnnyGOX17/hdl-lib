#!/bin/sh
#
# Compiles all modules using Model/Questa Sim `vcom` or `vlog` (for VHDL & Verilog)
# in HDL library, and optionally launches `vsim` on a testbench
#

usage() { echo -e 'Usage: compile_all_mentor.sh [-c <files.list>] [-s <entity_to_vsim>]\n\t-c,\tcompiles all files in given file list parameter [defaults to hdl-lib.list]\n\t-s,\t[optional] launches vsim simulation on entity given as parameter\n\nClean all: compile_all_mentor.sh -r' 1>&2; exit 1; }

fileList="hdl-lib.list"
simEntity=""
shaDir=".hdl_sha1"
# Free edition of ModelSim doesn't support some options...
#vcomOpts="-2008 -quiet -floatgenerics"
vcomOpts="-2008"
vlogOpts=""
vsimOpts=""

while getopts ":c:s:r" o; do
  case "${o}" in
    c)
      fileList=${OPTARG}
      ;;
    s)
      simEntity=${OPTARG}
      ;;
    r)
      echo "Deleting intermediate files..."
      rm -f ./transcript
      rm -f ./vsim.wlf
      rm -f ./vlog.opt
      rm -rf "$shaDir"
      rm -rf ./work/
      exit 0
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

# create hidden folder for SHA-1 file sums for already-compiled file checks
mkdir -p "$shaDir"

# map libraries to ModelSim
vlib work > /dev/null
vmap work work > /dev/null

fileCount=$(wc -l < "$fileList")
iter=0
while read -r line || [[ -n "$line" ]]; do
  fileName="$(basename ${line})"
  fileExt="${fileName##*.}"
  if [ "$fileExt" = "vhd" ]; then
    tmpCC="vcom $vcomOpts $line -work work"
  elif [ "$fileExt" = "v" ]; then
    tmpCC="vlog $vlogOpts $line -work work"
  else
    echo -en "\nUnknown extension in $fileName !\n\n"
    continue
  fi

  percent=$(awk "BEGIN { pc=100*${iter}/${fileCount}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
  echo -en "\r\033[K [${percent}%] $fileName"

  shaFile="$shaDir/$fileName.sha1"
  if [ -f "$shaFile" ]; then # SHA-1 checksum present
    # if SHA-1's differ, recompile and re-checksum, else the file looks to have
    # not been changed since last compile script invocation, can skip to next file
    shaCurr="$(sha1sum "$line")"
    shaPrev="$(cat "$shaFile")"
    if [[ "$shaCurr" != "$shaPrev" ]]; then
      sha1sum "$line" > "$shaFile"
      eval $tmpCC 2> /dev/null
    fi
  else # file not already checksummed, do SHA-1 and compile
    sha1sum "$line" > "$shaFile"
    eval $tmpCC 2> /dev/null
  fi

  iter=$(( $iter + 1 ))
done < $fileList
echo -en "\r\033[K Compilation complete...\n"

if [ -n "$simEntity" ]; then
  echo "Launching ModelSim vsim for given entity $simEntity..."
  vsim "$vsimOpts" "$simEntity"
fi

