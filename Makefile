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
    --extra-config=apiserver.service-node-port-range=1-65535 \
	--embed-certs

## Stop minikube cluster
mk.stop:
	@minikube stop

## Restart Minikube Ingress addon
mk.ing.restart: mk.ing.disable mk.ing.enable

mk.ing.disable:
	@minikube addons disable ingress

mk.ing.enable:
	@minikube addons enable ingress
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
	@kustomize build awx -o awx/awx.yaml | kubectl apply -f awx/awx.yaml

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

###### Change awx svc to LoadBalancer
patch.awx.svc.lb:
	@echo "\r\n-- Changing Service from NodePort to LoadBalancer --"
	@kubectl patch svc awx-demo-service -n awx --type='json' -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'

###### Change awx svc to NodePort
patch.awx.svc.np:
	@echo "\r\n-- Changing Service from LoadBalancer to NodePort --"
	@kubectl patch svc awx-demo-service -n awx --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'

###Helloworld App
## Deploy Helloworld Sample app to test minikube ingress access
deploy.helloworld: deploy.hw.cmd deploy.default.ingress curl.hw.svc

deploy.hw.cmd:
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/minikube/master/deploy/addons/ingress-dns/example/example.yaml

deploy.default.ingress:
	@kubectl apply -f ingress-default.yaml 
###### Change Helloword svc to LoadBalancer
patch.hw.svc.lb:
	@echo "\r\n-- Changing Service from NodePort to LoadBalancer --"
	@kubectl patch svc hello-world-app --type='json' -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'

###### Change Helloworld svc to NodePort
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

###BlueWhale App
## Deploy BlueWhale Page
deploy.bluewhale:
	@kubectl apply -f bluewhale

## Undeploy BlueWhale Page
undeploy.bluewhale:
	@kubectl delete -f bluewhale
###Utils
## deploy dnsutils (DNS / IP / NSLOOKUP) 
deploy.dnsutils:
	@kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml

## Un deploy dnsutils
undeploy.dnsutils:
	@kubectl delete -f https://k8s.io/examples/admin/dns/dnsutils.yaml

## Deploy K8s Dashboard Ingress
deploy.dash.ing:
	@kubectl apply -f k8s-dashboard.yaml
	@echo Ingress can be access here: https://k8s.dashboard.test

## Create & Install local dev certs - mkcert
certs.create:
	@mkdir -p certs
	@mkcert -install \
	-cert-file certs/mkcert.pem \
	-key-file certs/mkcert-key.pem \
	bluewhale.test "*.bluewhale.test" \
	hello-john.test hello-jane.test \
	k8s.dashboard.test "*.dashboard.test" \
	awx.test "*.awx.test" \
	hw.test "*.hw.test" \
	"*.test" \
	localhost 127.0.0.1 ::1 

certs.del.mk:
	@kubectl -n kube-system delete secret mkcert
## Add certs to Minikube Cluster
certs.add.mk: 
	@kubectl -n kube-system create secret tls mkcert --key certs/mkcert-key.pem --cert certs/mkcert.pem

## Verify certs in Cluster
certs.verify.mk:
	@kubectl -n ingress-nginx get deployment ingress-nginx-controller  -o jsonpath="{.spec.template.spec.containers}"  | jq -r '.[].args' | grep kube-system

###NGINX Ingress
## Install NGINX Ingress
nginx.install:
	@helm upgrade --install ingress-nginx ingress-nginx \
  	--repo https://kubernetes.github.io/ingress-nginx \
  	--namespace ingress-nginx --create-namespace

## Uninstall NGINX Ingress
nginx.uninstall:
	@helm uninstall ingress-nginx --namespace ingress-nginx
