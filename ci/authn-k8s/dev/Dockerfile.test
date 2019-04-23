FROM google/cloud-sdk:241.0.0

RUN mkdir -p /src
WORKDIR /src

# Install Docker client
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common wget && \
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce && \
    rm -rf /var/lib/apt/lists/*

# Install OpenShift client
ARG OPENSHIFT_CLI_URL
RUN mkdir -p ocbin && \
    wget -O oc.tar.gz ${OPENSHIFT_CLI_URL:-https://github.com/openshift/origin/releases/download/v3.7.2/openshift-origin-client-tools-v3.7.2-282e43f-linux-64bit.tar.gz} && \
    tar xvf oc.tar.gz --strip-components=1 -C ocbin && \
    mv ocbin/oc /usr/local/bin/oc && \
    rm -rf ocbin oc.tar.gz
