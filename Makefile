all:
	hack/install-all.sh

install-etcd:
	hack/install-etcd.sh

install-k8s install-kubernetes:
	hack/install-k8s.sh

install-karmada:
	hack/install-etcd.sh

install-certs:
	hack/install-certs.sh

install-scripts:
	hack/install-scripts.sh

enable disable start stop restart status health uninstall help:
	hack/ctrl.sh $@

check:
	hack/check.sh
