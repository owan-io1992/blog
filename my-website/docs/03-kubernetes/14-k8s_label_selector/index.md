---
tags: []
---
# k8s label selector cheatsheet
k8s 的 label 是關聯 object 之間重要的設定
但在不同地方語法卻會稍微不同 有點惱人  
因此整理這篇做紀錄

selector 有兩種
- matchLabels
- matchExpressions

## matchLabels 
較簡單, 就是 key/value  

```yaml
matchLabels:
  <key>: <value>
```

## matchExpressions  
帶有 operator 能夠做出更彈性的設定  
多個 Expression 為 and 的關係  

```yaml
matchExpressions:
  - key: ""
    operator: <In|NotIn|Exists|DoesNotExist|Gt|Lt>
    values:
      - ""
```

**Operators**

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

> [!NOTE]
> `Gt` and `Lt` operators will not work with non-integer values. If the given value
> doesn't parse as an integer, the Pod will fail to get scheduled. Also, `Gt` and `Lt`
> are not available for `podAffinity`.


## 適用範圍
這就是比較煩的了  
不同的 kind 在使用 LabelSelector 可能會使用不同名稱 + 支援不同的 LabelSelector  
語法也會不同, 請多利用 `kubectl explan` 做查詢   

| kind  | field  | support LabelSelector  | 
|---|---|---|
| Deployment  | selector  | matchLabels/matchExpressions  | 
| StatefulSet  | selector  | matchLabels/matchExpressions  |  
| Service  | selector  |  matchLabels | 
| NetworkPolicy  | podSelector  | matchLabels/matchExpressions  | 
| PersistentVolume  | nodeAffinity  | matchExpressions  | 
| PersistentVolumeClaim  | selector  | matchLabels/matchExpressions  | 

## Taints and Tolerations
雖不是 label 
但設定概念相近

說明可見 [taint-and-toleration](/docs/k8s-doc-reading/k8s-doc-reading-taint-and-toleration/)

```yaml
# in pod.spec
tolerations:
  - key: ""
    operator: "<Equal|Exists>"
    value: ""
    effect: "<NoExecute|NoSchedule|PreferNoSchedule>"
```

|    effect    |    Behavior    |
| :------------: | :-------------: |
| `NoExecute` | evict pod and no schedule |
| `NoSchedule` | no schedule |
| `PreferNoSchedule` | soft no schedule |

