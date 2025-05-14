#!/bin/bash -f

function usage() {
  echo -e "Syntax: $(basename "$0") [-h] [-n <name>] [-p <ip>] [-o <openrc>]"
  echo -e "Script to access OpenStack environment."
  echo -e "  -h, --help            Show this help text"
  echo -e "  -o, --openrc          OpenRC file path"
  exit 1
}

# Argument parsing
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            usage
            ;;
        -o|--openrc)
            OPENRC="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $key"
            usage
            ;;
    esac
done

# Check mandatory arguments
if [[  -z "$OPENRC" ]]; then
    echo "Error: OpenRC path."
    usage
fi

# Docker run command
docker run -it --name "openstack" \
       -v "${OPENRC}:/home/openstack/bin/openrc.sh" \
       nsf-lrose/lrose-gateway /bin/bash
