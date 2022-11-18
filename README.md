# Karmada-Mac

Run [karmada](https://github.com/karmada-io/karmada) natively on Mac, without virtual machine.

# Why Karmada-Mac

The official installation of `karmada` is running in docker. As is known to all, running docker on Mac is with the help of virtual machine. But vm costs too much hardware resource, it works hard for mac with low level hardware.
This repository is committed to resolving this problem.
- Abandoning vm, run karmada natively and lightly.
- Easy debug for karmada developer.


# Quick Start

## Prerequisites

If you cannot run a program, please see "Trouble Shooting" section first.

### Install Command Line Tools

macOS builtin command line tools' version is usually too old. In order to run the scripts correctly, you'd better install newer version via homebrew, then modify your `PATH` to make sure newly installed version will be found first.

The following list is not complete, if you encounter any problem while executing a command, try to install a newer version instead.

Depending on you macOS version, some tools may be new enough to skip. But which tools are new enough needs your own digging.

```
brew install bash
brew install make
# macOS 10.15 builtin curl command don't support tls1.3
brew install curl
```

### Manual Install Commands

- <https://github.com/cloudflare/cfssl/releases>
- [Install and Set Up kubectl on macOS](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/)


### Install binaries

Build binaries and place them into `BIN_DIR`(default is `~/bin`, can be changed in `config`)

1. Install karmada binaries
```shell
git clone https://github.com/karmada-io/karmada.git
cd karmada
make
mv _output/bin/darwin/<architecture>/* ~/bin/
```

2. Install etcd binaries

<https://etcd.io/docs/v3.5/install/#install-pre-built-binaries>

3. Install kubernetes binaries

```shell
git clone -b release-1.23 https://github.com/kubernetes/kubernetes.git
cd kubernetes
make kube-apiserver kube-controller-manager
cp _out/bin/{kube-apiserver,kube-controller-manager} ~/bin/
```

### Trouble Shooting

1) macOS Cannot Verify That This App Is Free from Malware

You may need following command to remove GateKeeper restriction of downloaded executable file. Chrome will add attributes to downloaded file, cause a certificate check when first running program. Most command line tools aren't signed, so execution will fail.

```
# You can pass a single filename or multiple filenames at once
xattr -rd com.apple.quarantine <filename> ...
```

You can also use GUI to green light an application: <https://support.apple.com/zh-cn/guide/mac-help/mchleab3a043/mac>

## Configure

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

## Install Karmada

Run this script to install Karmada.
```shell
./ctrl.sh install
```

This script will fail if some dependency is not installed, you need to install them yourself.



When completed, Karmada is ready. You can access Karmada by

```shell
kubectl --kubeconfig ~/.karmada/karmada-apiserver.config version -o yaml
```

Or
```shell
export KUBECONFIG=~/.karmada/karmada-apiserver.config
kubectl version -o yaml
```

## Usage

See the usage by
```shell
./ctrl.sh help
```

You may want to run `health_check.sh` to check if your karmada cluster is up and running. The health check logic inside installation process is pretty loose.

# License

Karmada-mac is under the Apache 2.0 license. See the [LICENSE](LICENSE) file for details.
