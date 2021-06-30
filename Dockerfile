# This build is used as environment for automated testing with GUI (running in non-headless mode) of alza.cz 
# includes: firefox, geckodriver, python, x11vnc
# for convinience I wil call this image 'ASUG'
        # Alza
        # Shop
        # Ubuntu
        # GUI

FROM ubuntu:latest

# specify firefox and geckodriver versions to obtain
ARG firefox_ver=89.0.2
ARG geckodriver_ver=0.29.1
# pass for vnc
ARG x11vnc_pass=1234
# run privileged
USER root

# add universe sources to access to needed resources
RUN echo "deb http://archive.ubuntu.com/ubuntu bionic main universe\n\
deb http://archive.ubuntu.com/ubuntu bionic-security main universe\n\
deb http://archive.ubuntu.com/ubuntu bionic-updates main universe" >> /etc/apt/sources.list

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
    # Install dependencies for Firefox
    && apt-get install -y --no-install-recommends --no-install-suggests \
            `apt-cache depends firefox-esr | awk '/Depends:/{print$2}'` \
            # additional 'firefox-esl' dependencies which is not in 'depends' list
            libxt6 \
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
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip python3 x11vnc xvfb firefox
# add pass to x11vnc
RUN mkdir ~/.vnc && x11vnc -storepasswd ${x11vnc_pass} ~/.vnc/passwd

RUN iconfig