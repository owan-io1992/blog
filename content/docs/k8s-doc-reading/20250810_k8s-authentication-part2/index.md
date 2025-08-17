---
date: 2025-07-08T09:07:00
draft: false
tags:
- k8s-reading
title: "kubernetes authentication - part2"
weight: 32
---
![alt](images/banner.png)  

<!--more-->

[doc link](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)

## normal user account  

雖然使用 service account 可以達成權限管理  
但是實務上可能會使用 LDAP or OAuth 來直接使用外部帳號  
藉此達成 Single Sign-On  

因此除了 service account 之外  
這邊再介紹幾種常見的 normal user account 管理方法   

### X509 client certificates 
default 產生的 kubeconfig 就是採用此方式  

```bash

# 為 jane 產生一個 2048 位元的 RSA 私鑰
openssl genrsa -out jane.key 2048

# 建立一個 CSR
# CN=jane 代表使用者名稱是 "jane"
# O=developers 代表她屬於 "developers" 群組
openssl req -new -key jane.key -out jane.csr -subj "/CN=jane/O=developers"

# 將 CSR 檔案內容進行 Base64 編碼
CSR_BASE64=$(cat jane.csr | base64 -w 0)

# create csr.yaml
tee csr.yaml <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane-csr
spec:
  request: ${CSR_BASE64}
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

# apply scr to k8s
kubectl apply -f csr.yaml

# check status 
kubectl get csr
## NAME       AGE   SIGNERNAME                            REQUESTOR      REQUESTEDDURATION   CONDITION
## jane-csr   6s    kubernetes.io/kube-apiserver-client   system:admin   <none>              Pending

# aprove scr
kubectl certificate approve jane-csr

# check status 
kubectl get csr
## NAME       AGE   SIGNERNAME                            REQUESTOR      REQUESTEDDURATION   CONDITION
## jane-csr   34s   kubernetes.io/kube-apiserver-client   system:admin   <none>              Approved,Issued

# download cert
kubectl get csr jane-csr -o jsonpath='{.status.certificate}' | base64 --decode > jane.crt
```

綁定 role
```bash { filename=jane_RoleBinding.yaml }
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-jane
  namespace: default
subjects:
- kind: User  # 我們是綁定到一個使用者
  name: jane  # 這就是 CSR 中 CN 的值
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

套用  
```bash
kubectl apply -f jane_RoleBinding.yaml
```

建立 kubeconfig for jane  
```bash
KUBECONFIG_FILE="kubeconfig-jane.yaml"


CURRENT_CONTEXT=$(kubectl config current-context)
# --- Get Cluster Info ---
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# --- Use the --raw flag to get the CA data ---
CA_DATA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')


# 1. 設定叢集資訊
echo "${CA_DATA}" | base64 --decode > ca.crt.tmp

# 2: 讓 kubectl 從這個臨時檔案讀取憑證
kubectl config set-cluster ${CLUSTER_NAME} \
  --server=${SERVER} \
  --certificate-authority=ca.crt.tmp \
  --embed-certs=true \
  --kubeconfig=${KUBECONFIG_FILE}

# 3. 設定使用者憑證 (私鑰和公鑰憑證)
kubectl config set-credentials jane \
  --client-key=jane.key \
  --client-certificate=jane.crt \
  --embed-certs=true \
  --kubeconfig=${KUBECONFIG_FILE}

# 4. 設定 context，將使用者和叢集綁定在一起
kubectl config set-context jane-context \
  --cluster=${CLUSTER_NAME} \
  --user=jane \
  --namespace=default \
  --kubeconfig=${KUBECONFIG_FILE}

# 5. 設定 default context
kubectl config use-context jane-context --kubeconfig=${KUBECONFIG_FILE}


echo "✅ Kubeconfig file '${KUBECONFIG_FILE}' created successfully."

# --- Test the new kubeconfig ---
echo "Testing the new kubeconfig..."
kubectl --kubeconfig=${KUBECONFIG_FILE} get pods
kubectl --kubeconfig=${KUBECONFIG_FILE} get node # should fail
```

### OpenID Connect

因為 k8s 只支援 OpenID Connect  
因此通常會使用 [dex](https://dexidp.io) 協助介接 LDAP, SAML, and OAuth2 ...etc  

#### install dex

由於是 lab 環境

```bash

```