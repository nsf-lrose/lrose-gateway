FROM rockylinux:9

ARG TERRAFORM_VERSION=0.14.4
ARG HELM_VERSION=3.8.2

ENV HOME=/home/openstack \
    PATH=/home/openstack/bin:$PATH

RUN mkdir -p /home/openstack/bin

# Maybe later
# COPY bin/*.sh /home/openstack/bin/
COPY .bashrc /home/openstack/

RUN printf '[kubernetes]\n\
name=Kubernetes\n\
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key\n' \
    > /etc/yum.repos.d/kubernetes.repo && \
    yum upgrade -y && yum install -y epel-release && \
    yum install -y sudo man man-pages vim nano git wget unzip ncurses procps \
    htop python3 telnet openssh openssh-clients openssl findutils diffutils \
    vi less kubectl pip rsync jq && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    curl -sSL https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | \
    tar -xz -C /usr/local/bin --strip-components=1 linux-amd64/helm && \
    useradd -ms /bin/bash openstack && \
    echo 'openstack:docker' | chpasswd && \
    echo 'openstack ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/openstack && \
    git clone https://github.com/zonca/jupyterhub-deploy-kubernetes-jetstream \
        /home/openstack/jupyterhub-deploy-kubernetes-jetstream && \
    git clone https://github.com/nsf-lrose/lrose-gateway \
        /home/openstack/lrose-gateway && \
    pip3 install --upgrade pip && \
    pip3 install --upgrade 'python-openstackclient<7' python-designateclient  \
        python-magnumclient python-octaviaclient --ignore-installed && \
    chown -R openstack:openstack /home/openstack
    # && chmod +x /home/openstack/bin/*.sh

WORKDIR /home/openstack
USER openstack
