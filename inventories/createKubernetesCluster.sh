#!/usr/bin/bash

usage(){
echo " -h|-s -n (-i -w)"
echo "-h                    help"
echo "-i                    enventory source"
echo "-p                    path to kubernetes inventory"
echo "-n                    name of kubernetes inventory"
echo "-k                    kubspray path"
}

INV="inventory"
PATHKUBE='./'
NAME='kube-clu'

# while getopts "hvcts:n:i:" OPTION; do
while getopts "hk:p:i:n:" OPTION; do
    case "${OPTION}"
    in
        h)          HELP="1";;
        i)          INV=${OPTARG};;
        p)          PATHKUBE=${OPTARG};;
        n)          NAME=${OPTARG};;
        k)          KUBESPRAY=${OPTARG};;
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

( cd $PATHKUBE/$NAME &&
# mkdir group_vars &&
ln -s $RELATIVEPATHKUBE/host_vars host_vars )
# ln -s $RELATIVEPATHKUBE/group_vars group_vars &&

echo "all:
  hosts:
  children:
    kube-master:
      hosts:
    kube-node:
      hosts:
    etcd:
      hosts:
    calico-rr:
      hosts:
    k8s-cluster:
      children:
        kube-master:
        kube-node:
        calico-rr:
    vault:
      hosts:" >> $PATHKUBE/$NAME/inventory.yml

GROUPVARS=0

if [[ ! -z $KUBESPRAY ]]; then
  if [[ -d $KUBESPRAY ]]; then
    if [[ -d "$KUBESPRAY/inventory" ]]; then
      if [[ -d "$KUBESPRAY/inventory/sample" ]]; then
        if [[ -d "$KUBESPRAY/inventory/sample/group_vars" ]]; then
          cp -r "$KUBESPRAY/inventory/sample/group_vars" $PATHKUBE/$NAME/group_vars
          GROUPVARS=1
        fi
      fi
    fi
  fi
fi

if [[ "$GROUPVARS" -eq "0" ]]; then
  echo "You will have to copy sample group_vars"
fi