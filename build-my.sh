#!/bin/bash
# tree-sitter github 官网上支持的语言
languages=(
    'bash'
    'c'
    'cpp'
    'css'
    'c-sharp'
    'go'
    'html'
    'haskell'
    'java'
    'javascript'
    'json'
    'julia'
    'python'
    'php'
    'ql'
    'ruby'
    'rust'
    'regex'
    'scala'
    'swift'
)
# 非 tree-sitter 官网上收录的语言
languages_other=(
    'commonlisp'
    'cuda'
    'elisp'
    'lua'
    'make'
    'markdown'
    'objc'
    'perl'
    'r'
    'sql'
    'toml'
    'tsx'
    'typescript'
    'vue'
)
declare -A languages_other_url
languages_other_url["toml"]="https://github.com/ikatyang/tree-sitter-toml"
languages_other_url["sql"]="https://github.com/m-novikov/tree-sitter-sql"
languages_other_url["perl"]="https://github.com/ganezdragon/tree-sitter-perl"
languages_other_url["objc"]="https://github.com/merico-dev/tree-sitter-objc"
languages_other_url["commonlisp"]="https://github.com/theHamsta/tree-sitter-commonlisp"
languages_other_url["vue"]="https://github.com/ikatyang/tree-sitter-vue"
languages_other_url["elisp"]="https://github.com/Wilfred/tree-sitter-elisp"
languages_other_url["lua"]="https://github.com/Azganoth/tree-sitter-lua"
languages_other_url["markdown"]="https://github.com/ikatyang/tree-sitter-markdown"
languages_other_url["r"]="https://github.com/r-lib/tree-sitter-r"
languages_other_url["typescript"]="https://github.com/tree-sitter/tree-sitter-typescript"
languages_other_url["tsx"]="https://github.com/tree-sitter/tree-sitter-typescript"
languages_other_url["cuda"]="https://github.com/theHamsta/tree-sitter-cuda"
languages_other_url["make"]="https://github.com/alemuller/tree-sitter-make"

if [ $(uname) == "Darwin" ]
then
    soext="dylib"
else
    soext="so"
fi


# 定义一个函数，这个函数接受一个参数，此参数为所支持的语言
function get_url() {
    for i in ${languages[@]}
    do
        [ "$i" == "$1" ] && echo "https://github.com/tree-sitter/tree-sitter-$i.git"
    done
    for i in ${languages_other[@]}
    do
        [ "$i" == "$1" ] && echo "${languages_other_url[$1]}.git"
    done
}

# 构建函数
# 参数为 lang 和 url
function build_language() {
    [ -z $2 ] && echo  "此语言暂时不支持，详情输入 ./build-my.sh help 查看" && exit 0
    # 下载的脚本的地址
    module_path=`pwd`

    # Retrieve sources.
    if [ ! \( -d "tree-sitter-$1" \) ]; then
        git clone $2  --depth 1
        # 获取失败则直接返回
        [ "$?" != "0" ] && return
    fi

    # 构建地址
    # typescript 情况有点特殊
    if [ "$1" == "typescript" ]; then
        build_path="tree-sitter-typescript/typescript"
    elif [ "$1" == "tsx" ]; then
        build_path="tree-sitter-typescript/tsx"
    else
        build_path="tree-sitter-$1"
    fi

    cp tree-sitter-lang.in "$build_path/src"
    cp emacs-module.h "$build_path/src"
    cp "$build_path/grammar.js" "$build_path/src"
    cd "$build_path/src"
    # The dynamic module's c source.

    # Build.
    cc -c -I. parser.c
    # Compile scanner.c.
    if test -f scanner.c
    then
        cc -fPIC -c -I. scanner.c
    fi
    # Compile scanner.cc.
    if test -f scanner.cc
    then
        c++ -fPIC -I. -c scanner.cc
    fi

    # Link.
    if test -f scanner.cc
    then
        c++ -fPIC -shared *.o -o "libtree-sitter-$1.${soext}"
    else
        cc -fPIC -shared *.o -o "libtree-sitter-$1.${soext}"
    fi

    # Copy out.
    if [ ! \( -d "$module_path/dist" \) ]; then
        mkdir -p "$module_path/dist"
    fi

    cp "libtree-sitter-$1.${soext}" "$module_path/dist"
    cd $module_path
    rm -rf ${build_path%/*}
}

function build_help() {
    # 输出支持的语言
    echo "该脚本支持的语言如下："
    echo ${languages[@]}
    echo ${languages_other[@]}
    echo "使用方法：
不带参数：默认构建所有脚本支持的语言
如果只有一个参数 help，打印 help，否则查看是否属于脚本支持的语言，
支持则自动开始构建，不支持提醒用户
多个参数，如果第二个参数是 url，则从该 url 获取源码构建相关语言
如果第二个参数不是 url，则认为其是所支持的语言
两个参数以上则默认所有参数都是所支持的语言
./build-my.sh 不带参数：默认构建所有脚本支持的语言
./build-my.sh help 查看支持语言以及使用方法
./build-my.sh language 对支持的语言进行构建
./build-my.sh language 'url' 对不支持的语言，通过添加 url 参数来进行构建."
    exit 0
}

if [ "$#" == 1 ]; then
    if [ "$1" == "help" ]; then
        build_help
    else
        build_language $1 `get_url $1`
    fi
elif (($#>1)); then
    if [[ "$2" == *":"* ]]; then
        build_language $1 $2
    else
        for i in $@
        do
            build_language $i `get_url $i`
        done
    fi
else
    for i in ${languages[@]} ${languages_other[@]}
    do
        build_language $i `get_url $i`
    done
fi
