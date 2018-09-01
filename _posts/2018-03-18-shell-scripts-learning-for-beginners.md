---
layout: post
title:  "Shell 脚本的简要入门"
date:   2018-3-18 22:39:50 +0800
categories: Linux Shell
---

笔者第一次接触 Linux 操作系统还是在大学时代，当虚拟机显示出 Ubuntu 的标识的那一刻笔者才知道原来操作系统并不是只有 Windows，可惜之后一直没能好好研究这个系统，直到随着工作的变动这才有了机会领略一番 Linux 的命令行和 Shell 脚本的威力。

MaxOS 和 Linux 都是类 Unix 系统所以 Shell 脚本的语法都能兼容，而 Windows 阵营在微软于 Win10 上推出 WSL（Windows Subsystem for Linux）之后也能使用 Shell 的语法。对于普通的开发者来说 WSL 提供的 Linux 功能堪称完美，在其上编译 APK 毫无问题。

工作中笔者主要使用的系统是 [Linux Mint](https://www.linuxmint.com)，这个系统对新手十分友好，如果你是刚刚从 Windows 系统转过来的话可能还会对它的界面和交互模式有种莫名的熟悉感，推荐刚接触 Linux 的读者安装使用。

好了，让我们进入正文，聊一聊如何入门 Shell 脚本的编写吧！

# Hello World

```shell
#!/usr/bin/env bash

echo "Hello Word"
```

将这段代码另存为 helloworld.sh 文件，并如下执行命令：

```shell
$ chmod +x helloworld.sh
$ ./helloworld.sh
HelloWorld
```

`chmod +x 文件名` 用于授予文件执行权限，之后调用该脚本就能在命令行中看到 `echo` 命令输出的 `Hello World` 语句了。

# 条件判断

```shell
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

除了 `if` 语法以外 Shell 脚本当然还可以使用 `switch` 语法：

```shell
# case 语句 ============================
opt="a"
case ${opt} in
    a)
        echo "opt is a"
        ;;
    b)
        echo "opt is b"
        ;;
    *)
        echo "opt '${opt}' is not in the cases"
        ;;
esac
```

以下是一些 `if` 语句常用的判定：

```shell
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

# 导入函数和脚本

就像在平常开发中写工具类一样，在 Shell 脚本中你也可以将常用的函数或者变量写到一个单独的文件里面然后再导入。将以下代码另存为 `utils.sh` 文件：

```shell
#!/usr/bin/env bash

CONST_VAL="THIS IS CONST VAL"

function printArg(){
    arg=$1

    # 通过 echo 返回结果
    echo "What you input is ${arg}"
}
```

可以看到在里面我们定义了一个变量和一个函数，接下来我们将要在另一个脚本中使用它：

```shell
#!/usr/bin/env bash
source ./utils.sh

echo "Value is ${CONST_VAL}"

# 使用 $(命令) 可以将函数或者其他命令的输出转化成字符串，继而赋值给其他变量
result=$(printArg 123)
echo ${result}
```

将该脚本保存为 `import_test.sh` 并放置在 `utils.sh` 的同一目录下，执行后就可以看到输出：

```
Value is THIS IS CONST VAL
What you input is 123
```

# 参数处理

大多数命令行工具都可以通过添加 `-h` 或者 `--help` 来输出使用帮助，这类脚本通常还能使用各种参数来定义程序运行中的一些规则，比如 `zip` 命令：

```shell
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

```shell
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

# 编写 Android 工程自动打包脚本

编写脚本的目的自然是为了简化日常中繁琐的操作以提高工作效率，接下来让我们一切编写一个自动打包 Android 工程的脚本作为本篇博客的总结，笔者将会提供尽可能详细注释以便读者理解：

```shell
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
    echo "Please exec this scripts under android project directory."
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

以上，就是本篇博客的全部内容，所有的源码你都可以在以下地址中找到：

[https://github.com/DrkCore/DrkCore.github.io/tree/master/_posts/scripts/shell-scripts-learning-for-beginners](https://github.com/DrkCore/DrkCore.github.io/tree/master/_posts/scripts/shell-scripts-learning-for-beginners)

如果你觉得笔者写还可以，欢迎 **star** 该项目！！！