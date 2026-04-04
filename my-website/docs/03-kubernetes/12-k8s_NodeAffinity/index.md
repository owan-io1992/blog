---
tags: []
---
# k8s NodeAffinity
關於 NodeAffinity 的文件 官方文件散落各地, 因此整理一篇來幫助記憶  

在講 NodeAffinity 時  
通常會認為在說 pod 用的 [nodeAffinity](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#NodeAffinity)  

在 k8s 中還存在一個 [VolumeNodeAffinity](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/#:~:text=nodeAffinity%20(-,VolumeNodeAffinity,-))  
是給 persistent volume 使用  

## api field
先看看 api field 能大概了解差異  

```bash
# VolumeNodeAffinity
.spec.nodeAffinity.required.nodeSelectorTerms.matchExpressions
.spec.nodeAffinity.required.nodeSelectorTerms.matchFields

# NodeAffinity
.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution.preference.matchExpressions
.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution.preference.matchFields

.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms.matchExpressions
.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms.matchFields 
```

由於 VolumeNodeAffinity 的 field 也是 `nodeAffinity` 因此要小心別搞錯  
另外 pod 的 nodeAffinity 後的 field 名稱非常長, 但基本只要看前面 preferred/equired 就能知道意思  
[詳細說明](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity)

這邊可以看到兩者都是使用 `matchExpressions`, `matchFields`  
下面來說明差異  

## matchExpressions/matchFields
matchFields: select object field  
matchExpressions: select object label  

範例

[matchExpressions](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#labelselectorrequirement-v1-meta)  
```yaml
- matchExpressions:
  - key: topology.kubernetes.io/zone
    operator: In
    values:
    - antarctica-east1
```

[matchFields](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#labelselectorrequirement-v1-meta)  
```yaml
- matchFields:
  - key: metadata.name
    operator: NotIn
    values:
    - worker-1
```

## matchExpressions/matchFields operator
[operator](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators) 支援以下設定  

The following are all the logical operators that you can use in the `operator` field for `nodeAffinity` and `podAffinity` mentioned above.

|    Operator    |    Behavior     |
| :------------: | :-------------: |
| `In` | The label value is present in the supplied set of strings |
|   `NotIn`   | The label value is not contained in the supplied set of strings |
| `Exists` | A label with this key exists on the object |
| `DoesNotExist` | No label with this key exists on the object |

The following operators can only be used with `nodeAffinity`.

|    Operator    |    Behavior    |
| :------------: | :-------------: |
| `Gt` | The field value will be parsed as an integer, and that integer is less than the integer that results from parsing the value of a label named by this selector |
| `Lt` | The field value will be parsed as an integer, and that integer is greater than the integer that results from parsing the value of a label named by this selector |



> `Gt` and `Lt` operators will not work with non-integer values. If the given value
doesn't parse as an integer, the Pod will fail to get scheduled. Also, `Gt` and `Lt`
are not available for `podAffinity`.


## label-selectors

另外一個同樣在 select label 的 [LabelSelector](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector)
語法又稍微不同, 大部分用在 deployment/service
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  ...
```

這裡也能使用 [matchExpressions](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#labelselectorrequirement-v1-meta)   
不過大多使用 matchLabels(map of `{key,value}`)  

