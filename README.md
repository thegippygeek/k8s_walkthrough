# Tony's quick K8s walkthrough

This is a quick general guide and tools I find useful for managing K8s Clusters. These tools are generic and should work on any type of K8s cluster; be it AKS, EKS or GKE.

- [Tony's quick K8s walkthrough](#tonys-quick-k8s-walkthrough)
  - [Recommended Tools](#recommended-tools)
    - [Minikube](#minikube)
    - [K9s](#k9s)
    - [Stern](#stern)
  - [Create Minikube Cluster](#create-minikube-cluster)
  - [Deploy test workloads](#deploy-test-workloads)
    - [Deploy hello-world](#deploy-hello-world)
    - [Deploy BlueWhale](#deploy-bluewhale)
  - [Minikube Ingress](#minikube-ingress)
    - [DNSMasq](#dnsmasq)
      - [Install](#install)
      - [Update Config](#update-config)
      - [Restart Dnsmasq service](#restart-dnsmasq-service)
      - [Test dnsmasq resolve](#test-dnsmasq-resolve)
      - [Configure Osx DNS resolving for `.test` domain](#configure-osx-dns-resolving-for-test-domain)
        - [Testing](#testing)
    - [MKCERT](#mkcert)
      - [Install](#install-1)
      - [Setup and Create Certs](#setup-and-create-certs)
      - [Add Certs to the cluster](#add-certs-to-the-cluster)
      - [Configure Minikube Ingress Addon to use Custom Certs](#configure-minikube-ingress-addon-to-use-custom-certs)
  - [Minikube Tunnel](#minikube-tunnel)
  - [Test Ingress](#test-ingress)
  - [Learning Resources](#learning-resources)

## Recommended Tools

### Minikube
**homepage:** https://minikube.sigs.k8s.io/docs/

Minikube quickly sets up a local Kubernetes cluster on macOS, Linux, and Windows. We proudly focus on helping application developers and new Kubernetes users.

**How to Install**

```bash
brew install minikube
```
>For more install options go to [here](https://minikube.sigs.k8s.io/docs/start/)

### K9s 

**homepage:** https://k9scli.io/

K9s is a terminal based UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your deployed applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.

K9s is available on Linux, macOS and Windows platforms.

**How to Install**

Binaries for Linux, Windows and Mac are available as tarballs in the release page.

- MacOS

```bash
 # Via Homebrew
 brew install derailed/k9s/k9s
 # Via MacPort
 sudo port install k9s
```
- Linux

```bash
 # Via LinuxBrew
 brew install derailed/k9s/k9s
 # Via PacMan
 pacman -S k9s
```

- Windows

```bash
# Via scoop
scoop install k9s
# Via chocolatey
choco install k9s
```

### Stern

**homepage**: https://github.com/stern/stern

Stern allows you to tail multiple pods on Kubernetes and multiple containers within the pod. Each result is color coded for quicker debugging.

The query is a regular expression so the pod name can easily be filtered and you don't need to specify the exact id (for instance omitting the deployment id). If a pod is deleted it gets removed from tail and if a new pod is added it automatically gets tailed.

When a pod contains multiple containers Stern can tail all of them too without having to do this manually for each one. Simply specify the container flag to limit what containers to show. By default all containers are listened to.

**How to Install**

**- asdf (Linux/macOS)**

If you use asdf, you can install like this:
```bash
asdf plugin-add stern
asdf install stern latest
```
**- Homebrew (Linux/macOS)**
If you use Homebrew, you can install like this:

```bash
brew install stern
```

**- Krew (Linux/macOS/Windows)**
If you use Krew which is the package manager for kubectl plugins, you can install like this:

```bash
kubectl krew install stern
```

## Create Minikube Cluster
Create the minikube cluster

```bash
make mk.start
```
This will create a minikube cluster with the following command with the following vars configured in the Makefile

```bash
CPUS=4
MEMORY=6g # in g
NODES=1
...
```

```bash
minikube start --addons=ingress,ingress-dns,dashboard,metrics-server \
	--cni=flannel \
	--install-addons=true \
    --kubernetes-version=stable \
    --vm-driver=docker --wait=false \
    --cpus=$(CPUS) --memory=$(MEMORY) --nodes=$(NODES) \
    --extra-config=apiserver.service-node-port-range=1-65535 \
	--embed-certs
```

## Deploy test workloads
There are two apps configured and ready for deployment **BlueWhale** and a **hello-world**

### Deploy hello-world
```bash
make deploy.helloworld
```

### Deploy BlueWhale
```bash
make deploy.bluewhale
```

## Minikube Ingress
To access the pods besides running port forwards, we can utilise the minikube addon `ingress`

The following steps need to be done.

1. Setup [`dnsmasq`](https://passingcuriosity.com/2013/dnsmasq-dev-osx/) for test domain resolution
2. Create local test certs with [`mkcert`](https://github.com/FiloSottile/mkcert) 
3. run `minikube tunnel` 


### DNSMasq

#### Install
```bash
brew install dnsmasq
```
#### Update Config
```bash
code /opt/homebrew/etc/dnsmasq.conf
```
Added the domain "test" to resolve with 127.0.0.1
```
address=/test/127.0.0.1
```
#### Restart Dnsmasq service
```bash
sudo brew services restart dnsmasq
```
#### Test dnsmasq resolve
```bash
dig testing.testing.one.two.three.dev @127.0.0.1
```

#### Configure Osx DNS resolving for `.test` domain

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
##### Testing
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

#### Setup and Create Certs

```bash
mkdir -p certs
mkcert -install \
	-cert-file certs/mkcert.pem \
	-key-file certs/mkcert-key.pem \
	bluewhale.test "*.bluewhale.test" \
	hello-john.test hello-jane.test \
	k8s.dashboard.test "*.dashboard.test" \
	awx.test "*.awx.test" \
	hw.test "*.hw.test" \
	"*.test" \
	localhost 127.0.0.1 ::1 
```
alternatively run the following make commands
```bash
 make certs.create
 ```

#### Add Certs to the cluster

```bash
kubectl -n kube-system create secret tls mkcert --key certs/mkcert-key.pem --cert certs/mkcert.pem
```
alternatively 
```bash
make certs.add.mk
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

```bash
curl localhost

Hello, world!
Version: 1.0.0
Hostname: hello-world-app-86d5b6469f-rdqrq
```

test https and confirm that the issuer is from mkcert 
```bash
curl -v https://localhost

...
*  issuer: O=mkcert development CA; OU=tonyh@Tonys-MacBook-Pro.local (Tony Hallworth); CN=mkcert tonyh@Tonys-MacBook-Pro.local (Tony Hallworth)
*  SSL certificate verify ok.
...

```

## Learning Resources

- [Learn Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics) | https://kubernetes.io/docs/tutorials/kubernetes-basics
- [Tail K8s with Stern](https://kubernetes.io/blog/2016/10/tail-kubernetes-with-stern/) | https://kubernetes.io/blog/2016/10/tail-kubernetes-with-stern
- [LearnCMD Kubernetes 101](https://gitlab.mantelgroup.com.au/cmd/training/kubernetes_101) | https://gitlab.mantelgroup.com.au/cmd/training/kubernetes_101
- [DNS Masking](https://passingcuriosity.com/2013/dnsmasq-dev-osx/) | https://passingcuriosity.com/2013/dnsmasq-dev-osx/
- [Minikube Certs for Ingress](https://minikube.sigs.k8s.io/docs/tutorials/custom_cert_ingress/) | https://minikube.sigs.k8s.io/docs/tutorials/custom_cert_ingress/
- [mkcert (Create local certs for dev)](https://github.com/FiloSottile/mkcert) | https://github.com/FiloSottile/mkcert