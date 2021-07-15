# This build is used as environment for automated testing with GUI (running in non-headless mode) of alza.cz 
# includes: firefox, geckodriver, python, x11vnc
# for convinience I wil call this image 'ASUG'
        # Alza
        # Shop
        # Ubuntu
        # GUI

FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP AND VSCODE
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get --assume-yes install curl gpg wget
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | \
   tee /etc/apt/sources.list.d/vs-code.list
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
# INSTALL XFCE DESKTOP AND DEPENDENCIES
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get install --assume-yes --fix-missing sudo wget apt-utils xvfb xfce4 xbase-clients \
    desktop-base vim xscreensaver google-chrome-stable python-psutil psmisc python3-psutil
# INSTALL OTHER SOFTWARE (I.E VSCODE)
RUN apt-get install --assume-yes --fix-missing code 
# INSTALL REMOTE DESKTOP
RUN wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
RUN dpkg --install chrome-remote-desktop_current_amd64.deb
RUN apt-get install --assume-yes --fix-broken
RUN bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'
# ---------------------------------------------------------- 
# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=asugusr
ARG PIN=751359
ARG CODE=4/0AX4XfWjaTUOwCxwaXW1SeAqE0LNe5JaPH0DSGnxY0dWvYOFNrAcq23cf_k8MEf7rmZ40nA
ARG HOSTNAME=$(hostname)
# ---------------------------------------------------------- 
# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER
RUN mkhomedir_helper $USER
RUN adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN usermod -aG chrome-remote-desktop $USER
USER $USER
WORKDIR /home/$USER
RUN mkdir -p .config/chrome-remote-desktop
RUN chown "$USER:$USER" .config/chrome-remote-desktop
RUN chmod a+rx .config/chrome-remote-desktop
RUN touch .config/chrome-remote-desktop/host.json
# INSTALL GOOGLE'S CHROME REMOTE DESKTOP WITH CODE, HOSTNAME AND PIN FROM ENV VAR
RUN DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/0AX4XfWh90dx79IttB1y_1o3E2r-8O6ilHpR9IDw4FP-vqDCInoa5SVyGwt8LFHReREFjYQ" --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=${HOSTNAME} --pin=${PIN}
# COPY THE CONFIGURATION TO THE NEW FILE THAT MATCHES THE CORRECT HOSTNAME (MD5 HASH THEREOF)
RUN HOST_HASH=$(echo -n $HOSTNAME | md5sum | cut -c -32) && \
    FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
    cp .config/chrome-remote-desktop/host#*.json $FILENAME
RUN sudo service chrome-remote-desktop stop
# specify firefox and geckodriver versions to obtain
ARG firefox_ver=89.0.2
ARG geckodriver_ver=0.29.1

# add universe sources to access to needed resources
RUN echo "deb http://archive.ubuntu.com/ubuntu bionic main universe\n\
deb http://archive.ubuntu.com/ubuntu bionic-security main universe\n\
deb http://archive.ubuntu.com/ubuntu bionic-updates main universe\n" >> /etc/apt/sources.list

# add locales for en_US UTF-8
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# got this snap from instrumentisto/geckodriver
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends --no-install-suggests \
            ca-certificates \
    && update-ca-certificates \
    \
    # Install tools for building
    && toolDeps=" \
        curl bzip2 \
    " \
    && apt-get install -y --no-install-recommends --no-install-suggests \
            $toolDeps \
    \
    # Download and install geckodriver
    && curl -fL -o /tmp/geckodriver.tar.gz \
            https://github.com/mozilla/geckodriver/releases/download/v${geckodriver_ver}/geckodriver-v${geckodriver_ver}-linux64.tar.gz \
    && tar -xzf /tmp/geckodriver.tar.gz -C /tmp/ \
    && chmod +x /tmp/geckodriver \
    && mv /tmp/geckodriver /usr/local/bin/ \
    \
    # Cleanup unnecessary stuff
    && apt-get purge -y --auto-remove \
                    -o APT::AutoRemove::RecommendsImportant=false \
            $toolDeps \
    && rm -rf /var/lib/apt/lists/* \
            /tmp/*

# install requiments for running tests
RUN apt-get remove -y firefox
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip python3 firefox libpci-dev libpci3
# EXTEND THE CMD WITH SLEEP INFINITY & WAIT IN ORDER TO KEEP THE REMOTE DESKTOP RUNNING
CMD [ "/bin/bash","-c","sudo service chrome-remote-desktop start ; echo $HOSTNAME ; sleep infinity & wait"]