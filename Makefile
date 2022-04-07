#!/usr/bin/env make
include Makehelp

CPUS=4
MEMORY=6g # in g
NODES=1

###Cluster
## Start minikube cluster 
mk.start:
	@minikube start --addons=ingress,ingress-dns,dashboard,metrics-server \
	--cni=flannel \
	--install-addons=true \
    --kubernetes-version=stable \
    --vm-driver=docker --wait=false \
    --cpus=$(CPUS) --memory=$(MEMORY) --nodes=$(NODES) \
    --extra-config=apiserver.service-node-port-range=1-65535

## Stop minikube cluster
mk.stop:
	@minikube stop

## Pause minikube cluster
mk.pause:
	@minikube pause

## Unpause minikube cluster
mk.unpause:
	@minikube unpause

## Delete minikube cluster
mk.delete:
	@minikube delete

###Helloworld App
## Deploy Helloworld Sample app to test minikube access
deploy.helloworld: deploy.hw.cmd curl.hw.svc

deploy.hw.cmd:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/minikube/master/deploy/addons/ingress-dns/example/example.yaml

## Change Helloword svc to LoadBalancer
patch.hw.svc.lb:
	@echo "\r\n-- Changing Service from NodePort to LoadBalancer --"
	@kubectl patch svc hello-world-app --type='json' -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'

## Change Helloworld svc to NodePort
patch.hw.svc.np:
	@echo "\r\n-- Changing Service from LoadBalancer to NodePort --"
	@kubectl patch svc hello-world-app --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'

## Check helloworld service
curl.hw.svc:	
	@echo "\r\n-- Test svc --"
	@sleep 3
	@curl localhost

## Destroy helloworld Sample app
destroy.helloworld:
	@kubectl delete -f https://raw.githubusercontent.com/kubernetes/minikube/master/deploy/addons/ingress-dns/example/example.yaml

###Utils
## DNS / IP 
deploy.dnsutils:
	@kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml

destroy.dnsutils:
	@kubectl delete -f https://k8s.io/examples/admin/dns/dnsutils.yaml
