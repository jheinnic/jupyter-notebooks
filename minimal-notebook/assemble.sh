#!/bin/bash

set -x

set -eo pipefail

umask 002

########################################################################
# INFO: Install everything that's required for Jupyter notebooks here.
########################################################################

# Ensure we are using the latest pip and wheel packages.

pip install -U pip setuptools wheel

# Install mod_wsgi for use in optional webdav support.

pip install 'mod_wsgi==4.6.8'

# Install supervisord for managing multiple applications.

pip install 'supervisor==4.1.0'

# Install base packages needed for running Jupyter Notebooks. 

pip install -r /opt/app-root/src/requirements.txt

# Install cmake
cd /opt/app-root
wget https://github.com/Kitware/CMake/releases/download/v3.18.3/cmake-3.18.3-Linux-x86_64.tar.gz
tar xf ./cmake-3.18.3-Linux-x86_64.tar.gz
cd ./cmake-3.18.3-Linux-x86_64
tar cf - . ( cd ../; tar xf - )

# Enable clickable images
git clone https://github.com/jheinnic/jupyter_clickable_image_widget
cd jupyter_clickable_image_widget
pip3 install -e .
jupyter labextension install js
jupyter labextension enable js

# Enable ipyparallel for JubyterHub
# jupyter nbextension install --sys-prefix --py ipyparallel
# jupyter nbextension enable --sys-prefix --py ipyparallel
# jupyter serverextension enable --sys-prefix --py ipyparallel

# Enable JupyterLab 
jupyter serverextension enable jupyterlab
jupyter nbextension enable --py widgetsnbextension --sys-prefix
jupyter nbextension enable --py plotlywidget --sys-prefix
jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build
jupyter labextension install jupyterlab-plotly@4.10.0 --no-build
jupyter labextension install plotlywidget@4.10.0 --no-build
jupyter labextension enable @jupyter-widgets/jupyterlab-manager --no-build
jupyter labextension enable jupyterlab-plotly@4.10.0 --no-build
jupyter labextension enable plotlywidget@4.10.0 --no-build
jupyter lab build --minimize=False

# Install oc command line client for OpenShift cluster.

curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v3/clients/3.11.153/linux/oc.tar.gz && \
    tar -C /opt/app-root/bin -zxf /tmp/oc.tar.gz oc && \
    mv /opt/app-root/bin/oc /opt/app-root/bin/oc-3.11 && \
    rm /tmp/oc.tar.gz

curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.1/linux/oc.tar.gz && \
    tar -C /opt/app-root/bin -zxf /tmp/oc.tar.gz oc && \
    mv /opt/app-root/bin/oc /opt/app-root/bin/oc-4.1 && \
    rm /tmp/oc.tar.gz

curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.2/linux/oc.tar.gz && \
    tar -C /opt/app-root/bin -zxf /tmp/oc.tar.gz oc && \
    mv /opt/app-root/bin/oc /opt/app-root/bin/oc-4.2 && \
    rm /tmp/oc.tar.gz

curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.3/linux/oc.tar.gz && \
    tar -C /opt/app-root/bin -zxf /tmp/oc.tar.gz oc && \
    mv /opt/app-root/bin/oc /opt/app-root/bin/oc-4.3 && \
    rm /tmp/oc.tar.gz

curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.4/linux/oc.tar.gz && \
    tar -C /opt/app-root/bin -zxf /tmp/oc.tar.gz oc && \
    mv /opt/app-root/bin/oc /opt/app-root/bin/oc-4.4 && \
    rm /tmp/oc.tar.gz

curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.5/linux/oc.tar.gz && \
    tar -C /opt/app-root/bin -zxf /tmp/oc.tar.gz oc && \
    mv /opt/app-root/bin/oc /opt/app-root/bin/oc-4.5 && \
    rm /tmp/oc.tar.gz

curl -s -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.6/linux/oc.tar.gz && \
    tar -C /opt/app-root/bin -zxf /tmp/oc.tar.gz oc && \
    mv /opt/app-root/bin/oc /opt/app-root/bin/oc-4.6 && \
    rm /tmp/oc.tar.gz

ln -s /opt/app-root/bin/oc-wrapper.sh /opt/app-root/bin/oc

curl -Ls -o /tmp/kustomize.tar.gz https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v3.4.0/kustomize_v3.4.0_linux_amd64.tar.gz && \
    tar -C /opt/app-root/bin -zxf /tmp/kustomize.tar.gz kustomize && \
    rm /tmp/kustomize.tar.gz

# Ensure passwd/group file intercept happens for any shell environment.

echo "source /opt/app-root/etc/generate_container_user" >> /opt/app-root/etc/scl_enable

# Install packages required by the proxy process.

cd /opt/app-root/gateway && source scl_source enable rh-nodejs10

npm cache clean --force
rm -rf $HOME/.cache/yarn
rm -rf $HOME/.node-gyp
npm install --production

# Making mount point or injection point for init container to write into
mkdir -p /opt/app-root/data
mkdir -p /opt/app-root/inst

# Protobuf compiler
yum install protoc

# Generate default supervisord.conf file.

echo_supervisord_conf | \
    sed -e 's%^logfile=/tmp/supervisord.log%logfile=/dev/fd/1%' \
        -e 's%^logfile_maxbytes=50MB%logfile_maxbytes=0%' > \
        /opt/app-root/etc/supervisord.conf

cat >> /opt/app-root/etc/supervisord.conf << EOF

[include]
files = /opt/app-root/etc/supervisor/*.conf
EOF

chown 1001 /opt/app-root/bin/oc* /opt/app-root/bin/kustomize /opt/app-root/data /opt/app-root/etc/supervisord.conf
chgrp 0 /opt/app-root/bin/oc* /opt/app-root/bin/kustomize /opt/app-root/data /opt/app-root/etc/supervisord.conf
chmod g+rx /opt/app-root/bin/oc* /opt/app-root/bin/kustomize 
chmod g+rw /opt/app-root/etc/supervisord.conf
chmod g+rwxs /opt/app-root/data

# Fixup permissions on directories and files.
fix-permissions /opt/app-root
