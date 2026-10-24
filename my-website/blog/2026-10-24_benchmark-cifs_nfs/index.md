---
title: "benchmark cifs nfs 性能差異"
tags: [linux,cifs,nfs]
---

在 Linux 上連 Synology NAS，到底該用 CIFS 還是 NFS？實際用 fio 測一次。

<!-- truncate -->

## 前言

心血來潮，想說我的電腦既然是 Linux，為什麼連 Synology NAS 還要用 CIFS？
NFS 可能會更好，於是有了這篇 benchmark。

方法：分別以 CIFS / NFS mount 同一個 NAS volume，用 fio 跑同一份設定檔（11 個 job，各 60 秒）。

## 測試結果

每格為 `IOPS / 頻寬 / 平均延遲`，**粗體**為較佳者（差距小於 5% 視為持平，不標示）。

| Job | 方向 | CIFS | NFS |
| --- | --- | --- | --- |
| 4k randread qd1 | read | 4248 / 16.6 MiB/s / 234 µs | 3885 / 15.2 MiB/s / 256 µs |
| 4k randwrite qd1 | write | 4179 / 16.3 MiB/s / 238 µs | 3695 / 14.4 MiB/s / 269 µs |
| 4k randread qd16 | read | 23.0k / 89.8 MiB/s / 695 µs | **26.5k / 104 MiB/s / 603 µs** |
| 4k randwrite qd16 | write | 18.3k / 71.6 MiB/s / 872 µs | 18.4k / 71.7 MiB/s / 866 µs |
| 64k randrw 70/30 qd16 | read | 1190 / 74.4 MiB/s / 9.5 ms | **1616 / 101 MiB/s / 6.0 ms** |
| 64k randrw 70/30 qd16 | write | 515 / 32.3 MiB/s / 9.5 ms | **695 / 43.5 MiB/s / 9.3 ms** |
| 1m seq read qd1 | read | 103 / 103 MiB/s / 9.7 ms | 103 / 103 MiB/s / 9.7 ms |
| 1m seq write qd1 | write | 104 / 104 MiB/s / 9.6 ms | 100 / 100 MiB/s / 10.0 ms |
| 1m seq read qd16 | read | 106 / 107 MiB/s / 150 ms | 106 / 107 MiB/s / 150 ms |
| 1m seq write qd16 | write | 111 / 112 MiB/s / 143 ms | 111 / 112 MiB/s / 143 ms |
| 1m seq read 4 jobs | read | 106 / 107 MiB/s / 599 ms | 105 / 107 MiB/s / 603 ms |
| 1m seq write 4 jobs | write | 106 / 107 MiB/s / 600 ms | 108 / 110 MiB/s / 585 ms |

原始 log：[fio_nfs.log](./fio_nfs.log)、[fio_cifs.log](./fio_cifs.log)

## 結論

- **循序讀寫完全持平**：全部卡在約 107 MiB/s，這是 1GbE 的線速上限（約 118 MB/s 扣掉協定開銷），瓶頸在網路，不在協定。
- **4k 隨機 qd1**：CIFS 略快約 10%（延遲 234 µs vs 256 µs），差距很小，可能在誤差範圍。
- **4k 隨機 qd16**：讀取 NFS 快約 15%，寫入持平。
- **64k 混合讀寫**：NFS 明顯勝出，讀寫都快約 35%，且讀取延遲低約 37%（6.0 ms vs 9.5 ms）。
- 若主要是大檔案複製，兩者沒差；若有多工、小檔或混合負載（如開專案、跑 build），NFS 較有利。
- 注意：兩者在 64k 混合測試的寫入都出現秒級的極端延遲（NFS 最大約 3.9 秒、CIFS 約 2.4 秒），推測是 NAS 端 flush 造成，兩邊皆有，不構成選擇依據。

> 限制：只測一輪，未重複取平均；網路為 1GbE，若升級到 2.5G / 10G，差異可能會更明顯。

## 測試細節
執行 
`fio fio.conf`

`fio.conf`
```bash
; usage:
;   fio fio.conf --output=fio.log

; run as root and drop caches between runs if needed:
;   sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches

[global]
filename=testfile.dat
size=5g
ioengine=libaio
direct=1
end_fsync=1
group_reporting
stonewall
runtime=60
time_based
ramp_time=5

; ---- 4k random, qd1 / qd16 ----
[4kRandRead-qd1]
bs=4k
readwrite=randread
iodepth=1

[4kRandWrite-qd1]
bs=4k
readwrite=randwrite
iodepth=1

[4kRandRead-qd16]
bs=4k
readwrite=randread
iodepth=16

[4kRandWrite-qd16]
bs=4k
readwrite=randwrite
iodepth=16

; ---- 64k mixed 70/30 ----
[64kRandRW-qd16]
bs=64k
readwrite=randrw
rwmixread=70
iodepth=16

; ---- 1m sequential, qd1 / qd16 ----
[1mSeqRead-qd1]
bs=1m
readwrite=read
iodepth=1

[1mSeqWrite-qd1]
bs=1m
readwrite=write
iodepth=1

[1mSeqRead-qd16]
bs=1m
readwrite=read
iodepth=16

[1mSeqWrite-qd16]
bs=1m
readwrite=write
iodepth=16

; ---- 1m sequential, multi-job ----
[1mSeqRead-4jobs]
bs=1m
readwrite=read
iodepth=16
numjobs=4

[1mSeqWrite-4jobs]
bs=1m
readwrite=write
iodepth=16
numjobs=4

```