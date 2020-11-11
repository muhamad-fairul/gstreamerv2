FROM ubuntu:18.04

RUN apt-get update && apt-get install -y openssh-server
RUN apt-get install -y git build-essential libssl-dev
RUN wget https://github.com/Kitware/CMake/releases/download/v3.16.5/cmake-3.16.5.tar.gz
RUN tar -zxvf cmake-3.16.5.tar.gz
WORKDIR cd cmake-3.16.5 && ./bootstrap
RUN make
RUN make install 
RUN mkdir /var/run/sshd
RUN echo 'root:Intel123!' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

#ADD head-pose-face-detection-female-and-male /gstreamer
RUN mkdir /gstreamer
WORKDIR /gstreamer

#install openvino
RUN git clone https://github.com/openvinotoolkit/openvino.git
WORKDIR openvino
RUN git submodule update --init --recursive
RUN chmod +x install_build_dependencies.sh
RUN ./install_build_dependencies.sh
RUN mkdir build
WORKDIR build
RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make --jobs=$(nproc --all)

#install gstreamer
WORKDIR /gstreamer
RUN apt install snapd
RUN snap install gstreamer --edge
RUN apt-get install libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio

#add video and playback
ADD head-pose-face-detection-female-and-male.mp4 /gstreamer
RUN gst-launch-1.0 filesrc location=head-pose-face-detection-female-and-male.mp4 ! decodebin ! videoconvert ! ximagesink sync=false

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
