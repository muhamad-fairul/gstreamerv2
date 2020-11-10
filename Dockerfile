FROM ubuntu:18.04
#FROM ubuntu:saucy

# install required packages
RUN apt-get update
RUN apt-get install -y apt-transport-https
RUN echo 'deb http://private-repo-1.hortonworks.com/HDP/ubuntu14/2.x/updates/2.4.2.0 HDP main' >> /etc/apt/sources.list.d/HDP.list
RUN echo 'deb http://private-repo-1.hortonworks.com/HDP-UTILS-1.1.0.20/repos/ubuntu14 HDP-UTILS main'  >> /etc/apt/sources.list.d/HDP.list
RUN echo 'deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/azurecore/ trusty main' >> /etc/apt/sources.list.d/azure-public-trusty.list
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:Intel123!' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN apt-get -y install software-properties-common apt-utils vim htop dpkg-dev \
  openssh-server git-core wget software-properties-common
RUN echo $(lsb_release -sc)
RUN apt-add-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) multiverse"
RUN apt-get update

RUN apt-get install -y faac yasm

# create the ubuntu user
RUN addgroup --system ubuntu
RUN adduser --system --shell /bin/bash --gecos 'ubuntu' \
  --uid 1000 --disabled-password --home /home/ubuntu ubuntu
RUN adduser ubuntu sudo
RUN echo ubuntu:ubuntu | chpasswd
RUN echo "ubuntu ALL=NOPASSWD:ALL" >> /etc/sudoers
USER ubuntu
ENV HOME /home/ubuntu
WORKDIR /home/ubuntu

# Git config is needed so that cerbero can cleanly fetch some git repos
RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"

# build gstreamer 1.0 from cerbero source
# the build commands are split so that docker can resume in case of errors
RUN git clone --depth 1 git://anongit.freedesktop.org/gstreamer/cerbero
# hack: to pass "-y" argument to apt-get install launched by "cerbero bootstrap"
RUN sed -i 's/apt-get install/apt-get install -y/g' cerbero/cerbero/bootstrap/linux.py
RUN cd cerbero; ./cerbero-uninstalled bootstrap

RUN cd cerbero; ./cerbero-uninstalled build \
  glib bison gstreamer-1.0

RUN cd cerbero; ./cerbero-uninstalled build \
  py2cairo pygobject gst-plugins-base-1.0 gst-plugins-good-1.0 

RUN cd cerbero; ./cerbero-uninstalled build \
  gst-plugins-bad-1.0 gst-plugins-ugly-1.0

RUN cd cerbero; ./cerbero-uninstalled build \
  gst-libav-1.0

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
