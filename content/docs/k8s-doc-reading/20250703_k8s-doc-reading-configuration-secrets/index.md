---
date: 2025-07-03T07:30:00
draft: false
tags:
- k8s-reading
title: "Concepts - configuration - secret"
weight: 23
---
![alt](images/banner.png)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/configuration/secret/)   

secret 跟 configmap 很像  
同樣儲存在 etcd 中, 使用方法與 configmap 無異  
不過偏好用於儲存敏感資訊(sensitive data)  

不過要注意 secret 沒有加密, 沒有保護機制  
除了內容會先被 base64 encode 外 *[stringData 可不被 encode](https://kubernetes.io/docs/concepts/configuration/secret/#restriction-names-data)  
configmap 跟 secret 基本沒有太多差異  
這也是不少人覺得奇怪的點  

## Types of Secret 
 
secret 與 configmap 不同之處  

他提供 type 的設定, 讓內容有其固定格式  
我這邊先列常用的  

- Opaque: 與 configmap 相同 key-value 形式  
- kubernetes.io/dockerconfigjson: serialized ~/.docker/config.json file, 基本用於存放與 private registry 連線的 auth token  
  可以用在 `imagePullSecrets` 設定  
- kubernetes.io/tls: 放 tls 憑證, 通常供 ingress 存取  

剩下的可以參考 [secret-types](https://kubernetes.io/docs/concepts/configuration/secret/#secret-types)  

## example config

```bash
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: registry.k8s.io/busybox:1.27.2
      command: [ "/bin/sh", "-c", "ls /etc/config/" ]
      volumeMounts:
      - name: secret-volume
        mountPath: /etc/config
      envFrom:
      - secretRef:
          name: secret-demo

  volumes:
    - name: secret-volume
      secret:
        secretName: secret-demo
```

使用上不外乎就是將 configmap 改為 secret  
very easy  

## using external Secret store providers

k8s 提供一個 Secrets Store CSI driver  
可以使用外部的地方儲存 secret  
可以使用的方案  
https://secrets-store-csi-driver.sigs.k8s.io/concepts.html#provider-for-the-secrets-store-csi-driver

在 on-premise 環境  通常使用 vault-csi-provider  

不過由於牽扯的東西較多  
之後再額外介紹  