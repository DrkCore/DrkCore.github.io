---
layout: post
title:  "Linux Shell 脚本的简要入门"
date:   2018-3-18 22:39:50 +0800
categories: Linux
---

笔者第一次接触 Linux 操作系统还是在大学时代，当虚拟机显示出 Ubuntu 的标识的那一刻笔者才知道原来操作系统并不是只有 Windows。可惜之后一直没能好好研究这个系统，直到随着工作的变动来到了现在的公司，这才有了机会领略一番 Linux 的命令行和 Shell 脚本的威力。

笔者工作中主要使用的系统是 [Linux Mint](https://www.linuxmint.com)，这个系统对新手十分友好，如果你是刚刚从 Windows 系统转过来的话可能还会对它的界面和交互模式有种莫名的熟悉感。

好了，让我们进入正文，聊一聊如何入门 Linux Shell 脚本的编写吧！

# 基础知识

```shell
#!/usr/bin/env bash

echo "HelloWord"
```

将这段代码另存为 helloworld.sh 文件，并如下执行命令：

```shell
$ chmod +x helloworld.sh
$ ./helloworld.sh
HelloWorld
```

`chmod +x 文件名` 用于授予文件执行权限，之后调用该脚本就能在命令行中看到 `echo` 命令输出的 `HelloWorld` 语句了

在 Shell 脚本中你还可以调用另一个脚本甚至是导入其参数，将以下代码另存为 constants.sh 文件：

```shell
#!/usr/bin/env bash
```

## 条件判断

## 函数调用

# 参数处理

# 使用 oh-my-zsh 和 guake 以提高工作效率

# 在 Windows 下使用 Linux 命令