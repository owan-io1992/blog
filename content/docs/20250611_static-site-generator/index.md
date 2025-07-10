---
date: 2025-06-11T11:19:00
draft: false
tags:
- hugo
- docusaurus
title: static site generator
---

![alt](images/banner.png)

<!--more-->


## Introduction
static site 表示這個 site 單純依靠 HTML,CSS 和 JavaScript 組成  
server 只負責存放(host) 這些內容(file)  
browser(client) 進行渲染(render)  
server 不會進行任何動態行為, 比如說存取 DB  


**靜態網站的優點：**
速度快： 因為內容是預先準備好的，伺服器可以直接傳送，載入速度通常非常快。  
安全性高： 由於沒有複雜的後端程式碼和資料庫直接暴露給用戶請求，被攻擊的風險較低。  
成本低： 靜態檔案對伺服器的資源要求不高，所以託管成本通常更便宜，甚至有很多免費的託管服務（如 GitHub Pages, Netlify, Vercel）。  
可靠性高/易於擴展： 由於結構簡單，伺服器壓力小，更容易應對大量訪問，並且可以輕鬆地使用 CDN（內容傳遞網路）來加速全球訪問。  
開發和維護相對簡單（對於某些類型的網站）： 對於內容不常變動的網站來說，開發和維護可能更直接。  
**靜態網站的缺點/限制：**
互動性有限： 如果需要複雜的用戶互動（如用戶登入、留言板、線上購物等需要後端處理的功能），純靜態網站本身無法實現，需要依賴第三方服務或 JavaScript 來模擬。  
內容更新不便（傳統方式）： 如果沒有使用現代化的工具，每次更新內容可能都需要手動修改 HTML 檔案，然後重新上傳，對於非技術人員來說比較麻煩。  

## 評估系統 hugo & Docusaurus


兩者都是使用 markdown 書寫  

### Docusaurus
https://docusaurus.io  
Docusaurus 產生網站速度較慢 (but who care)  
但上手難度較高, 建議需要基本 js/ts 能力, plugin/theme 支援較少  

支援 git 版控  比較適合 doc 類網站

### hugo
https://gohugo.io  
較單純 基本 toml/markdown knowledge 即可, theme 非常多  
較適合做網站/blog  


## conclusion
因為我比較需要 blog 形式  
hugo 的 theme 給我較快速上手的能力  
另外社群擴充功能也比較豐富  
與 wordpress 相比
hugo 的輕量化也讓效率大幅提昇  
wordpress  就是給人一種沈重的感覺  
於是採用 hugo 作為我的 static blog system

