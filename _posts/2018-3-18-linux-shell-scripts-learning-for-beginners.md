---
layout: post
title:  "Linux Shell 脚本的简要入门"
date:   2018-3-18 22:39:50 +0800
categories: Linux
---

笔者第一次接触 Linux 操作系统还是在大学时代，当虚拟机显示出 Ubuntu 的标识的那一刻笔者才知道原来操作系统并不是只有 Windows。可惜之后一直没能好好研究这个系统，直到随着工作的变动来到了现在的公司，这才有了机会领略一番 Linux 的命令行和 Shell 脚本的威力。

笔者工作中主要使用的系统是 [Linux Mint](https://www.linuxmint.com)，对新手十分的友好，如果你是刚刚从 Windows 系统转过来的话可能还会对它的界面和交互模式有种莫名的熟悉感。

好了，让我们进入正文，来聊一聊如何入门 Linux Shell 脚本的编写吧！

# 脚本编写的起手式

```shell
#!/usr/bin/env bash
set -e
source /etc/profile
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "HelloWord"
```

将这段代码另存为 helloworld.sh 文件，并用如下命令赋予其执行权限：

```shell
chmod +x helloworld.sh
```

# 条件判断

# 函数调用

# 参数处理

# 使用 oh-my-zsh 和 guake 以提高工作效率

# 在 Windows 下使用 Linux 命令