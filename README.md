# Tony's quick K8s walkthrough

This is a quick general guide and tools I find useful for managing K8s Clusters. These tools are generic and should work on any type of K8s cluster; be it AKS, EKS or GKE.

- [Tony's quick K8s walkthrough](#tonys-quick-k8s-walkthrough)
  - [Recommended Tools](#recommended-tools)
    - [Minikube](#minikube)
    - [K9s](#k9s)
    - [Stern](#stern)
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


## Learning Resources

- [Learn Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics) | https://kubernetes.io/docs/tutorials/kubernetes-basics
- [Tail K8s with Stern](https://kubernetes.io/blog/2016/10/tail-kubernetes-with-stern/) | https://kubernetes.io/blog/2016/10/tail-kubernetes-with-stern
- [LearnCMD Kubernetes 101](https://gitlab.mantelgroup.com.au/cmd/training/kubernetes_101) | https://gitlab.mantelgroup.com.au/cmd/training/kubernetes_101
- [DNS Masking](https://passingcuriosity.com/2013/dnsmasq-dev-osx/) | https://passingcuriosity.com/2013/dnsmasq-dev-osx/
- [Minikube Certs for Ingress](https://minikube.sigs.k8s.io/docs/tutorials/custom_cert_ingress/) | https://minikube.sigs.k8s.io/docs/tutorials/custom_cert_ingress/
- [mkcert (Create local certs for dev)](https://github.com/FiloSottile/mkcert) | https://github.com/FiloSottile/mkcert