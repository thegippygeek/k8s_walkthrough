# Setting up a Kubernetes for local development/testing

## Introduction

Setting up a local Kubernetes environment locally can sometimes be a struggle, especially on accessing your workloads you want to access.

In this article I will show you the following:

- Some recommended tooling for working with Kubernetes clusters
- Create a Minikube Kubernetes Cluster
- Configure Minikube Ingress
- Setup Dnsmasq for resolving a `.test` domain for development/test purposes
- Use MKCERT for locally-trusted development certificates

## Prerequisites

All you need is Docker (or similarly compatible) container or a Virtual Machine environment. 

> I have tested this solution on a M1 mac with Colima

## Recommended Tools

### K9s

**homepage:** https://k9scli.io/

K9s is a terminal based UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your deployed applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.

K9s is available on Linux, macOS and Windows platforms.

#### K9s Install

- MacOS / Linux
```bash
 # Via brew
 brew install derailed/k9s/k9s
```

- Windows
```bash
# Via choco
choco install K9s
```

### Stern

**homepage**: https://github.com/stern/stern

Stern allows you to tail multiple pods on Kubernetes and multiple containers within the pod. Each result is color coded for quicker debugging.

The query is a regular expression so the pod name can easily be filtered and you don't need to specify the exact id (for instance omitting the deployment id). If a pod is deleted it gets removed from tail and if a new pod is added it automatically gets tailed.

When a pod contains multiple containers Stern can tail all of them too without having to do this manually for each one. Simply specify the container flag to limit what containers to show. By default all containers are listened to.

#### Stern Install

- MacOS / Linux
```bash
 # Via brew
 brew install stern
```

- Windows
```bash
# Via choco
choco install stern
```

### kubectx + kubens

**homepage**: https://github.com/ahmetb/kubectx

kubectx is a tool to switch between contexts (clusters) on kubectl faster.
kubens is a tool to switch between Kubernetes namespaces (and configure them for kubectl) easily.

```bash
#switch to another cluster that's in kubeconfig
$ kubectx minikube
Switched to context "minikube".

# switch back to previous cluster
$ kubectx -
Switched to context "oregon".

# create an alias for the context
$ kubectx dublin=gke_ahmetb_europe-west1-b_dublin
Context "dublin" set.
Aliased "gke_ahmetb_europe-west1-b_dublin" as "dublin".

# change the active namespace on kubectl
$ kubens kube-system
Context "test" set.
Active namespace is "kube-system".

# go back to the previous namespace
$ kubens -
Context "test" set.
Active namespace is "default".

```

#### Install

- MacOS / Linux
```bash
brew install kubectx
```

- Windows
```bash
choco install kubens kubectx
```




## DNSMasq

**homepage**: https://en.wikipedia.org/wiki/Dnsmasq

Dnsmasq is a lightweight, easy to configure DNS forwarder, designed to provide DNS services to a small-scale network. 

#### DNSMasq Install

- MacOS
```bash
brew install dnsmasq
```

> Look for Windows version (DNSAgent ??)

##### DNSMasq Config

Configure DNSMasq to resolve the `.test` domain to our localhost ip address of 127.0.0.1

```bash
code /opt/homebrew/etc/dnsmasq.conf
```
Added the domain "test" to resolve with 127.0.0.1
```
address=/test/127.0.0.1
```
Restart DNSMasq

```bash
sudo brew services restart dnsmasq
```

##### Configure Osx DNS resolving for `.test` domain

OS X also allows you to configure additional resolvers by creating configuration files in the `/etc/resolver/` directory. This directory probably won’t exist on your system, so your first step should be to create it:

```bash
sudo mkdir -p /etc/resolver
```

Create the domain file
```bash
sudo tee /etc/resolver/test >/dev/null <<EOF
nameserver 127.0.0.1
EOF
```

Once the file is created, OS X will automatically read it.

