#!/usr/bin/bash

usage(){
echo " -h|-s -n (-i -w)"
echo "-h                    help"
}

INV="inventory"
PATHKUBE='./'
NAME='kube-clu'

# while getopts "hvcts:n:i:" OPTION; do
while getopts "hp:i:n:" OPTION; do
    case "${OPTION}"
    in
        h)          HELP="1";;
        i)          INV=${OPTARG};;
        p)          PATHKUBE=${OPTARG};;
        n)          NAME=${OPTARG};;
        ?)          usage >&2
                    exit 1;;
    esac
done

if [[ $HELP == "1" ]]; then
    usage
    exit 0
fi

if [[ ! -d $INV ]]; then
    echo "Inventory dos not exist"
    exit 1
fi

if [[ -z '$(ls $INV)' ]]; then
    echo "It look like your inventory is empty"
fi

if [[ -d "$PATHKUBE/$NAME" ]]; then
    echo "Error cluster inventory look like ever existing"
    exit 1
fi

mkdir -p "$PATHKUBE/$NAME"

if [[ ! -d "$INV/group_vars" ]]; then
mkdir "$INV/group_vars"
fi

if [[ ! -d "$INV/host_vars" ]]; then
mkdir "$INV/host_vars"
fi

RELATIVEPATHKUBE=$(realpath --relative-to="$PATHKUBE/$NAME" "$INV/")

( cd $PATHKUBE/$NAME && \
ln -s $RELATIVEPATHKUBE/group_vars group_vars && \
ln -s $RELATIVEPATHKUBE/host_vars host_vars )

echo "all:
  hosts:
  children:
    kube-master:
      hosts:
    kube-node:
      hosts:
    etcd:
      hosts:
    k8s-cluster:
      hosts:
    calico-rr:
      hosts:
    vault:
      hosts:" >> $PATHKUBE/$NAME/inventory.yml