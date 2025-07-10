---
date: 2025-06-23T06:17:00
draft: false
tags:
- k8s-reading
title: "k8s doc reading: Concepts - Workload Management - statefulsets"
---
![alt](images/banner.jpeg)  

<!--more-->
[doc link](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)   

如果在前面的 deployment 應該會發現  
pod name 會有一串 random id  
statefulset 則是會讓 pod 有固定名稱(固定的 hostname)  
pod 所 mount volume 也會是跟著固定的  

statefulset 適用在以下需求  
- Stable, unique network identifiers.  
- Stable, persistent storage.  
- Ordered, graceful deployment and scaling.  
- Ordered, automated rolling updates.  


### Limitations 

- volume 一定要使用 PersistentVolume Provisioner 去建立 volume, 或者 pre-provisioned volume  
- 刪除 or scaleing in 不會刪除 volume, 藉此確保 volume safety  
- statefule 如果需要 Headless Service(之後再說明), 你需要自己建立  
- k8s 不負責 gracelful shutdown,  因此在 stop workloading 應該要自己注意步驟  


### manifest sample

```bash
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx # has to match .spec.template.metadata.labels
  serviceName: "nginx"
  replicas: 3 # by default is 1
  minReadySeconds: 10 # by default is 0
  template:
    metadata:
      labels:
        app: nginx # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.24
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "my-storage-class"
      resources:
        requests:
          storage: 1Gi

```

以下是這些新參數的解釋：


[`minReadySeconds`](https://kubernetes.io/blog/2021/08/27/minreadyseconds-statefulsets/)   
是一個 Pod 規格中的欄位，定義了 Pod 在被標記為「可用 (available)」之前，必須保持「就緒 (ready)」狀態的最小秒數。
*   **目的**：這對於確保新啟動的 Pod 在接收流量之前，有足夠的時間進行初始化和預熱非常有用。例如，一個應用程式可能需要幾秒鐘來載入配置、建立資料庫連線或執行初始設定，即使其容器已經啟動並通過了就緒探針 (readiness probe)。


`terminationGracePeriodSeconds`  
定義了 Pod 在被強制終止之前，給予 graceful shutdown的時間
*   **目的**：當 Pod 被刪除或需要重新排程時（例如，由於節點故障或資源重新分配），Kubernetes 會先向 Pod 中的容器發送 `SIGTERM` 訊號。這個訊號通知應用程式它即將被終止，應用程式應該開始清理工作，例如關閉現有連線、保存狀態或完成正在進行的請求。
*   **流程**：
    1.  Kubernetes 向 Pod 發送 `SIGTERM`。
    2.  Pod 中的應用程式有 `terminationGracePeriodSeconds` 所定義的時間來執行清理。
    3.  如果在寬限期結束時應用程式仍未終止，Kubernetes 會發送 `SIGKILL` 訊號，強制終止所有剩餘的程序。
*   **重要性**：對於有狀態應用程式尤其重要，因為它確保應用程式在關閉前能妥善處理資料和狀態，避免資料損壞或遺失。

[`volumeClaimTemplates`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#statefulsetspec-v1-apps) 是 StatefulSet 特有的功能，用於為 StatefulSet 中的每個 Pod 自動創建一個 [`PersistentVolumeClaim (PVC)`](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims), PVC 之後會再說明 。  
*   **目的**：StatefulSet 中的每個 Pod 都需要一個獨立且穩定的儲存空間。`volumeClaimTemplates` 允許您定義一個 PVC 的模板，StatefulSet 控制器會根據這個模板為每個副本 Pod 自動創建一個 PVC。
*   **特性**：
    *   **穩定性**：每個 Pod 都有其專屬的 PVC，即使 Pod 被重新排程或刪除，其對應的 PVC 和底層的 PersistentVolume (PV) 仍然存在，確保資料的持久性(can change)。
    *   **命名約定**：創建的 PVC 會遵循特定的命名約定（例如 `$(claimName)-$(podName)`），這使得管理和識別每個 Pod 的儲存變得容易。
    *   **自動創建與刪除**：當 StatefulSet 擴展時，新的 PVC 會自動創建；當 Pod 被縮減時，對應的 PVC 不會自動刪除，這需要手動清理以防止資料意外丟失。


[`volumeMounts`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#container-v1-core) 是容器規格中的一個欄位，用於將 Pod 中定義的 [`Volume`](https://kubernetes.io/docs/concepts/storage/volumes/) 掛載到容器的指定路徑。
*   **目的**：它定義了容器內部檔案系統中，Volume 應該被掛載的位置。這使得容器內的應用程式可以讀取或寫入該 Volume 中的資料。
*   **與 volumeClaimTemplates 的關係**：當使用 `volumeClaimTemplates` 時，每個 Pod 會自動獲得一個 PVC。這個 PVC 會綁定到一個 PV，而這個 PV 最終會作為一個 Volume 被掛載到 Pod 中。`volumeMounts` 則指定了這個 Volume 在容器內部可訪問的路徑。
*   **重要屬性**：
    *   `name`：必須與 Pod 中定義的 Volume 名稱匹配。
    *   `mountPath`：Volume 在容器內部被掛載的路徑。

定外 statefulset 不會建立 ReplicaSet  
pod replica 是由 statefulset 直接管理  

### Deployment and Scaling Guarantees 

create pod 時 pod id 一定是按造順序 {0..N-1}  
rolling restart 時 一定是按造順序 {0..N-1}  
scale-in 時 pod id 一定是按造順序 {N-1..0}
> 如有需要可以設定 `.spec.ordinals.start` 來改變起始 id 

再做任何 scaling operation 時, 必須先等全部為 Running and Ready 才能開始動作

---

剩下大部分設定都與 deployment 相同  
因此兩者使用上只要根據需求選擇  
學習上應該不太困難  