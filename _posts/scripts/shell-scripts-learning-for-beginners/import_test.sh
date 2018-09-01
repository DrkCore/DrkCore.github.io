#!/usr/bin/env bash
source ./utils.sh

echo "Value is ${CONST_VAL}"

# 使用 $(命令) 可以将函数或者其他命令的输出转化成字符串，继而赋值给其他变量
result=$(printArg 123)
echo ${result}