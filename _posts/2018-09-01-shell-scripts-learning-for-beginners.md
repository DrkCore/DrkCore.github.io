---
layout: post
title:  "Linux：Shell 脚本的简要入门"
date:   2018-09-01 22:39:50 +0800
categories: Linux Shell
---

笔者第一次接触 Linux 操作系统还是在大学时代，当虚拟机显示出 Ubuntu 的标识的那一刻笔者才知道原来操作系统并不是只有 Windows，可惜之后一直没能好好研究这个系统，直到随着工作的变动这才有了机会领略一番 Linux 的命令行和 Shell 脚本的威力。

MaxOS 和 Linux 都是类 Unix 系统所以 Shell 脚本的语法都能兼容，而 Windows 阵营在微软于 Win10 上推出 WSL（Windows Subsystem for Linux）之后也能使用 Shell 的语法。对于普通的开发者来说 WSL 提供的 Linux 功能堪称完美，在其上编译 APK 毫无问题。

工作中笔者主要使用的系统是 [Linux Mint](https://www.linuxmint.com)，这个系统对新手十分友好，如果你是刚刚从 Windows 系统转过来的话可能还会对它的界面和交互模式有种莫名的熟悉感，推荐刚接触 Linux 的读者安装使用。

好了，让我们进入正文，聊一聊如何入门 Shell 脚本的编写吧！

# Hello World

```bash
#!/bin/bash

# 该脚本执行后将会输出 Hello World
echo "Hello Word"
```

将这段代码另存为 helloworld.sh 文件，并如下执行命令：

```bash
$ chmod +x helloworld.sh
$ ./helloworld.sh
HelloWorld
```

可以看到脚本成功输出了我们想要的 `Hello World`。

Shell 脚本中比较基础的知识点如下：

- 开头的 `#!` 语法用于标注脚本的解释器，本例中解释器是 `bash`，不指定解释器则由运行环境决定
- 使用 `#` 作为注释的开头
- `chmod +x 文件名` 命令用于授予文件执行权限，没有执行权限就尝试运行会抛出 `Permission denied` 异常
- `echo` 命令常用于输出日志
- 绝大多数命令直接加 `-h` 或者 `--help` 就能看到使用说明
- 敲命令行的时候可以使用 `TAB` 键来补全部分命令

# 变量

```bash
#!/bin/bash

# 基本上 Shell 能用的变量类型就时数字、字符串和数组了
var_num=123
var_str="MyName"
# 数组申明时，元素之间使用空格来间隔，而不是常见的逗号
var_array=(1 2 3)

echo "var_num is ${var_num}"
echo "var_str is ${var_str}"

# 截取字符串，表示从下标 1 个开始截取 3 个字符
echo "${var_str:1:3}"
# 字符串长度
echo "the length of the string is ${#var_str}"
# 字符串拼接，类似 Kotlin
var_str="num is ${var_num} and str is ${var_str}"
echo "${var_str}"
# 需要注意的是，如果你使用了单引号的话用 ${var_num} 来引用变量将是无效的
var_str='the num is ${var_num}'
echo "${var_str}"

# 数组操作
echo "var_array is ${var_array[*]}"
echo "v1 is ${var_array[1]}"
echo "the length of var_array is ${#var_array[@]}"

# 数学计算
let a=5+4
let b=a-3 
echo $a $b
```

- 变量名限制和大多数编程语言类似
- 变量名和等号之间不能有空格
- 使用 `${var}` 的格式来引用变量
- 使用 `let` 命令可以进行数字的计算，在 `let` 命令的表达式中不需要使用 `${var}` 格式来引用变量

# 流程控制

```bash
#!/usr/bin/env bash

# 定义参数
arg1="test"
arg2="hello"

# 取出参数时需要加 '$' 符号
if [ ${arg1} == ${arg2} ]; then
    echo "arg1 is equal to arg2"

elif [ ${arg1} == "test" ]; then
    echo "arg1 is 'test'"

else
    echo "nothing here"
fi
```

需要注意的是在表达式两边各有两个空格，既 `if [空格 表达式 空格]`，如果缺少空格的话运行时会报错。

以下是一些 `if` 语句常用的判定：

```bash
# 字符串判空 ===========================================
empty=
# 这里注意参数要加双引号
if [ -z "${empty}" ]; then
    echo "arg is empty"
fi

notEmpty="123"
if [ -n "${notEmpty}" ]; then
    echo "arg is not empty"
fi

# 文件判断 ============================================
if [ -f ./if.sh ]; then
    echo "if.sh file is existing"
fi

if [ -d ../ ]; then
    echo "../ dir is existing"
fi
```

除了 `if` 语法以外 Shell 脚本当然还可以使用 `switch` 语法：

```bash
# case 语句 ============================
opt="a"
case ${opt} in
    a) # 直接判断相等
        echo "opt is a"
        ;;
    [0-9]) # 使用正则表达式匹配
        echo "opt is a num"
        ;;
    *) # 通配符处理 default 的情况
        echo "opt '${opt}' is not in the cases"
        ;;
esac
```

Shell 中的 `switch` 有点类似 Kotlin 中的 `when`，不过可以直接使用正则表达式匹配这一点还是很不错的。

循环语句的话则是如下：

```bash
#!/bin/bash

# 使用数组
array=(1 2 3 4 5)
for loop in ${array[@]}
do
    echo "The value is: $loop"
done

# 使用 while 语句
int=1
while(( $int<=5 ))
do
    echo $int
    let "int++"
done
```

# 导入函数和脚本

就像在平常开发中写工具类一样，在 Shell 脚本中你也可以将常用的函数或者变量写到一个单独的文件里面然后再导入。将以下代码另存为 `utils.sh` 文件：

```bash
#!/usr/bin/env bash

CONST_VAL="THIS IS CONST VAL"

function printArg(){
    arg=$1

    # 通过 echo 返回结果
    echo "What you input is ${arg}"
}
```

可以看到在里面我们定义了一个变量和一个函数，接下来我们将要在另一个脚本中使用它：

```bash
#!/usr/bin/env bash
source ./utils.sh

echo "Value is ${CONST_VAL}"

# 使用 $(命令) 可以将函数或者其他命令的输出赋值给其他变量
result=$(printArg 123)
echo ${result}
```

以上脚本运行时将会输出如下内容：

```
Value is THIS IS CONST VAL
What you input is 123
```

- 在 `function` 末尾使用 `echo` 作为函数的返回结果
- 使用 `source` 来导入其他脚本文件的逻辑
- 使用 `$(命令)` 可以将函数或者其他命令的输出赋值给其他变量

# 参数传入和处理

```bash
# 以 $n 来使用第 n 个参数
echo "first arg is ：$1"
echo "second arg is ：$2"
echo "third arg is ：$3"
# 使用 $* 来获取所有参数的数组
echo "all args are: $*"
```

如果时比较简单的脚本的话直接使用参数时可以的，不过如果需要解析复杂参数的话就需要做特殊处理了。实际上当你使用 `-h` 或者 `--help` 查看脚本使用手册时就会发现他们有着各式各样的参数选项，比如 `zip` 命令：

```bash
$ zip --help

Copyright (c) 1990-2008 Info-ZIP - Type 'zip "-L"' for software license.
Zip 3.0 (July 5th 2008). Usage:
zip [-options] [-b path] [-t mmddyyyy] [-n suffixes] [zipfile list] [-xi list]
  The default action is to add or replace zipfile entries from list, which
  can include the special name - to compress standard input.
  If zipfile and list are omitted, zip compresses stdin to stdout.
  -f   freshen: only changed files  -u   update: only changed or new files
  -d   delete entries in zipfile    -m   move into zipfile (delete OS files)
  -r   recurse into directories     -j   junk (don't record) directory names
  -0   store only                   -l   convert LF to CR LF (-ll CR LF to LF)
  -1   compress faster              -9   compress better
  -q   quiet operation              -v   verbose operation/print version info
  -c   add one-line comments        -z   add zipfile comment
  -@   read names from stdin        -o   make zipfile as old as latest entry
  -x   exclude the following names  -i   include only the following names
  -F   fix zipfile (-FF try harder) -D   do not add directory entries
  -A   adjust self-extracting exe   -J   junk zipfile prefix (unzipsfx)
  -T   test zipfile integrity       -X   eXclude eXtra file attributes
  -y   store symbolic links as the link instead of the referenced file
  -e   encrypt                      -n   don't compress these suffixes
  -h2  show more help
```

在你编写自己的脚本时你可以使用如下的语法来做到同样的操作：

```bash
#!/usr/bin/env bash

outputDir=gen
assembleMode=Release
while getopts ":ho:d" opt; do
    case ${opt} in
    h)
        echo -e "Assemble apk and store the outputs.\n"
        echo "Usage:"
        echo "build_apk.sh [OPTIONS] [ARGS...]"
        echo "    -o STORE_DIR    specify directory to store the zipped outputs files."
        echo "    -d                       assemble apk in debug mode."
        exit 0
        ;;
    o)
        outputDir=${OPTARG}
        ;;
    d)
        assembleMode=Debug
        ;;
    \?)
        echo "Invalid option: -${OPTARG}"
        exit 1
        ;;
    esac
done
```

保存为 `assemble.sh` 后运行 `assemble.sh -h` 时你将会看到如下输出：

```
Assemble apk and store the outputs.

Usage:
build_apk.sh [OPTIONS] [ARGS...]
    -o STORE_DIR    specify directory to store the zipped outputs files.
    -d              assemble apk in debug mode.
```

# 写一个 Android 工程自动打包脚本

编写脚本的目的自然是为了简化日常中繁琐的操作以提高工作效率，接下来让我们一切编写一个自动打包 Android 工程的脚本作为本篇博客的总结，笔者将会提供尽可能详细注释以便读者理解：

```bash
#!/usr/bin/env bash

# 设置抛出异常就终止脚本运行
set -e
# 导入系统环境变量
source /etc/profile
# 获取当前脚本所在的绝对路径
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

appModule=app

storeDir=${SELF_DIR}/gen
assembleMode=Release
while getopts ":ho:d" opt; do
    case ${opt} in
    h)
        echo -e "Assemble apk and store the outputs.\n"
        echo "Usage:"
        echo "build_apk.sh [OPTIONS] [ARGS...]"
        echo "    -o STORE_DIR    specify directory to store the zipped outputs files."
        echo "    -d                       assemble apk in debug mode."
        exit 0
        ;;
    o)
        storeDir=${OPTARG}
        ;;
    d)
        assembleMode=Debug
        ;;
    \?)
        echo "Invalid option: -${OPTARG}"
        exit 1
        ;;
    esac
done

# 检查参数合法性
# exit 0 表示脚本正常执行结束
# exit 1 表示脚本异常并终止运行

# 检查当前时位于 Android 工程目录下
if [ ! -f ./gradlew ]; then
    echo "Please exec this script under android project directory."
    exit 1
fi

# 创建用于保存打包文件的目录，-p 表示如果父目录不存在，则一并创建
mkdir -p ${storeDir}
if [ ! -d ${storeDir} ]; then
    echo "Output directory '${storeDir}' is not available."
    exit 1
fi

./gradlew ${appModule}:clean
# 使用指定模式编译 apk 这里实际执行的是 ./gradlew :app:assembleRelease 或者 ./gradlew :app:assembleDebug
./gradlew ${appModule}:assemble${assembleMode}

outputsDir=${SELF_DIR}/${appModule}/build/outputs
# 生成时间戳
timestamp=$(date +"%Y-%m-%d_%H-%M-%S_%N")
storeFile=${storeDir}/app_${assembleMode}_${timestamp}.zip
# 如果该文件已存在，则删除
rm -rf ${storeFile}
# 压缩输出目录并保存到对应位置
cd ${outputsDir}
zip -r -9 ${storeFile} ./
cd ${SELF_DIR}

echo "--------------------------------------------------------"
echo "Total time: ${SECONDS}s"
```

在 Android 工程目录下执行该脚本，就会自动打包，并将打包好的文件压缩保存到 `gen` 目录下。

# 工具推荐

## [oh-my-zsh](https://ohmyz.sh/)

oh-my-zsh 是笔者使用过的相当方便的 Shell 环境，带有强大的补全功能，而且支持安装插件

![](https://ohmyz.sh/img/themes/nebirhos.jpg)

## [Guake](http://guake-project.org/)

Guake 是一个快捷的命令行工具，允许使用 `F12` 键快速调取出一个半屏的命令行窗口

![](http://guake-project.org/img/screenshot.png)

## [Cmder](https://cmder.net/)（Win）

Linux 和 MacOS 都能很好的兼容的 Shell 脚本，Windows 用户如果想要使用 Shell 脚本的话就只能使用 Linux 子系统了（Windows Subsystem for Linux，限 Win10 系统），具体的安装过程可以自行搜索。

这里推荐 Cmder 作为日常的命令行工具：

![](https://cmder.net/img/main.png)

---

以上，就是本篇博客的全部内容，所有的源码你都可以在以下地址中找到：

[https://github.com/DrkCore/DrkCore.github.io/tree/master/_posts/scripts/shell-scripts-learning-for-beginners](https://github.com/DrkCore/DrkCore.github.io/tree/master/_posts/scripts/shell-scripts-learning-for-beginners)

如果你觉得笔者写还可以，欢迎 **star** 该项目！！！