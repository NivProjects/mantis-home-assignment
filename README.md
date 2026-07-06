<b>Mantis home assignment</b>

1.
short explantion about design:
Modular Architecture: I structured the Terraform code using modules to promote code reusability and maintainability. Breaking down the infrastructure into logical units as it is the best practice to ensure that the configuration remains clean as the project grows. Deployed the EC2 within a private network (VPC/Subnet) with NAT gateway for maximum security and demonstration of real organizition that using private network.

terraform apply output will be attach in additional-deliverables file


2.
k8s initialize in the EC2:
Sudo su -
dnf install -y containerd 

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

Vim /etc/yum.repos.d/kubernetes.repo 
Insert into the file:
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key

dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes 
systemctl enable --now kubelet

dnf install -y iproute-tc
echo 1 > /proc/sys/net/ipv4/ip_forward
Vim /etc/sysctl.d/k8s.conf 
Into the file:
net.bridge.bridge-nf-call-iptables = 1 
net.bridge.bridge-nf-call-ip6tables = 1
 net.ipv4.ip_forward 

kubeadm init --pod-network-cidr=192.168.0.0/16

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 chmod 700 get_helm.sh ./get_helm.sh 

helm repo add projectcalico https://docs.tigera.io/calico/charts
helm repo update

kubectl create namespace tigera-operator

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
helm install calico projectcalico/tigera-operator --namespace tigera-operator

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/cust
om-resources.yaml

--------------------------------------------------------------------------------------------
Since this is a single-node cluster, the control plane also serves as the worker node. By default, Kubernetes prevents regular pods from being scheduled on the control plane by applying a taint.
To allow the pods to run on the only node in the cluster, I completely removed this taint using the following command:
kubectl taint nodes --all node-role.kubernetes.io/control-plane-


<img width="665" height="85" alt="getnodes" src="https://github.com/user-attachments/assets/3f110da2-a995-4766-98d1-2db16cfa48b4" />

<img width="512" height="139" alt="calico run" src="https://github.com/user-attachments/assets/67797b44-036d-4944-ba6e-325e145abe22" />




<br/>

3.
<img width="512" height="37" alt="networkcheck" src="https://github.com/user-attachments/assets/825188ff-96ee-4fbf-8b2e-09297efd34d1" />

yaml files:

App1-deploy:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1-deployment
  namespace: app1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      serviceAccountName: app1-sa
      containers:
      - name: nginx
        image: nginx:alpine
        command: ["/bin/sh", "-c"]
        args:
        - echo "Hello from App 1" > /usr/share/nginx/html/index.html && nginx -g "daemon off;"
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
  namespace: app1
spec:
  selector:
    app: app1
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

---
App2-deploy:
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2-deployment
  namespace: app2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      serviceAccountName: app2-sa
      containers:
      - name: nginx
        image: nginx:alpine
        command: ["/bin/sh", "-c"]
        args:
        - echo "Hello from App 2" > /usr/share/nginx/html/index.html && nginx -g "daemon off;"
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
  namespace: app2
spec:
  selector:
    app: app2
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80

---
App1-policy:
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace-only
  namespace: app1
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
---
App2-policy:
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace-only
  namespace: app2
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
---
App1-sa:
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app1-sa
  namespace: app1
---
App2-sa:
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app2-sa
  namespace: app2
```
