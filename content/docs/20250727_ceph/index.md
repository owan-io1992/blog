---
date: 2025-07-27T05:54:00  
draft: false
tags: []
title: "introduction cepf"
---

<!--more-->

* Monitors: A Ceph Monitor (ceph-mon) maintains maps of the cluster state, including the monitor map, manager map, the OSD map, the MDS map, and the CRUSH map. These maps are critical cluster state required for Ceph daemons to coordinate with each other. Monitors are also responsible for managing authentication between daemons and clients. At least three monitors are normally required for redundancy and high availability.

* Managers: A Ceph Manager daemon (ceph-mgr) is responsible for keeping track of runtime metrics and the current state of the Ceph cluster, including storage utilization, current performance metrics, and system load. The Ceph Manager daemons also host python-based modules to manage and expose Ceph cluster information, including a web-based Ceph Dashboard. At least two managers are normally required for high availability.

* Ceph OSDs: An Object Storage Daemon (Ceph OSD, ceph-osd) stores data, handles data replication, recovery, rebalancing, and provides some monitoring information to Ceph Monitors and Managers by checking other Ceph OSD Daemons for a heartbeat. At least three Ceph OSDs are normally required for redundancy and high availability.

* MDSes: A Ceph Metadata Server (MDS, ceph-mds) stores metadata for the Ceph File System. Ceph Metadata Servers allow CephFS users to run basic commands (like ls, find, etc.) without placing a burden on the Ceph Storage Cluster.

* RGWs: A Ceph Object Gateway (RGW, ceph-radosgw) daemon provides a RESTful gateway between applications and Ceph storage clusters. The S3-compatible API is most commonly used, though Swift is also available.

# install

install docker https://docs.docker.com/engine/install/ubuntu/
install cephadm https://docs.ceph.com/en/latest/cephadm/install/


# install in k8s 

