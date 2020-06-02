#!/usr/bin/bash

cd subProject

git clone https://github.com/kubernetes-sigs/kubespray.git

( cd kubespray && pip3 install -r requirements.txt )