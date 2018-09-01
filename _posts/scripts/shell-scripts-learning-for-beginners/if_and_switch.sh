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
