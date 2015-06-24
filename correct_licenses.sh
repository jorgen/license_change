#!/bin/bash

SRC_DIR=""
LICENSE_FILE=""

SOURCE_FILES=""

function print_usage {
  echo "Usage for $0"
  echo " $0 [options] -d sourceDir -l license-file"
  echo ""
  echo "Options:"
  echo "-l, --license-file      file containing the license header"
  echo "-d, --source-dir        directory containing source files"
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
            -d|--source-dir)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                SRC_DIR="$2"
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
    if [ -z "$SRC_DIR" ]; then
        error_missing_argument "source-dir"
    elif [ ! -d $SRC_DIR ]; then
        error_missing_file $SRC_DIR
    elif [ -z "$LICENSE_FILE" ]; then
        error_missing_argument "license-file"
    elif [ ! -f $LICENSE_FILE ]; then
        error_missing_file $LICENSE_FILE
    elif [ ! -f "change_license.sh" ]; then
        echo "Missing changle_license.sh script, make sure it is in the path"
        exit 1
    fi
}

function get_source_files {
    echo "Looking up source files in $SRC_DIR"
    SOURCE_FILES=$(IFS=$'\n' find $SRC_DIR -iname "*.cpp" -o -iname "*.h")
}

function change_lisence_in_sources {
    for file in $SOURCE_FILES; do
        ./change_license.sh -l $LICENSE_FILE -s $file || exit 1
    done
}

set -e
set -b
process_arguments $@
verify_arguments
get_source_files
change_lisence_in_sources
