# Karmada-Mac

Run [karmada](https://github.com/karmada-io/karmada) natively on Mac, without virtual machine.

## Why Karmada-Mac

The official installation of `karmada` is running in docker. As is known to all, running docker on Mac is with the help of virtual machine. But vm costs too much hardware resource, it works hard for mac with low level hardware.
This repository is committed to resolving this problem.
- Abandoning vm, run karmada natively and lightly.
- Easy debug for karmada developer.


## Quick Start

### Prerequisites

##### Install binaries

Build binaries and place them into `BIN_DIR`(default is `~/bin`, can be changed in `config`)

1. Install karmada binaries
```shell
git clone https://github.com/karmada-io/karmada.git
cd karmada
make
cp _output/bin/$(uname -s)/$(uname -m)/* ~/bin/
```

2. Install etcd binaries

```shell
git clone https://github.com/etcd-io/etcd.git
cd etcd
make
cp bin/etcd ~/bin/
```

3. Install kubernetes binaries

```shell
git clone -b release-1.23 https://github.com/kubernetes/kubernetes.git
cd kubernetes
make kube-apiserver kube-controller-manager
cp _out/bin/{kube-apiserver,kube-controller-manager} ~/bin/
```

### Configure

1. Clone this repository, and change to the directory:
```shell
git clone https://github.com/ikaven1024/karmada-mac.git
cd karmada-mac
```

2. [Optional] Copy the `default.config`, and edit it:
```shell
cp default.config config
vi config
# TO EDIT YOUR CONFIG
```

> Both the `default.config` and `config` will be loaded, and later will override the values in the former.

### Install Karmada

Run this script to install Karmada.
```shell
./run.sh install
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

### Usage

See the usage by
```shell
./run.sh help
```

## License

Karmada-mac is under the Apache 2.0 license. See the [LICENSE](LICENSE) file for details.
