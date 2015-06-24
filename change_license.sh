#!/bin/bash

SRC_FILE=""
LICENSE_FILE=""

LICENSE_START=""
LICENSE_END=""

COPYRIGHT_SOURCE=""
COPYRIGHT_LICENSE=""

function print_usage {
  echo "Usage for $0"
  echo " $0 [options] -l license-file -s sourceFile"
  echo ""
  echo "Options:"
  echo "-l, --license-file      file containing the license header"
  echo "-s, --source-file       source file for which to apply license header"
  echo ""
}

function print_missing_argument {
    echo ""
    echo "Missing argument for $1"
    echo ""
    print_usage
    exit 1
}

function print_unknown_argument {
    echo ""
    echo "Unknown argument: $1"
    echo ""
    print_usage
    exit 1
}

function process_arguments {
    while [ ! -z $1 ]; do
        case "$1" in
            -l|--license-file)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                LICENSE_FILE="$2"
                shift 2
                ;;
            -s|--source-file)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                SRC_FILE="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                shift
                ;;
            *)
                print_unknown_argument $1
                shift
                ;;
        esac
    done
}

function error_missing_argument {
    echo ""
    echo "Missing argument $1"
    exit 1
}
function error_missing_file {
    echo ""
    echo "Missing file $1"
    exit 1
}

function verify_arguments {
    if [ -z "$SRC_FILE" ]; then
        error_missing_argument "source-file"
    elif [ ! -f $SRC_FILE ]; then
        error_missing_file $SRC_FILE
    elif [ -z "$LICENSE_FILE" ]; then
        error_missing_argument "license-file"
    elif [ ! -f $LICENSE_FILE ]; then
        error_missing_file $LICENSE_FILE
    fi
}

function line_of_patter {
    local pattern=$1
    local file=$2
    line=$(grep -n -E "$pattern" $file | awk -F: '{print $1}' | head -1)
    re='^[0-9]+$'
    if ! [[ $line =~ $re ]] ; then
        echo 0
    fi
    echo $line
}

function set_license_range {
    LICENSE_START=$(line_of_patter "\/\**(\*)$" $SRC_FILE)
    LICENSE_END=$(line_of_patter "\**(\*)\/" $SRC_FILE)

    if [ $LICENSE_START -gt 3 ]; then
        echo "Failed to find license start"
        exit 1
    fi

    if [ $LICENSE_END -le $LICENSE_START ]; then
        echo "Failed to find license header"
        exit 1
    fi
}

function set_copyright_variables {
    COPYRIGHT_SOURCE=$(IFS=$'\n' grep "Copyright (C)" $SRC_FILE)
    COPYRIGHT_LICENSE=$(IFS=$'\n' grep "Copyright (C)" $LICENSE_FILE)
}

function remove_header_from_source {
    local from=$LICENSE_START
    local nlines=`expr $LICENSE_END - 1`
    sed -i "$from",+"$nlines"d $SRC_FILE
}

function prepend_new_header {
    $(cat $LICENSE_FILE $SRC_FILE>tmp.txt && mv tmp.txt $SRC_FILE)
}

function replace_copyright {
    copyright_line=$(line_of_patter "Copyright \(C\)" "$SRC_FILE")

    if [ $copyright_line -eq "0" ]; then
        echo "Failed to find copyright header in the new license. Something must have gone wrong with $SRC_FILE"
        exit 1
    fi
    sed -i "$copyright_line"d "$SRC_FILE"
    IFS=$'\n'
    for copyright in $COPYRIGHT_SOURCE; do
        sed -i "$copyright_line"i\\"$copyright" "$SRC_FILE"
        copyright_line=`expr $copyright_line + 1`
    done
}

set -e
set -b
process_arguments $@
verify_arguments
set_license_range
set_copyright_variables
remove_header_from_source
prepend_new_header
replace_copyright

