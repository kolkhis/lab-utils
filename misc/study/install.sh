#!/bin/bash
# shellcheck disable=SC2162,SC2086

declare packageName

while [[ -n $1 && $1 =~ ^- ]]; do
    case $1 in 
        -h|--help)
            printf "Usage: ./install program1 program2 ...\n"
            shift;
            ;;
        -v|--version)
            printf "version 1\n"
            shift;
            ;;
        *)
            printf "Unknown option, discarding.\n"
            shift;
            ;;
    esac
done

# while getopts "hvf:" opt; do
#     case "$opt" in
#         h) printf "Help requested\n"; exit 0 ;;
#         f) filename="$OPTARG" ;;
#         v) verbose=true ;;
#         \?) printf >&2 "Invalid option: -%s\n" "$OPTARG" ;;
#         :) printf >&2 "Option -%s requires an argument.\n" "$OPTARG" ;;
#     esac
# done

if [[ $# -gt 0 ]]; then
    printf "Found arguments\n"
    for pkg in "$@"; do
        printf "Argument: %s\n" "$pkg"
        if rpm -q $pkg; then
            echo "$pkg is already installed"
        else
            echo "$pkg is NOT installed"
            sudo dnf install -y $pkg || {
                printf "Failed to install package %s\n" "$pkg"
            }
        fi
    done
else
    printf "Warning: no arguments were given!\n" && exit 1
fi

# [[ -n $1 ]] && packageName=$1

# if ! dnf whatprovides $packageName >/dev/null 2>&1; then
#     printf "Package doesn't exist.\n" && exit 1
# fi

# if rpm -q $packageName; then
#     echo "$packageName is already installed"
# else
#     echo "$packageName is NOT installed"
#     sudo dnf install -y $packageName || {
#         printf "Failed to install package %s\n" "$packageName"
#         matches=$(dnf whatprovides "$packageName" | awk -F: "{printf $1}")
#     }
# fi
