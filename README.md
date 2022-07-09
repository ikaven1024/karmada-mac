# Karmada-Mac

Run [karmada](https://github.com/karmada-io/karmada) natively on Mac, without virtual machine.

## Why Karmada-Mac

The official installation of `karmada` is running in docker. As is known to all, running docker on Mac is with the help of virtual machine. But vm costs too much hardware resource, it works hard for mac with low level hardware.
This repository is committed to resolving this problem.
- Abandoning vm, run karmada natively and lightly.
- Easy debug for karmada developer.


## Quick Start

### Prerequisites

##### Install karmada binaries

```shell
git clone https://github.com/karmada-io/karmada.git
cd karmada
make
cp _output/bin/$(uname -s)/$(uname -m)/* ~/bin/
cd ..
```

##### Install etcd binaries

```shell
git clone https://github.com/etcd-io/etcd.git
cd etcd
make
cp bin/{kube-apiserver,kube-controller-manager} ~/bin/
cd ..
```

##### Install kubernetes binaries

```shell
git clone -b release-1.23 https://github.com/kubernetes/kubernetes.git
cd kubernetes
make kube-apiserver kube-controller-manager
cp _out/bin/{kube-apiserver,kube-controller-manager} ~/bin/
cd ..
```

#### Clone this repository

```shell
git clone https://github.com/ikaven1024/karmada-mac.git
```

### Install karmada

Run this script to install Karmada.
```shell
cd karmada-mac
./run.sh install
```

When above is completed, Karmada is ready. You can access Karmada by
```shell
kubectl --kubeconfig ~/.karmada/karmada-apiserver.config version -o yaml
```

### Usage

All the commands of `run.sh`:
- install: install config files, and start karmada.
- uninstall: stop karmada, and remove config files, and clean data.
- start: run the karmada.
- stop: stop the karmada.
- status: show the status of processes.
- help: print the usage of this script.


## License

Karmada-mac is under the Apache 2.0 license. See the [LICENSE](LICENSE) file for details.
