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


# Enable ipyparallel for JubyterHub
jupyter nbextension install --sys-prefix --py ipyparallel
jupyter nbextension enable --sys-prefix --py ipyparallel
jupyter serverextension enable --sys-prefix --py ipyparallel

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

# Create additional directories.

echo " -----> Creating additional directories."

mkdir -p /opt/app-root/data

# Generate default supervisord.conf file.

echo_supervisord_conf | \
    sed -e 's%^logfile=/tmp/supervisord.log%logfile=/dev/fd/1%' \
        -e 's%^logfile_maxbytes=50MB%logfile_maxbytes=0%' > \
        /opt/app-root/etc/supervisord.conf

cat >> /opt/app-root/etc/supervisord.conf << EOF

[include]
files = /opt/app-root/etc/supervisor/*.conf
EOF

# Fixup permissions on directories and files.
# fix-permissions /opt/app-root

chown 1001 /opt/app-root/bin/oc* /opt/app-root/bin/kustomize /opt/app-root/data /opt/app-root/etc/supervisord.conf
chgrp 0 /opt/app-root/bin/oc* /opt/app-root/bin/kustomize /opt/app-root/data /opt/app-root/etc/supervisord.conf
chmod g+rx /opt/app-root/bin/oc* /opt/app-root/bin/kustomize 
chmod g+rw /opt/app-root/etc/supervisord.conf
chmod g+rwxs /opt/app-root/data
