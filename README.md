Zookeeper for Kubernetes
========================

A docker image to run a Zookeeper cluster over Kubernetes.

The main difference of this image to others is that it will use DNS to build the cluster configuration instead of hardcoding all servers names in the service YAML.

How it works
------------

The idea behind this image is very straightforward: it will keep asking the DNS server the addresses of the hosts in the service and it will build a `zoo.cfg` with the addresses of these hosts (be sure to make zookeeper a headless services). The IDs of the hosts will be the values of `status.podID` without the dots that separate the octets.

All parameters are environment variables. `SERVICE_NAME` is the DNS record to be fetched. `ENSEMBLE_SIZE` is the number of hosts that the DNS server must answer before a `zoo.cfg` can be created. This *must* match the `replicas` of the `StatefulSet` (recommended) or the `ReplicationController` (avoid this as you may lose data). `ZK_INSTANCE_IP` must be the IP address that the DNS will answer for the current instance; it will be used to create a myid file. I recommend to use `status.podIP` as `ZK_INSTANCE_IP` value.

Here follows a sample `spec` for this image:

    spec:
      containers:
        - name: zookeeper
          image: pedroarthur/zookeeper-4k8s:3.4.9-1
          env:
            - name: SERVICE_NAME
              value: zoo.default.svc.cluster.local
            - name: ENSEMBLE_SIZE
              value: "3"
            - name: ZK_INSTANCE_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP

Running zookeeper with specific UID and GROUPS
----------------------------------------------

When zookeeper is part of a CI/CD infrastructure, it might be interesting to snapshot the contents of `ZK_DATA` in order to accelerate bootstrap time. A problem with this approach is that new logs will be written with root's `UID` and `GROUPS`, making it harder the workspace wipe out procedure.

With this image, one can avoid permissions problems by setting the variable `USR_ID` and `GRP_ID` with the values of `UID` and `GROUPS` of the user:

    docker run --rm -e USR_ID=$UID -e GRP_ID=$GROUPS pedroarthur/zookeeper-4k8s

Effectively, this will translate to `sudo -E -u #$USR_ID -g #$GRP_ID "${CMD[@]}"`.

TODO
----

Make all variables available without configuration!

Credits
-------

This image is a refactor of [wurstmeister's](https://github.com/wurstmeister/zookeeper-docker).

