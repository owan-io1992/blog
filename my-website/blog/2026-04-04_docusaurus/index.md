---
title: 從 hugo 搬家到 docusaurus
tags: [docusaurus,hugo]
---

![](image.png)

<!-- truncate -->
紀錄一下從 hugo 搬家到 docusaurus 的原因  

之前覺得 hugo 速度很快, docusaurus 則慢又有點小複雜  
因此採用 hugo 作為我的 static site generater  
但隨著越用越多功能, 開始體感到 hugo 麻煩的地方  
hugo 本身依靠 layouts 來設定如何實際 rander html  
通常來說就是安裝 theme  
但問題會變成 theme 決定了你的網站可以用哪些功能  
造就了功能會摻疵不齊, 用法各異  
變成了後續維護上的麻煩  
雖然剛開始看到不同 theme 覺得很棒  
可實際用後發現真正算的上能用的就那幾個  
然後好死不死想要的功能沒有一個 theme 完全支援  
只能忍痛退讓  

經過一陣時間掙扎  
想想都寫 markdown 了 > 原本就是不想花時間在文書排版上  
hugo 的 theme 變成又花時間在網站排版 > 變得本末導致了  

所以又嘗試再看看 docusaurus  

docusaurus 就沒什麼 UI 的選擇  
雖然會覺得沒有個人特色, 但可以讓人更專心在內容上, 不過也許就是懶而已😆  

docusaurus 實際切換後發現的優點  
- link check: 會幫忙檢查是否有失連狀況, 意外挺加分  
- mermaid: 支援良好 [Registering icon pack](https://www.simonpainter.com/mermaid-icons/) 也能支援  

讓我感到不舒服的是 build 速度實在太慢了  
寫作時感到非常煩躁  
還好官方有提供 [Docusaurus Faster](https://github.com/facebook/docusaurus/issues/10556)  
雖然還是 experimental 功能, 但實測沒有什麼問題  
速度是快很多, 雖然還是比 hugo 稍慢,但已經是可以接受的地步  

:::tip
整體來說 切換到 docusaurus 個人是覺得值得的  
