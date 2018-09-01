#!/usr/bin/env bash

CONST_VAL="THIS IS CONST VAL"

function printArg(){
    arg=$1

    # 通过 echo 返回结果
    echo "What you input is ${arg}"
}