---
title: antigravity IDE 啟動失敗
tags: [chrome-sandbox, sandbox]
---

![banner](banner.png)
<!-- truncate -->


在新版的 antigravity IDE 中  
使用了 sandbox 技術  
但在 linux 會因為權限問題導致無法啟動  
```
❯ ./antigravity-ide
[13150:0615/091950.905610:FATAL:sandbox/linux/suid/client/setuid_sandbox_host.cc:166] The SUID sandbox helper binary was found, but is not configured correctly. Rather than run without sandboxing I'm aborting now. You need to make sure that /home/owan/data/Antigravity-IDE/chrome-sandbox is owned by root and has mode 4755.
Trace/breakpoint trap
[13153:0100/000000.919329:ERROR:content/zygote/zygote_linux.cc:672] write: Broken pipe (32)
```

原因是 linux 對 sandbox 有強制要求權限  
解決方法  
```
# 1. 將擁有者更改為 root（需要輸入你的 sudo 密碼）
sudo chown root:root chrome-sandbox

# 2. 設定正確的 SUID 權限 (4755)
sudo chmod 4755 chrome-sandbox
```

**4**755 是少見的權限  
> 4 代表 SUID (Set User ID)：當一個二進位檔案被設定了 SUID，不論是哪位使用者執行這個檔案，該程式在執行期間都會暫時取得該檔案「擁有者（Owner）」的權限。  
