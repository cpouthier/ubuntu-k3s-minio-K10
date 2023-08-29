# ubuntu-k3s-minio-K10
Simple script to configure a signke node Kubernetes cluster based on K3s and extra tools such as Minio and Kasten K10.

**Pre-requisites**

This scripts has been tested on a Ubuntu 22.04, it may also apply for other operating system releases.

Also ensure curl and wget are already installed.

ZFS needs to get some unformatted disk space to create the proper storage pool for Kasten.

Run the script as su (sudo su):

```console
curl -s https://raw.githubusercontent.com/cpouthier/ubuntu-k3s-minio-K10/main/installscript.sh | bash
```
