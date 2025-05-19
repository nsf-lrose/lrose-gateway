- [LROSE Gateway](#h-3B253038)
  - [Project Purpose](#h-801FE3E2)
  - [Target Audience](#h-6182AF53)
  - [Features](#h-7F816516)
  - [Prerequisites](#h-20066193)
  - [Getting Started](#h-1B77807C)
    - [OpenStack Control VM on Jetstream2](#h-AD29AAF8)
      - [Listing and Entering Current OpenStack and Hub Environments](#h-159666A2)
        - [openstack](#h-5D58BCD6)
        - [lrosehub](#h-719F0291)
      - [Tmux (Optional but Recommended)](#h-5108A4E1)
  - [Deployment Scenarios](#h-6BCD4BE2)
    - [Defining a JupyterHub Cluster](#h-487A6DED)
      - [Clone This Repository](#h-6C528D05)
      - [Define New Environment](#h-6F85DF5F)
        - [Dockerfile](#h-40A2B831)
        - [environment.yml](#h-7D30C8A2)
      - [Building and Pushing This Dockerfile](#h-B3E459BA)
      - [secrets.yaml](#h-B14026AE)
        - [User Authentication](#h-59C832DA)
        - [Public Web Access](#h-67E578ED)
        - [Core Pod Scheduling](#h-425C921A)
        - [User Notebook Environments](#h-142FD687)
        - [Compute Profiles for Users](#h-D88529F6)
    - [Building an Openstack and Kubernetes Environment for Openstack Control VM](#h-F46724A8)
      - [Preamble](#h-9E8E78DC)
      - [Build Container](#h-C32DFB87)
      - [Launch the Container for OpenStack Interaction](#h-A054C5DC)
    - [Launching a Jetstream2 Openstack Magnum Cluster](#h-C18A5351)
      - [Preamble](#h-5EFA4896)
      - [Obtain openrc.Sh App Credentials for Magnum Clusters](#h-34D247DF)
      - [Obtain or Re-use an IP address](#h-B6B2E201)
      - [Launch Cluster Building Environment](#h-FBA11C0F)
      - [Launching the JupyterHub](#h-C9998D99)
        - [AZ Blog](#h-A9D2E815)
        - [Create Cluster](#h-53E51B30)
  - [Troubleshooting](#h-D10BD7C2)
  - [Useful Commands and Tips](#h-955ECD64)
    - [OpenStack](#h-C071CE11)
    - [Kubernetes](#h-B0E4F09D)



<a id="h-3B253038"></a>

# LROSE Gateway


<a id="h-801FE3E2"></a>

## Project Purpose

The [LROSE (Lidar Radar Open Software Environment)](https://www.eol.ucar.edu/content/lidar-radar-open-software-environment) Gateway project provides a framework for building and deploying one or more JupyterHubs on the [NSF Jetstream2](https://docs.jetstream-cloud.org/ui/cli/auth/#about-openrcsh-files) cloud. These JupyterHubs integrate LROSE tools for workshops or long-term use, leveraging Kubernetes via OpenStack Magnum on Jetstream2.


<a id="h-6182AF53"></a>

## Target Audience

This project is intended for software engineers at NSF NCAR EOL (Earth Observing Laboratory) and LROSE scientist collaborators at Colorado State University responsible for maintaining JupyterHubs equipped with LROSE technology on Jetstream2.


<a id="h-7F816516"></a>

## Features

-   A containerized environment running on a Jetstream2 OpenStack Control VM, designed to manage OpenStack and Kubernetes resources directly from within Jetstream2. Multiple instances of this environment can be launched in parallel to access the OpenStack CLI (Command Line Interface) or to create and manage JupyterHub clusters.
-   Structured directories, each containing the configuration files needed to set up and run a specific LROSE JupyterHub cluster, whether for a short-term workshop or a long-term deployment.


<a id="h-20066193"></a>

## Prerequisites

-   [An NSF Access allocation on the Jetstream2 Cloud](https://docs.jetstream-cloud.org/alloc/overview/#access-credits-and-thresholds)
-   [CLI access to Jetstream2 OpenStack](https://docs.jetstream-cloud.org/ui/cli/overview/)
    -   A properly configured [openrc.sh](https://docs.jetstream-cloud.org/ui/cli/auth/#setting-up-application-credentials-and-openrcsh-for-the-jetstream2-cli) file
-   Access to the LROSE OpenStack VM on Jetstream2


<a id="h-1B77807C"></a>

## Getting Started


<a id="h-AD29AAF8"></a>

### OpenStack Control VM on Jetstream2


<a id="h-159666A2"></a>

#### Listing and Entering Current OpenStack and Hub Environments

`ssh` into the Jetstream2 OpenStack Control VM. Running the `docker ps` command will list the cluster environments that are running. We will assume these running Docker containers have already been set up on your behalf. Later in this document we will discuss how to actually build and launch these environments.

```sh
$ docker ps
# example output
CONTAINER ID   IMAGE                     COMMAND       CREATED          STATUS          PORTS     NAMES
5ee8ad793895   nsf-lrose/lrose-gateway   "/bin/bash"   10 minutes ago   Up 10 minutes             openstack
b2b9a7e97503   nsf-lrose/lrose-gateway   "/bin/bash"   14 minutes ago   Up 14 minutes             lrosehub
...
```

Listed here are two distinct but related Docker containers: a generic `openstack` environment for exploring and issuing OpenStack commands, and `lrosehub` for managing the Kubernetes cluster associated with that hub. In fact, under the hood, they are different instances of the same Docker image (`nsf-lrose/lrose-gateway`) being used for different purposes.


<a id="h-5D58BCD6"></a>

##### openstack

OpenStack is the cloud infrastructure platform used by Jetstream2 to manage and provision virtual machines, networks, persistent storage, and other cloud computing resources. You can enter a running docker container with `docker exec -it <container id or name> /bin/bash`. To enter the `openstack` environment:

```sh
$ docker exec -it openstack bash
```

This OpenStack environment provides a command-line interface (CLI) for interacting with OpenStack services. For example, running `openstack server list`, aliased with `osl` will display a list of servers in the OpenStack environment as shown below:

```sh
  $ osl
  # Example output
+--------------------------------------+--------------------------------------------------+--------+----------------------------------------------------+--------------------------+-----------+
  | ID                                   | Name                                             | Status | Networks                                           | Image                    | Flavor    |
  +--------------------------------------+--------------------------------------------------+--------+----------------------------------------------------+--------------------------+-----------+
  | a402ab54-977b-4c1a-8613-c5224e23ce3a | openstack-ctrl                                   | ACTIVE | auto_allocated_network=10.0.1.30, 149.165.173.141  |                          | m3.medium |
  | 24084f8e-7973-4beb-9da3-5ddafe059af9 | lrosehub-omunlpsjerxx-mediums-r8lq4-fvnlv        | ACTIVE | auto_allocated_network=10.0.1.35                   | N/A (booted from volume) | m3.medium |
  | 03abba97-68fb-4739-bf64-de392cb813eb | lrosehub-omunlpsjerxx-default-worker-fqtm2-789jg | ACTIVE | auto_allocated_network=10.0.1.170                  | N/A (booted from volume) | m3.quad   |
  | 32f4cd65-f045-4e92-b273-55354669666e | lrosehub-omunlpsjerxx-control-plane-drgtr        | ACTIVE | auto_allocated_network=10.0.1.129                  | N/A (booted from volume) | m3.quad   |
  | 57462b28-90e8-4114-8eaf-14c58d0c1bda | needlessly-more-katydid                          | ACTIVE | auto_allocated_network=10.0.1.201, 149.165.152.223 |                          | m3.medium |
  | e9e424c3-6538-4410-a4ea-f121f9d3fc03 | firstly-thankful-lacewing                        | ACTIVE | auto_allocated_network=10.0.1.122, 149.165.168.41  |                          | m3.tiny   |
  +--------------------------------------+--------------------------------------------------+--------+----------------------------------------------------+--------------------------+-----------+-
```


<a id="h-719F0291"></a>

##### lrosehub

To enter the `lrose` environment:

```sh
$ docker exec -it lrosehub bash
```

To quickly check the cluster's nodes, you can run the following `kubectl` command aliased with `k`:

```sh
$ k get nodes -A
# example output
NAME                                               STATUS   ROLES           AGE   VERSION
lrosehub-omunlpsjerxx-control-plane-drgtr          Ready    control-plane   49d   v1.30.4
lrosehub-omunlpsjerxx-default-worker-fqtm2-789jg   Ready    <none>          49d   v1.30.4
lrosehub-omunlpsjerxx-mediums-r8lq4-fvnlv          Ready    <none>          17d   v1.30.4
```


<a id="h-5108A4E1"></a>

#### Tmux (Optional but Recommended)

An optional but highly convenient tool is the terminal multiplexer tool, [tmux](https://www.redhat.com/en/blog/introduction-tmux-linux), that can serve as an OpenStack Hub dashboard. `tmux` is a command-line tool that allows you to detach and reattach to persistent CLI sessions. When you detach from a `tmux` session, it remains running in the background, even after you've logged off, enabling you to reattach to it later and resume where you left off.

To list what `tmux` sessions may already be present:

```sh
tmux list-sessions
# example output
julien: 1 windows (created Thu May 15 16:19:49 2025)
```

To start a new `tmux` session:

```sh
tmux new-session -s <session name>
```

After sshing into the OpenStack control VM, you can enter a pre-existing `tmux` session with:

```sh
tmux attach -n <your optional name>
```

[Tmux Cheat Sheet & Quick Reference](https://tmuxcheatsheet.com/)


<a id="h-6BCD4BE2"></a>

## Deployment Scenarios


<a id="h-487A6DED"></a>

### Defining a JupyterHub Cluster

So far, we've assumed you have access to an LROSE JupyterHub cluster. Now, we'll walk through setting one up. You can use the existing OpenStack control VM, launch a new VM on Jetstream2, or do this locally on your computer. Make sure you have `git` and `docker` installed which should already be available on Jetstream2 VMs including the OpenStack control VM. If using the OpenStack control VM, you can launch a new `tmux` window with `ctrl+b c` .


<a id="h-6C528D05"></a>

#### Clone This Repository

```sh
git clone https://github.com/nsf-lrose/lrose-gateway
```


<a id="h-6F85DF5F"></a>

#### Define New Environment

Define a new JupyterHub environment in a directory in `lrose-gateway/hubs/` (e.g., `lrose-gateway/hubs/ams-2026`) using `lrose-gateway/hubs/gateway` as a template.

```sh
# For example,
cp -R lrose-gateway/hubs/gateway/ lrose-gateway/hubs/ams-2026/
```

The files that you will want to examine and possibly modify depending on your objectives are: `Dockerfile`, `environment.yml`, `secrets.yaml`.


<a id="h-40A2B831"></a>

##### Dockerfile

This `Dockerfile` builds a JupyterLab environment with these components:

1.  Downloads, installs via a Debian package and configures LROSE software.
2.  Adds XFCE desktop environment with VNC/novnc for browser-based GUI access via Jupyter server proxy.
3.  Sets up a Conda environment with packages such as `ncview` and the Python packages defined in the co-located `environment.yml` file.


<a id="h-7D30C8A2"></a>

##### environment.yml

The conda environment the user will be using in their JupyterLab environment, in this case, equipped with a standard set of Python meteorological (e.g., `metpy`) and radar analysis packages (e.g., `arm_pyart`). This file is referenced in the `Dockerfile` above and will be built in that container. If you need additional Python packages in the JupyterLab environment, you will add them here.


<a id="h-B3E459BA"></a>

#### Building and Pushing This Dockerfile

To deploy the environment, this `Dockerfile` must be built and pushed to a Docker registry, an online repository for container images. The registry URL is referenced in `secrets.yaml` so that Kubernetes can pull the correct image.

Several registries exist (e.g., Docker Hub, GitHub Container Registry, Quay.io). You will have to obtain an account on one of these for the next step. Use `docker login` to authenticate:

```sh
docker login <registry>
# for example
docker login ghcr.io
```

Then build and push an image

```sh
docker build -t <registry>/<username>/<name>:<tag> .
docker push <registry>/<username>/<name>:<tag>
```

For example,

```sh
docker build -t ghcr.io/nsf-lrose/lrose-hub-ams-2026:latest .
docker push ghcr.io/nsf-lrose/lrose-hub-ams-2026:latest
```

**NB**: Docker registries have been getting stricter about enforcing download limits. This fact will be something to be aware of during the deployment of these JupyterHub clusters.


<a id="h-B14026AE"></a>

#### secrets.yaml

**Warning**: Make sure not to put secret credentials in version control. Specifically, values listed below should only be "visible" from the deployed Hub. We will be covering how to use this `secrets.yaml` during the deployment phase later in this document.

-   Docker registry credentials (`username`, `password`)
-   JupyterHub cookie secret (`cookieSecret`)
-   GitHub OAuth credentials (`client_id`, `client_secret`)
-   JupyterHub proxy secret token (`secretToken`)

The YAML configuration defines a JupyterHub deployment on Kubernetes with:

-   Secure Access to Docker Images
-   User Authentication
-   Public Web Access
-   Core Pod Scheduling
-   User Notebook Environments
-   Compute Profiles for Users

We will covers some of these topics in turn:


<a id="h-59C832DA"></a>

##### User Authentication

```yaml
config:
  Authenticator:
    admin_users:
      - admin
    allowed_users:
      - users
    allow_existing_users: true
  JupyterHub:
    authenticator_class: github
  GitHubOAuthenticator:
   client_id: "xxx"
   client_secret: "xxx"
```

GitHub OAuth is a robust and reliable method of providing authentication for the JupyterHub. This section of the configuration sets up GitHub-based OAuth for the deployed JupyterHub. It defines a list of **admin users** and **allowed users**. The `GitHubOAuthenticator` block contains the necessary parameters (`client_id`, `client_secret`, and `oauth_callback_url`) for integrating with GitHub's OAuth system.

To obtain the `client_id` and `client_secret`, you must:

Go to <https://github.com/settings/developers>.

Click "New OAuth App".

Fill out the form, setting the Authorization callback URL to match your deployment (e.g., <https://your-domain.org/oauth_callback>).

After creating the app, GitHub will display the Client ID and allow you to generate a Client Secret.

**These credentials should be kept confidential and never committed to version control.**


<a id="h-67E578ED"></a>

##### Public Web Access

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt"
    nginx.ingress.kubernetes.io/proxy-body-size: 500m
  hosts:
      - lrosehub.ees200002.projects.jetstream-cloud.org
  tls:
      - hosts:
         - lrosehub.ees200002.projects.jetstream-cloud.org
```

This section configures Ingress, which is how external users access the JupyterHub service over the web. It enables Ingress using NGINX. It also sets up TLS encryption (HTTPS) using Let's Encrypt via `cert-manager`, which automatically issues and renews the SSL certificate. The certificate is stored under the Kubernetes secret named `certmanager-tls-jupyterhub`. [Andrea Zonca's blog covers this topic in more detail](https://www.zonca.dev/posts/2023-09-26-https-kubernetes-letsencrypt).


<a id="h-425C921A"></a>

##### Core Pod Scheduling

```yaml
scheduling:
  corePods:
    tolerations:
      - key: hub.jupyter.org/dedicated
        operator: Equal
        value: core
        effect: NoSchedule
      - key: hub.jupyter.org_dedicated
        operator: Equal
        value: core
        effect: NoSchedule
    nodeAffinity:
      matchNodePurpose: require
  podPriority:
    enabled: true
  userPlaceholder:
```

This part of the configuration controls how core pods of JupyterHub are scheduled to run on a Kubernetes cluster. It sets tolerations, which allow these pods to be scheduled on nodes marked with specific labels (`hub.jupyter.org/dedicated=core`) reserving those nodes for essential services like the hub and proxy. The `nodeAffinity` rule further ensures that these core pods only run on nodes explicitly designated for that purpose. `podPriority` is enabled so that critical system pods can preempt lower-priority workloads if resources become scarce. Finally, `userPlaceholder.replicas: 2` creates two idle "placeholder" pods to speed up user startup times by keeping resources active and ready.


<a id="h-142FD687"></a>

##### User Notebook Environments

```yaml
singleuser:
  nodeSelector:
    capi.stackhpc.com/node-group: mediums
  extraEnv:
    NBGITPULLER_DEPTH: "0"
    START_VIRTUAL_DESKTOP: "1"
  storage:
    capacity: 10Gi
  startTimeout: 600
  memory:
    guarantee: 24G
    limit: 24G
  cpu:
    guarantee: 6
    limit:  6
  defaultUrl: "/lab"
  image:
    name: nsflrose/lrose-hub-2025
    tag: "<tag>"
  lifecycleHooks:
    postStart:
      exec:
          command:
            - "bash"
            - "-c"
            - >
              gitpuller https://github.com/nsf-lrose/lrose-hub main lrose-hub;
              cp /update_workshop_material.ipynb /home/jovyan;
              cp /Acknowledgements.ipynb /home/jovyan;
              [[ -f $HOME/.condarc ]] || cp /.condarc /home/jovyan;
              [[ -f $HOME/.bashrc ]] || cat /etc/skel/.bashrc /bashrc_lrose /home/jovyan/.bashrc;
              [[ -f $HOME/.profile ]] || cp /.profile /home/jovyan;
              [[ -f $HOME/.lrose-nightly.ipynb ]] || cp /lrose-nightly.ipynb /home/jovyan;
```

This section defines how each user's Jupyter environment (container) is configured and launched. It specifies the computing resources (CPU, memory, storage), and the container image to use. The `image` section specifies the Docker container image that was built and pushed earlier that will be used to launch each user's Jupyter environment. After startup, it runs a custom script to pull course materials from GitHub and set up the user's environment with default configuration files and shared directories.


<a id="h-D88529F6"></a>

##### Compute Profiles for Users

```yaml
profileList:
- display_name: "Low Power (m3.small)"
  description: "4 GB of memory; 1.5 vCPUS"
  kubespawner_override:
    mem_guarantee: 2G
    mem_limit: 2G
    cpu_guarantee: 1.5
    cpu_limit: 1.5
    node_selector:
      capi.stackhpc.com/node-group: default-worker

- display_name: "Medium Power (m3.medium)"
  default: true
  description: "12 GB of memory; 3.5 vCPUS"
  kubespawner_override:
    mem_guarantee: 12G
    mem_limit: 12G
    cpu_guarantee: 3.5
    cpu_limit: 3.5
    node_selector:
      capi.stackhpc.com/node-group: mediums

- display_name: "High Power (m3.medium)"
  description: "24 GB of memory; 6 vCPUS"
  kubespawner_override:
    mem_guarantee: 24G
    mem_limit: 24G
    cpu_guarantee: 6
    cpu_limit: 6
    node_selector:
```

This section defines a menu of computing resource "profiles" that users can choose from when starting their Jupyter environment. The `Medium Power` profile is set as the default.


<a id="h-F46724A8"></a>

### Building an Openstack and Kubernetes Environment for Openstack Control VM


<a id="h-9E8E78DC"></a>

#### Preamble

Up to this point, we have assumed the environment to interact with Openstack Jetstream2 already exists. In this section, we will discuss how to actually create and launch this environment so that you can interact with OpenStack from the command line within that container.


<a id="h-C32DFB87"></a>

#### Build Container

The `Dockerfile` for this container is located in `lrose-gateway/openstack/`. It creates a development environment tailored for managing cloud infrastructure for OpenStack and Kubernetes.

The salient features of this container:

-   command-line tools: `vim`, `nano`, `git`, `wget`, `rsync`, `jq`, etc.
-   Kubernetes CLI tool `kubectl`
-   Terraform which is an infrastructure-as-code tool that allows you to define, provision, and manage cloud resources using declarative configuration files.
-   Helm which is a package manager for Kubernetes that simplifies the deployment and management of applications using reusable configuration templates called "charts".
-   OpenStack Python clients (e.g., `openstackclient`, `designate`, `magnum`, `octavia`).
-   Creates an `openstack` user.
-   Defines a number of shell aliases (e.g., `alias k='kubectl'`)
-   Customizes the shell prompt to reflect the current openstack container or Kubernetes cluster

This container can be constructed on the OpenStack Control VM referenced in this document, provided that the Git repository has been cloned previously. To build the container, run the following command:

```sh
docker build -t nsf-lrose/lrose-gateway .
```


<a id="h-A054C5DC"></a>

#### Launch the Container for OpenStack Interaction

Once the container has been built, you can launch it once you have [fetched your `openrc.sh` file](https://docs.jetstream-cloud.org/ui/cli/auth/#setting-up-application-credentials-and-openrcsh-for-the-jetstream2-cli).

```sh
openstack_launcher.sh -o <openrc.sh>
```

You can now start issuing OpenStack commands, such as listing volumes with `openstack volume list` using the `ovl` alias.

```sh
  $ ovl
+--------------------------------------+-------------------------------------------------------+-----------+------+---------------------------------------------------------------------------+
| ID                                   | Name                                                  | Status    | Size | Attached to                                                               |
+--------------------------------------+-------------------------------------------------------+-----------+------+---------------------------------------------------------------------------+
| 44b09e53-2087-43bf-abdf-e98448ad324e | lrosehub-omunlpsjerxx-mediums-r8lq4-tvd7l-root        | in-use    |   30 | Attached to lrosehub-omunlpsjerxx-mediums-r8lq4-tvd7l on /dev/vda         |
| 1bee722a-7896-4ab0-b44c-14b9671e8c09 | lrosehub-omunlpsjerxx-mediums-r8lq4-nlrzw-root        | in-use    |   30 | Attached to lrosehub-omunlpsjerxx-mediums-r8lq4-nlrzw on /dev/vda         |
| 765267c7-c69a-49d3-8434-dafad55b6195 | lrosevc-storage                                       | available | 1000 |                                                                           |
+--------------------------------------+-------------------------------------------------------+-----------+------+---------------------------------------------------------------------------+
```


<a id="h-C18A5351"></a>

### Launching a Jetstream2 Openstack Magnum Cluster


<a id="h-5EFA4896"></a>

#### Preamble

Once you have defined your cluster, you are ready to launch the OpenStack Magnum cluster building environment. Magnum is an OpenStack technology available on Jetstream2 that enables the deployment of autoscaling Kubernetes clusters. These clusters dynamically adjust their size in response to changing usage demands. By providing users with scalable clusters, Magnum ensures users have access to the necessary computational capacity (e.g., for remote Desktop environments), while also optimizing for Jetstream2 resource utilization. We will employ these clusters to implement the JupyterHub with Kubernetes workflow for launching a JupyterHub equipped with LROSE.


<a id="h-34D247DF"></a>

#### Obtain openrc.Sh App Credentials for Magnum Clusters

In order to launch OpenStack Magnum clusters, we need to work with a slightly different `openrc.sh` that gives us sufficient permissions to launch Magnum clusters. Obtain a second `openrc.sh` via the [Access Credentials](https://docs.jetstream-cloud.org/ui/cli/auth/#about-openrcsh-files) interface creating a new “Unrestricted (dangerous)” Application Credential via the Horizon interface, under Identity → Application Credentials. Let's call this second application credential `openrc-magnum.sh`.


<a id="h-B6B2E201"></a>

#### Obtain or Re-use an IP address

To begin, you will need to obtain or reuse a public IP address from Jetstream2. To do this, access the OpenStack container, as previously discussed. Once inside, you can list the available IP addresses to determine if there are any that can be allocated for the new LROSE cluster.

```sh
openstack floating ip list # aliased with ofl
```

If one is available indicated by `None`, make a note of it. If none are available, you can create a new one with:

```sh
openstack floating ip create public
```


<a id="h-FBA11C0F"></a>

#### Launch Cluster Building Environment

Once you have an available IP address, launch the cluster building environment using the command below located in `lrose-gateway/openstack`. Select the `name` carefully, as this will be the name of the cluster, including what will be facing the internet.

```sh
bash cluster_launcher.sh [-n <name>] [-p <ip>] [-o <openrc>]
```

For example,

```
$ bash cluster_launcher.sh -n lrose-test314 -p 149.165.154.1 -o ~/openrc-magnum.sh
Created base directory: /home/rocky/lrose-gateway/openstack/jhubs/lrose-test314
❯ (lrose-test314) ~ ➜
```


<a id="h-C9998D99"></a>

#### Launching the JupyterHub


<a id="h-A9D2E815"></a>

##### AZ Blog

At this point, we will follow instructions from Andrea Zonca regarding the construction of a Magnum cluster detailed in the blog post [Deploy Kubernetes and JupyterHub on Jetstream with Magnum and Cluster API](https://www.zonca.dev/posts/2024-12-11-jetstream_kubernetes_magnum). Note that many of the steps concerning software installation have already been completed for you inside the OpenStack Docker container that we have been working with throughout this document.


<a id="h-53E51B30"></a>

##### Create Cluster

`cd` to the `kubernetes_magnum` directory.

```sh
➜ cd ~/jupyterhub-deploy-kubernetes-jetstream/kubernetes_magnum/
```

In your favorite editor (e.g., `vi`, `nano`), examine the cluster creation script `create_cluster.sh`. We will leave the contents of the script alone, but you can make a note of what is configurable herein.

Next

```sh
➜ bash create_cluster.sh
```

You will see output that looks something like this:

```sh
Request to create cluster a6dffbe3-5ad7-4ebd-a913-4ce791ec395b accepted
Waiting for the cluster to become ready...
Time passed: 0 minutes. Current status: CREATE_IN_PROGRESS
Time passed: 1 minutes. Current status: CREATE_IN_PROGRESS
...
Time passed: 9 minutes. Current status: CREATE_COMPLETE
Cluster creation took 9 minutes.
```


<a id="h-D10BD7C2"></a>

## Troubleshooting


<a id="h-955ECD64"></a>

## Useful Commands and Tips


<a id="h-C071CE11"></a>

### OpenStack


<a id="h-B0E4F09D"></a>

### Kubernetes
