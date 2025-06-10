#!/bin/bash -f

function usage() {
  echo -e "Syntax: $(basename "$0") [-h] [-n <name>] [-p <ip>] [-o <openrc>]"
  echo -e "Script to access environment for launching JupyterHub clusters."
  echo -e "  -h, --help            Show this help text"
  echo -e "  -n, --name            JupyterHub name"
  echo -e "  -p, --ip              JupyterHub IP"
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
        -n|--name)
            JUPYTERHUB="$2"
            shift 2
            ;;
        -p|--ip)
            IP="$2"
            shift 2
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
if [[ -z "$JUPYTERHUB" || -z "$IP" || -z "$OPENRC" ]]; then
    echo "Error: Must supply JupyterHub name, IP, and OpenRC path."
    usage
fi

# Base directory for JupyterHub environments
BASE_DIR="$(pwd)/jhubs/${JUPYTERHUB}"

# Ensure base directory exists
if [[ ! -d "$BASE_DIR" ]]; then
    mkdir -p "$BASE_DIR"
    echo "Created base directory: $BASE_DIR"
fi

# Subdirectories
CACHE="$BASE_DIR/cache"
CONFIG="$BASE_DIR/config"
KUBE="$BASE_DIR/kube"
LOCAL="$BASE_DIR/local"
NOVACLIENT="$BASE_DIR/novaclient"
SECRETS="$BASE_DIR/secrets.yaml"
touch ${SECRETS}

# Create necessary subdirectories
for dir in "$CACHE" "$CONFIG" "$KUBE" "$LOCAL" "$NOVACLIENT" ; do
    mkdir -p "$dir"
done

# Docker run command
docker run -it --name "${JUPYTERHUB}" \
       -v "${CACHE}:/home/openstack/.cache/" \
       -v "${CONFIG}:/home/openstack/.config/" \
       -v "${OPENRC}:/home/openstack/bin/openrc.sh" \
       -v "${KUBE}:/home/openstack/.kube/" \
       -v "${LOCAL}:/home/openstack/.local/" \
       -v "${NOVACLIENT}:/home/openstack/.novaclient/" \
       -v "${SECRETS}:/home/openstack/jupyterhub-deploy-kubernetes-jetstream/secrets.yaml" \
       -e CLUSTER="${JUPYTERHUB}" \
       -e K8S_CLUSTER_NAME="${JUPYTERHUB}" \
       -e IP="${IP}" \
       nsf-lrose/lrose-gateway /bin/bash
