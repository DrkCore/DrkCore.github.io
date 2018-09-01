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