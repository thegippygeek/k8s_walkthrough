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

###AWX
## deploy AWX Operator to cluster
awx.deploy.operator:
	@kustomize build awx | kubectl apply -f -

## get awx pods
awx.get.pods:
	@kubectl get pods -l "app.kubernetes.io/managed-by=awx-operator" -n awx

## get awx pod name
awxPodName=$(shell kubectl -n awx get po -l app.kubernetes.io/component=awx -o jsonpath="{.items..metadata.name}")

.PHONY: awx.get.pod.name
awx.get.pod.name: 
	@eval $$(minikube docker-env)
	@echo 'podName=$(awxPodName)'
	kubectl get po $(awxPodName) 
	

## awx portforward on port 8052	
awx.port-forward: 
	@kubectl port-forward $(awxPodName) 8052:8052 -n awx

## get logs from awx-manager
awx.get.logs.manager:
	@stern -n awx -l control-plane=controller-manager -c awx-manager

## get AWX admin password
awx.get.admin.pass:
	@kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode

## Change awx svc to LoadBalancer
patch.awx.svc.lb:
	@echo "\r\n-- Changing Service from NodePort to LoadBalancer --"
	@kubectl patch svc awx-demo-service -n awx --type='json' -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'

## Change awx svc to NodePort
patch.awx.svc.np:
	@echo "\r\n-- Changing Service from LoadBalancer to NodePort --"
	@kubectl patch svc awx-demo-service -n awx --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'

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
undeploy.helloworld:
	@kubectl delete -f https://raw.githubusercontent.com/kubernetes/minikube/master/deploy/addons/ingress-dns/example/example.yaml

###Utils
## deploy dnsutils (DNS / IP / NSLOOKUP) 
deploy.dnsutils:
	@kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml

## Un deploy dnsutils
undeploy.dnsutils:
	@kubectl delete -f https://k8s.io/examples/admin/dns/dnsutils.yaml

###NGINX Ingress
## Install NGINX Ingress
nginx.install:
	@helm upgrade --install ingress-nginx ingress-nginx \
  	--repo https://kubernetes.github.io/ingress-nginx \
  	--namespace ingress-nginx --create-namespace

## Uninstall NGINX Ingress
nginx.uninstall:
	@helm uninstall ingress-nginx --namespace ingress-nginx

###MetalLB
## Update ARP for Metallb 
# see what changes would be made, returns nonzero returncode if different
metallb.updateARP:
	@kubectl get configmap kube-proxy -n kube-system -o yaml | \
	sed -e "s/strictARP: false/strictARP: true/" | \
	kubectl diff -f - -n kube-system
# actually apply the changes, returns nonzero returncode on errors only
	@kubectl get configmap kube-proxy -n kube-system -o yaml | \
	sed -e "s/strictARP: false/strictARP: true/" | \
	kubectl apply -f - -n kube-system
