all:
	hack/before-install.sh
	@$(MAKE) install-etcd-bin install-k8s-bin install-karmada-bin
	@$(MAKE) install-scripts install-certs install-servers install-karmada
	hack/post-install.sh

install-etcd-bin:
	hack/install-etcd-bin.sh

install-k8s-bin install-kubernetes-bin:
	hack/install-k8s-bin.sh

install-karmada-bin:
	hack/install-karmada-bin.sh

install-certs:
	hack/install-certs.sh

install-scripts:
	hack/install-scripts.sh

install-servers:
	hack/install-servers.sh

install-karmada:
	hack/install-karmada.sh

check:
	hack/check.sh
