# LROSE Nightly Builds

In order to allow gateway users access to the latest LROSE developments, we
implement nightly builds of LROSE. These builds are done within the gateway's
Kubernetes cluster as a Kubernetes CronJob.

## Quick Start

For a more in depth explanation, see subsequent sections.

- Ensure you have an [NFS shared drive](https://www.zonca.dev/posts/2025-04-22-nfs-server-jetstream2) enabled on the gateway
- Create a ConfigMap from `build-and-install.sh`:
  `kubectl create configmap lrose-nightly --from-file build-and-install.sh`
- Edit `lrose-core-cronjob.yaml` to have the appropriate NFS server address
- Apply the CronJob manifest: `kubectl apply -f lrose-core-cronjob.yaml`

You should now see a CronJob resource in the default namespace:

```bash
$ kubectl get cj
NAME            SCHEDULE    TIMEZONE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
lrose-nightly   0 0 * * *   US/Mountain   False     0        3h41m           3h44m
```

This should create a Job every night at midnight, US/Mountain time. If you want
to manually run a Job, use the following:
`kubectl create job lrose-core-build --from=cronjob/lrose-nightly`

## The CronJob

### General Information

A [Kubernetes
CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
will create a
[Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/) on a fixed
schedule. These Jobs will subsequently create Pods which will attempt to run to
completion. The CronJob, which manages Jobs and their associated Pods, is
configured to keep up to two successful and two unsuccessful Job runs. As more
Jobs are created, older Jobs will be automatically pruned by Kubernetes. This
also applies to any Jobs that are created using the `kubectl create job
--from=cronjob-nightly` command.

A script called `build-and-install.sh` is run by the Pod. This script will clone
the [lrose-bootstrap](https://github.com/NCAR/lrose-bootstrap) repository and
run some of its associated scripts in order to build
[lrose-core](https://github.com/NCAR/lrose-core).

### build-and-install.sh

The `build-and-install.sh` script can be found in the Pod at
`/lrose-nightly-scripts/build-and-install.sh`. It is worth noting that this
script is not included as part of the Docker image that the Pod runs,
(`ubuntu:24.04`), but rather is mounted onto the Pod via a "ConfigMap". The
ConfigMap is created using the following command:

`kubectl create configmap lrose-nightly --from-file build-and-install.sh`

Since it is the *ConfigMap* that is mounted onto the Pod and not the file
itself, changes to the `build-and-install.sh` file will not propogate to the
build Pods on their own. Rather, you would have to re-run the above command to
apply those changes to the ConfigMap.

In addition, these changes would only affect *new* Jobs; any existing Jobs would
not get these changes applied to them.

You can see the data in the ConfigMap using:

`kubectl describe cm lrose-nightly`

### Output Locations and Logging

The build takes place in a temporary directory, `/tmp/lrose-build`, of the Job
Pod. Build logs are placed in `/lrose-nightly/build-logs`. You can login to a
`bash` shell to see them using the following command:

```
kubectl exec -it <pod-name> -- /bin/bash
```

Additionally, as information is also printed to the Pod's standard output, you
can inspect this output using the normal Kubernetes method of:

`kubectl logs <pod-name>`

If the build succeeds, the new build will then be installed in the
`/share/lrose-nightly` path of the NFS shared drive, which is mounted onto the
build Pod at `/share`.

We keep the build logs separate from the final install location for two reasons:

1) It's not necessary for the end user to see them
2) Build logs would be over-written on the shared drive after every run

As we keep a 2 Job run history, we do not need to worry about logs being
overwritten before gateway administrators have a chance to inspect them.

### CronJob Management

To apply the CronJob manifest, use the standard command:

`kubectl apply -f lrose-nightly.yaml`

The above command can also be used to apply changes after editing
`lrose-nightly.yaml`.

You can see the CronJob with a:

`kubectl get cj`

You can see the Jobs it's created with:

`kubectl get jobs`

As mentioned in a previous section, Jobs will create Pods for you that carry out
the actual workflow. See these with a:

`kubectl get pods`

In the event that you need to delete a build Pod, it is recommended that you do
so by deleting its associated Job instead of the Pod itself, as deleting the Job
will also delete the Pod, but the opposite is not true. This makes sure that we
don't have any "orphaned" Jobs:

`kubectl delete job <job-name>`

If you need to suspend the execution of a CronJob, do so by setting
`spec.suspend` to `true` in the `lrose-nightly.yaml` manifest and re-applying
it as was explained above.

### Creating a Dedicated Build Node

The `lrose-nightly.yaml` manifest configures the Job Pods to run on the
`mediums` node group. It is unlikely that these Pods would disallow single user
Pods from being scheduled or running, as build Pods don't need any resources
after they've completed the build, something which is only attempted overnight.

If we decide that we need a dedicated node for the LROSE nightly builds, we can
create a new node group for this purpose. However, keep in mind that node groups
must always have 1 node active in the node group at all times, which means one
new machine consuming SUs. We create it as an `m3.quad` to reduce the amount of
SUs used. It may be possible to make this an `m3.small` and use even fewer SUs,
after all, the build will be performed over night, so high performance isn't
strictly required:
```
openstack coe nodegroup create lrosehub lrose-nightly \
    --node-count 1 \
    --flavor m3.quad \
    --labels auto_scaling_enabled=true \
    --min-nodes 1 \
    --max-nodes 1
```

After the node has been created, we can change the `nodeSelector` setting in
`lrose-nightly.yaml` to `lrose-nightly`, and the build Pods should be scheduled
in this dedicated node.
