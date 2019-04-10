#!/usr/bin/env bash
set -e
source /etc/profile
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

LOCAL_PATH=".\\/_posts\\/imgs";
REMOTE_PATH="https:\\/\\/github.com\\/DrkCore\\/DrkCore.github.io\\/blob\\/master\\/_posts\\/imgs"

path=${REMOTE_PATH}

while getopts ":hl" opt; do
    case ${opt} in
    h)
        echo -e "Script to help setup blog image path.\n"
        echo -e "All images reffered in post are supposed to be placed under _posts/imgs dir.\n"
        echo ""
        echo "Usage:"
        echo "prepare.sh [OPTIONS]"
        echo "    -l        set image to local path, for test only."
        exit 0
        ;;
    l)
        echo "Setuping local image path"
        path=${LOCAL_PATH}
        ;;
    \?)
        echo "Invalid option: -${OPTARG}"
        exit 1
        ;;
    esac
done

sed -i s/"\\!\[.*\\](.*\\/imgs"/"![](${path}"/g `grep -rl "\\!\[.*\]" ./_posts`


