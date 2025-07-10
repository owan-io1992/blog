---
date: 2025-06-18T02:49:00  
draft: false
tags:
- mise
- runtime manager
title: "developer 神器 runtime manager: mise"
---
![alt](images/banner.png)  

<!--more-->

## Introduction
對於開發者而言  
在開發的第一步是要先把 runtime 裝起來  
比如說 python/golang/node.js ...  

如果開發者用到多個 project/多個版本 通常會借助 runtime manager  
以下列出常見的 runtime manager  
python: pyenv  
golang: gvm  
node.js: nvm   

這時會發現一件事 不同的 runtime 就有不同的 runtime manager  

不同的 runtime manager 就有不同的操作方式  

![我好累](images/我好累.jpeg)


於是一個能 handle 大部分 runtime 的 runtime manager  
就很方便了  

## mise:  
[official site](https://mise.jdx.dev)

mise 作為一個 tool 來集中管理你的 runtime  
除了剛剛的例子外 python,golang/node.js  
像是 awscli/ansible/gcloud 也能支援  
所以不只 developer, 對於 operator 也是很有幫助  

還支援設定 environments & tasks (能夠讓你取代 make)  

他能夠支援的 tool 可以參考 [backends](https://mise.jdx.dev/dev-tools/backends/)  

利用 mise 管理的 runtime 可以是 global level  

也可以是 directory level
切換不同 directory, mise 會自動幫你切換 directory 設定的 runtime 版本  

有了 mise 之後   
要安裝 runtime 會變得超級簡單  
在統一團隊之間的 runtime 也變得非常容易  

## install mise
[doc](https://mise.jdx.dev/getting-started.html)

安裝 mise 及 activate (讓 mise 能夠幫你管 runtime)  
以下環境是以 linux 為範例  
如果環境不同 可以參考官方 doc  

```bash
# install mise
curl https://mise.run | sh

# set auto activate mise
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
```

## install runtime

### get info about runtime
首先先了解 mise 能夠幫忙管理哪些 runtime 及版本
```bash
mise ls-remote --all

# grep keyword "python"
mise ls-remote --all | grep python
```

### install runtime to global
嘗試安裝 python 3.13.5 在 global  
亦即不管你在哪個 workdirectory 都是使用此版本  
mise 會將設定寫在 `~/.config/mise/config.toml`  
除了用 mise 去指定外, 直接編輯 toml 也是可以的  

```bash
mise use --global python@3.13.5
```

### install runtime to directory

現在假設有個 dir1 想要使用 python 3.12.11
我們到該 directory root 下

```bash
mise use python@3.12.11
```

mise 會在此處產生一個 `mise.toml` 我們設定的 runtime 版本就會寫在此  
另外也可以看到 directory level 會優先於 global level 
```bash
$ cat mise.toml 
[tools]
python = "3.12.11"

$ python3 -V
Python 3.12.11
```

那進到 sub directory 會發生什麼事？ 
```bash
dir1/sub1$ python3 -V
Python 3.12.11
```

可以看到依舊是 Python 3.12.11  
mise 會自動 lookup top directory 的 mise.toml  
如果找不到 就會使用 global 的 config  


### install runtime from mise.toml

如果把 `mise.toml` 放在 git repo 中的 root 位置  
就等於宣告該 repo 要使用的 runtime 版本  
因此只要把 `mise.toml` commit 到 git 內  
在 team member 之間要確保版本一致就相當簡單  
再也不會有人使用不同的 runtime 去開發造成環境不一致產生的問題了  

對於其他 member 而言  
要安裝 runtime 只要下 以下指令即可   

```bash
mise trust # allow mise use this mise.toml
mise install # this is option
```

## Conclusion
對於 developer/operator/devops/sre 而言  
mise 是非常方便的工具  
關於 envrironments and tasks 就讓大家自行挖掘如何使用  
如果你跟我一樣之前是 asdf, 那換到 mise 一定是非常舒服的事情  
因為他的目標就是取代 asdf  
他比 asdf 容易使用且更加的強大  

let's happy developing  

## reference
https://github.com/bernardoduarte/awesome-version-managers

