---
date: 2025-12-18T02:22:00  
draft: false
tags: ["k8s","CKA","CKAD"]
title: "CKA, CKAD 經驗分享"
---
因為考試會一直改版  
所以想分享一下目前的最新資訊  

## 考前準備
CKA, CKAD 是實做測驗  
不外乎就是要熟相關 command, document  
但不用死記(應該也沒什麼人能夠記的住)  
考試中能夠開 document  
因此官網務必要熟悉, 測驗中才能順利翻找資料  

學習資源
- https://github.com/sailor-sh/CK-X : 社群製作的模擬器, 但答案判斷機制有點怪, 另外平台很舊, 有待更新  
- udemy 課程: 很推薦買 不貴,內容充實,終生,又持續更新, 未來 k8s 新功能也能當學習來源
- killercoda.com: 有些情境可以看
- killer.sh: 考試會送 2 次模擬考, 難度比實際實際考試難,能過基本可以穩拿證書  
- k3s: 基本上考試中也幾乎是用 k3s 了, 自架環境練習非常好用, 不建議使用 kind 
  因為 kind 會受 docker overlap 影響, 實際使用會有出入  

## 考試環境注意事項
因為考試規則會改變  
務必閱讀官方說明  
官方說明說的非常詳細, 比如說過程可以使用哪些資源[](https://docs.linuxfoundation.org/tc-docs/certification/certification-resources-allowed#certified-kubernetes-administrator-cka-and-certified-kubernetes-application-developer-ckad)

考試中可以使用[VSCodium](https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-user-interface/examui-performance-based-exams#guidelines-and-tips-for-using-the-remote-desktop)  
因此不必擔心改 yaml 會很痛苦  

這邊補充幾點  
考試必須使用 PSI Secure Browser  
但他在 ubuntu 與 snap 會衝突 [PSI secure browser installer crashed](https://docs.linuxfoundation.org/tc-docs/certification/lf-handbook2/exam-user-interface/examui-performance-based-exams#guidelines-and-tips-for-using-the-remote-desktop)  
另外我也遇到 text 無法複製問題  
因此強烈建議避免使用 linux 考試 (這對 linux foundation 有點諷刺...)  

## QA
Q. 考試中 browser 只能開兩個分頁？  
A. 目前無此限制
