# Karmada-Mac

[![CI Workflow](https://github.com/ikaven1024/karmada-mac/actions/workflows/ci.yml/badge.svg)](https://github.com/ikaven1024/karmada-mac/actions/workflows/ci.yml)

Run [karmada](https://github.com/karmada-io/karmada) natively on Mac, without virtual machine or Docker.

# Why Karmada-Mac

The official installation of `karmada` is running in docker. As is known to all, running docker on Mac is with the help of virtual machine. But vm costs too much hardware resource, it works hard for mac with low level hardware.
This repository is committed to resolving this problem.
- Abandoning vm, run karmada natively and lightly.
- Easy debug for karmada developer.


# Quick Start

## Prerequisites

Run installing kubernetes scripts needs bash version of 4.2. Check it with:
```shell
bash --version
```
If your bash is below this version, update by
```shell
brew install bash
```

## Install Karmada

Run this script to install Karmada.
```shell
make
```

When completed, Karmada is ready. You can access Karmada by

```shell
kubectl --kubeconfig ~/.karmada/karmada-apiserver.config version -o yaml
```

Or
```shell
export KUBECONFIG=~/.karmada/karmada-apiserver.config
kubectl version -o yaml
```

And a controller script is installed in `~/.karmada/ctrl.sh` by default. With it, you can start or stop karmada by:
```shell
# start karmada
~/.karmada/ctrl.sh start

# stop karmada
~/.karmada/ctrl.sh stop
```

More usage see
```shell
~/.karmada/ctrl.sh help
```

# License

Karmada-mac is under the Apache 2.0 license. See the [LICENSE](LICENSE) file for details.
