FROM s2i-minimal-notebook-py38:2.5.1-rc1

ADD https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh /tmp/Anaconda3-2020.07-Linux-x86_64.sh

RUN chmod 755 /tmp/Anaconda3-2020.07-Linux-x86_64.sh && \
    /tmp/Anaconda3-2020.07-Linux-x86_64.sh -b -p /opt/anaconda3 && \
    eval "$(/opt/anaconda3/bin/conda shell.bash hook)" && \
    conda init && \
    conda config --set auto_activate_base false && \
    if [ ! -f ~/.bash_profile -a ! -f ~/.bash_login ]; then \
    	echo 'source ~/.bashrc' > ~/.bash_profile;  \
    fi && \
    fix_permissions /opt/anaconda3
