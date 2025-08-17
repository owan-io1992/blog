---
date: 2025-07-08T07:07:00
draft: false
tags:
- k8s-reading
title: "kubernetes authentication - part1"
weight: 31
---
![alt](images/banner.png)  

<!--more-->

[doc link](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)

對於 k8s cluster, 通常會讓不同人進行存取  
不管是管理者還是使用者都會需要不同的權限  
因此這章要說明權限控管部份  

在 user 方面可以先分成兩種
- service account: 由 k8s 管理, 在 k8s cluster 中管理的帳號  
- normal user account: k8s 管理者/操作者, 換言之 來自 k8s 外部的帳號  

然而 k8s 並沒有 object 來支援 normal user account  
因此要建立 normal user account 時  
必須要透過一些方法才能達成  

其中分成三種方式  
-  client certificates
-  bearer tokens
-  authenticating proxy

但在建立帳號之前, 得先說明 RBAC  

## RBAC  
Role-based access control (RBAC)  
[doc link](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

RBAC 是一種常見的權限管理辦法  
將概念拆成不同的實做對象, 再組合 藉此來做高效的管理  

這裡會用到的是 reource 是  
Role: 權限(對某 resource 的權限)  
kind: 使用者(User,Group,ServiceAccount,serviceaccounts) - 
RoleBinding: 將使用者與權限結合, 代表使用者可以擁有什麼權限  


### Role
Role 又細分為 Role and ClusterRole  

簡單來說 ClusterRole 就是不分 namespace 的 role  

role  
```bash {filename=Role.yaml}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

ClusterRole  
```bash {filename=ClusterRole.yaml}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" omitted since ClusterRoles are not namespaced
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

基本上, 設定也只差在要不要設定 namespace 的差別而已  

### RoleBinding
RoleBinding 又細分為 RoleBinding and ClusterRoleBinding  

RoleBinding 可使用 ClusterRole  


```bash {filename=RoleBinding.yaml}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
roleRef:
  # "roleRef" specifies the binding to a Role / ClusterRole
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

以上 service account 就擁有相關的權限了  


## service account

[doc link](https://kubernetes.io/docs/concepts/security/service-accounts/)  

service account 是用在 k8s cluster 內  
service account 可以掛給 pod 使用  
或是透過 ServiceAccount token 從外部存取存取

以下範例產生 "default" 這個 service account 的 token  
```bash
# --- Configuration ---
SERVICE_ACCOUNT_NAME=default
NAMESPACE=default
KUBECONFIG_FILE="kubeconfig-sa.yaml"

# --- Get Cluster Info ---
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# --- Use the --raw flag to get the CA data ---
CA_DATA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

# --- Get the Token ---
TOKEN=$(kubectl create token ${SERVICE_ACCOUNT_NAME} -n ${NAMESPACE})

# --- Generate the kubeconfig file ---
tee ${KUBECONFIG_FILE} <<EOF
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    certificate-authority-data: ${CA_DATA}
    server: ${SERVER}
users:
- name: ${SERVICE_ACCOUNT_NAME}
  user:
    token: ${TOKEN}
contexts:
- name: ${SERVICE_ACCOUNT_NAME}-context
  context:
    cluster: ${CLUSTER_NAME}
    user: ${SERVICE_ACCOUNT_NAME}
    namespace: ${NAMESPACE}
current-context: ${SERVICE_ACCOUNT_NAME}-context
EOF

echo "✅ Kubeconfig file '${KUBECONFIG_FILE}' created successfully."

# --- Test the new kubeconfig ---
echo "Testing the new kubeconfig..."
kubectl --kubeconfig=${KUBECONFIG_FILE} get pods
kubectl --kubeconfig=${KUBECONFIG_FILE} get node # should fail
```


以上就是一個簡易使用 service account 來提供 cluster 外部使用的方法  

## normal user account  

為避免篇幅過長  
此拆成 part2  