Make sure you haven't broken your DNS
```bash
ping -c 1 www.google.com
```
Check that the .test name work
```bash
ping -c 1 tonys.test
ping -c 1 this.is.a.test
```
You should see results that mention the IP address in your Dnsmasq configuration like this:
```bash
PING this.is.a.test (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.027 ms

--- this.is.a.test ping statistics ---
1 packets transmitted, 1 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 0.027/0.027/0.027/0.000 ms
```

### MKCERT

Using the tool `mkcert` we can create localised certs for our cluster.

#### Install 
```bash
brew install mkcert
```

##### Setup and Create Certs

```bash
mkdir -p certs
mkcert -install \
	-cert-file certs/mkcert.pem \
	-key-file certs/mkcert-key.pem \
	hello-john.test hello-jane.test \
	k8s.dashboard.test "*.dashboard.test" \
	"*.test" \
	localhost 127.0.0.1 ::1 
```

## Create Minikube Cluster

Run the command below to create a Minikube Cluster with the following:

- Addons:
  - ingress
  - ingress-dns
  - dashboard
  - metrics-server
- CPUS: 4
- Memory: 6g
- Nodes: 1

```bash
minikube start --addons=ingress,ingress-dns,dashboard,metrics-server \
	--cni=flannel \
	--install-addons=true \
    --kubernetes-version=stable \
    --vm-driver=docker --wait=false \
    --cpus=4 --memory=6g --nodes=1 \
    --extra-config=apiserver.service-node-port-range=1-65535 \
	--embed-certs
```

# Minikube Ingress

To access the pods besides running port forwards, we can utilise the minikube addon `ingress` which installs an Nginx Ingress Controller.

#### Add Certs to the cluster

```bash
kubectl -n kube-system create secret tls mkcert --key certs/mkcert-key.pem --cert certs/mkcert.pem
```

#### Configure Minikube Ingress Addon to use Custom Certs

```bash
  minikube addons configure ingress
```
at prompt enter *kube-system/mkcert*
```bash
  -- Enter custom cert (format is "namespace/secret"): kube-system/mkcert
  ✅  ingress was successfully configured
```

Stop and restart ingress addon
```bash
  minikube addons disable ingress
  minikube addons enable ingress
```

## Minikube Tunnel
Start the tunnel 
```bash
  minikube tunnel
```

## Test Ingress

### Deploy a test hello world app
```bash
@kubectl apply -f https://raw.githubusercontent.com/kubernetes/minikube/master/deploy/addons/ingress-dns/example/example.yaml
```

```bash
curl hello-john.test

Hello, world!
Version: 1.0.0
Hostname: hello-world-app-86d5b6469f-rdqrq
```

Test https and confirm that the issuer is from mkcert 
```bash
curl -v https://hello-john.test

...
*  issuer: O=mkcert development CA; OU=tonyh@Tonys-MacBook-Pro.local (Tony Hallworth); CN=mkcert tonyh@Tonys-MacBook-Pro.local (Tony Hallworth)
*  SSL certificate verify ok.
...

```

# Congratulations!!

If you have made it to here, you should now have a fully accessible Kubernetes cluster for you to test your deployments on. 

Happy Kubeing 😄 

## Learning Resources

- [Learn Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics) | https://kubernetes.io/docs/tutorials/kubernetes-basics
- [Tail K8s with Stern](https://kubernetes.io/blog/2016/10/tail-kubernetes-with-stern/) | https://kubernetes.io/blog/2016/10/tail-kubernetes-with-stern
- [DNS Masking](https://passingcuriosity.com/2013/dnsmasq-dev-osx/) | https://passingcuriosity.com/2013/dnsmasq-dev-osx/
- [Minikube Certs for Ingress](https://minikube.sigs.k8s.io/docs/tutorials/custom_cert_ingress/) | https://minikube.sigs.k8s.io/docs/tutorials/custom_cert_ingress/
- [mkcert (Create local certs for dev)](https://github.com/FiloSottile/mkcert) | https://github.com/FiloSottile/mkcert