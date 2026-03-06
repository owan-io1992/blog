---
date: 2026-03-06T00:00:00
draft: false
tags:
- linux
title: "ASUS ExpertBook P5405 喇叭無聲修復紀錄"
image: "cover.png"
---
<!--more-->



 【技術總結：ASUS ExpertBook P5405 喇叭無聲修復紀錄】


  1. 問題現象 (Symptoms)
   * 系統環境： Linux (Tuxedo OS / Ubuntu 24.04 系), Kernel 6.17+。
   * 硬體規格： Intel Lunar Lake 平台, Realtek ALC294 Codec, Cirrus Logic CS35L41 (CSC3551) 喇叭放大器。
   * 錯誤日誌：
       * cs35l41-hda ... Enable(1) failed: -110 (晶片啟動逾時)。
       * Falling back to default firmware (找不到硬體專用韌體)。
       * Cannot Initialize Firmware. Error: -2 (找不到韌體檔案或格式錯誤)。


  2. 核心原因 (Root Causes)
   1. 型號 ID 不匹配： 筆電的子系統 ID 為 10431f63，但系統內建韌體庫僅包含 10431f62 的檔案。
   2. 韌體壓縮問題： 部分核心驅動程式在初始化 CS35L41 放大器時，無法正確解壓 .zst 格式的韌體，導致載入失敗。
   3. 音效拓撲識別： 核心預設未將此型號識別為華碩專用的音效配置，導致喇叭放大器未被正確供電。
   4. 硬體狀態鎖定： 放大器晶片在多次載入失敗後會進入保護模式，需透過完全斷電（Cold Boot）重置。

  ---

  3. 完整解決方案 (The Solution)

  ##### 第一步：處理韌體檔案 (解壓與匹配 ID)
  必須讓系統找到未經壓縮、且符合 1f63 編號的韌體檔案。


    1 # 1. 進入韌體目錄
    2 cd /lib/firmware/cirrus/
    3
    4 # 2. 解壓縮所有 .zst 檔案 (確保核心能讀取原始格式)
    5 sudo zstd -d --rm *.zst 2>/dev/null
    6
    7 # 3. 建立 1f63 的連結 (指向 1f62 的原始檔案)
    8 sudo ln -sf cs35l41-dsp1-spk-cali-10431f62.wmfw cs35l41-dsp1-spk-cali-10431f63.wmfw
    9 sudo ln -sf cs35l41-dsp1-spk-prot-10431f62.wmfw cs35l41-dsp1-spk-prot-10431f63.wmfw
   10 sudo ln -sf cs35l41-dsp1-spk-cali-10431f62-spkid0-l0.bin cs35l41-dsp1-spk-cali-10431f63-spkid0-l0.bin
   11 sudo ln -sf cs35l41-dsp1-spk-cali-10431f62-spkid0-r0.bin cs35l41-dsp1-spk-cali-10431f63-spkid0-r0.bin
   12 sudo ln -sf cs35l41-dsp1-spk-cali-10431f62-spkid1-l0.bin cs35l41-dsp1-spk-cali-10431f63-spkid1-l0.bin
   13 sudo ln -sf cs35l41-dsp1-spk-cali-10431f62-spkid1-r0.bin cs35l41-dsp1-spk-cali-10431f63-spkid1-r0.bin
   14 sudo ln -sf cs35l41-dsp1-spk-prot-10431f62-spkid0-l0.bin cs35l41-dsp1-spk-prot-10431f63-spkid0-l0.bin
   15 sudo ln -sf cs35l41-dsp1-spk-prot-10431f62-spkid0-r0.bin cs35l41-dsp1-spk-prot-10431f63-spkid0-r0.bin
   16 sudo ln -sf cs35l41-dsp1-spk-prot-10431f62-spkid1-l0.bin cs35l41-dsp1-spk-prot-10431f63-spkid1-l0.bin
   17 sudo ln -sf cs35l41-dsp1-spk-prot-10431f62-spkid1-r0.bin cs35l41-dsp1-spk-prot-10431f63-spkid1-r0.bin


  ##### 第二步：配置核心參數
  強制驅動程式使用適合華碩 ExpertBook 系列的音效模型。


   1 # 建立/修改音效配置檔案
   2 echo "options snd-hda-intel model=alc294-asus-p50" | sudo tee /etc/modprobe.d/alsa-base.conf
   3
   4 # 更新 initramfs (確保開機掛載)
   5 sudo update-initramfs -u

  ##### 第三步：手動解除底層靜音 (ALSA)
  解除硬體暫存器中的強迫靜音狀態。


   1 # 根據 amixer contents 找到的 numid 進行操作
   2 amixer -c 0 cset numid=3 0  # 關閉 Forced Mute L
   3 amixer -c 0 cset numid=6 0  # 關閉 Forced Mute R
   4 amixer -c 0 cset numid=10 on # 開啟 Speaker Switch
   5 amixer -c 0 cset numid=9 87  # 調高 Speaker Volume


  ##### 第四步：完全斷電重置 (Cold Boot)
  這是最關鍵的一步：
   * 關機，拔掉電源線。
   * 靜置約 10 秒（讓放大器晶片完全失去電力以清除錯誤狀態）。
   * 重新接電開機。

  ---


  4. 未來維護建議
   * 核心更新： 之後若更新核心（例如升級到 6.18+），若發現聲音消失，請檢查 /etc/modprobe.d/alsa-base.conf 是否還在。
   * 韌體包更新： 若 linux-firmware 套件更新，可能會重新下載 .zst 檔案，屆時可能需要重新執行「解壓縮」的動作。


  這份紀錄可以保存在您的雲端筆記或 /etc/ 備份中，方便日後重裝系統時參考。很高興能幫您解決問題！
