#!/bin/bash

SRC_DIR=""
LICENSE_FILE=""
REVISIONS=""
REVISION_FROM=""
REVISION_TO="HEAD"
INITIAL_COMMIT="NO"

function print_usage {
  echo "Usage for $0"
  echo " $0 [options] -d sourceDir -l license-file"
  echo ""
  echo "Options:"
  echo "-l, --license-file      file containing the license header"
  echo "-d, --source-dir        directory containing source files"
  echo "-r, --revision          git revision to rebase from"
  echo "-i, --initial           create initial commit"
  echo "-t, --to-revision       revison to rebase to"
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
            -r|--revision)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                REVISION_FROM="$2"
                shift 2
                ;;
            -t|--to-revision)
                if [ -z $2 ]; then
                    print_missing_argument $1
                fi
                REVISION_TO="$2"
                shift 2
                ;;
            -i|--initial)
                INITIAL_COMMIT="YES"
                shift
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
    elif [ ! -f "correct_licenses.sh" ]; then
        echo "Missing correct_licenses.sh script, make sure it is in the path"
        exit 1
    elif [[ "$(git show $REVISION_FROM 2>/dev/null)" == "" ]]; then
        echo "invalid revision. please specify a valid revision which licenses should be applyed from"
        exit 1
    fi
}

function get_revisions {
    REVISIONS=$(git rev-list --reverse  $REVISION_FROM..$REVISION_TO) || (echo "Failed to get revisions list" && exit 1)
    echo "Revision list is:\n $REVISIONS"
    local count=$(echo "$REVISIONS"|wc -l)
    echo  "$count patches will be rebased"
    $(read -p "Press any key to continue... " -n1 -s)
}

function apply_correct_licenses {
    local gitargs=$1
    ./correct_licenses.sh -d $SRC_DIR -l $LICENSE_FILE
    if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]; then
        git diff --no-ext-diff
        $(read -p "Press any key to continue... " -n1 -s)
        git commit $gitargs || exit 1
    fi
}
function initial_license_cleanup {
    git reset --hard $REVISION_FROM
    apply_correct_licenses "-a"
}

function rebase_revisions {
    for revision in $REVISIONS; do
        git cherry-pick $revision || exit 1
        apply_correct_licenses "-a --amend"
    done
}

process_arguments $@
verify_arguments
get_revisions
if [[ "$INITIAL_COMMIT" == "YES" ]]; then
    initial_license_cleanup
fi
rebase_revisions


