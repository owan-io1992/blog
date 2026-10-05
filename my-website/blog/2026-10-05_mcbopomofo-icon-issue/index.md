---
title: "小麥輸入法 system tray icon 無法顯示問題"
tags: []
---

<!-- truncate -->

問題描述: 當安裝完 [小麥輸入法](https://github.com/openvanilla/fcitx5-mcbopomofo)  
會發生 system tray icon 無法顯示問題  

修復方法 

```
# 1. 建立正確的符號連結覆蓋純文字檔
for size in 16x16 22x22 24x24 32x32 64x64; do
  sudo ln -sf "org.fcitx.Fcitx5.fcitx_mcbopomofo.png" "/usr/share/icons/hicolor/${size}/apps/fcitx_mcbopomofo.png"
done

# 2. 重新產生圖示快取
sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor
```

重新登入後應可解決  


可惜這問題不在每台電腦上發生  
因此 maintaner 無法複製問題, 導致此問題無法修正  
