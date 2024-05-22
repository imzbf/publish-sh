#!/bin/bash

# 定义函数用于选择发布的版本
select_option() {
  choices=("$@")
  selectedIndex=0

  while true; do
    clear
    echo "选择发布的版本"
    for index in "${!choices[@]}"; do
      if [ $index -eq $selectedIndex ]; then
        printf "\033[33m> ${choices[$index]}\e[0m\n"
      else
        echo "  ${choices[$index]}"
      fi
    done

    read -n1 -s key

    case "$key" in
      A)  # 上箭头
        if [ $selectedIndex -gt 0 ]; then
          selectedIndex=$((selectedIndex - 1))
        else
          selectedIndex=$(( ${#choices[@]} - 1 ))
        fi
        ;;
      B)  # 下箭头
        if [ $selectedIndex -lt $(( ${#choices[@]} - 1 )) ]; then
          selectedIndex=$((selectedIndex + 1))
        else
          selectedIndex=0
        fi
        ;;
      "")  # 回车键
        break
        ;;
    esac
  done

  selected_option="${choices[$selectedIndex]}"
}

# 提交未提交的内容
while true; do
    # 获取当前目录的Git状态
    status=$(git status --porcelain)

    # 检查是否有未提交的文件或更改
    if [ -n "$status" ]; then
        echo "存在未提交的文件或更改："
        echo "$status"
        
        git add .
        git cz
    else
        break
    fi
done


echo "拉取远程develop分支"
git pull origin develop

git checkout main

echo "拉取远程main分支"
git pull origin main
git merge develop

# brew install jq
# 获取当前版本号
current_version=$(jq -r '.version' package.json)

# 分解版本号
IFS='.' read -r major minor patch <<< "$current_version"

# 计算新的版本号
next_patch="$major.$minor.$((patch + 1))"
next_minor="$major.$((minor + 1)).0"
next_major="$((major + 1)).0.0"
next_prepatch="$major.$minor.$((patch + 1))-0"
next_preminor="$major.$((minor + 1)).0-0"
next_premajor="$((major + 1)).0.0-0"
next_prerelease="$major.$minor.$patch-1"

# 定义选项数组
options=(
    "patch [$next_patch]"
    "minor [$next_minor]"
    "major [$next_major]"
    "prepatch [$next_prepatch]"
    "preminor [$next_preminor]"
    "premajor [$next_premajor]"
    "prerelease [$next_prerelease]"
    "退出"
)

select_option "${options[@]}"

selected_parameter=$(echo "$selected_option" | cut -d "[" -f 2 | cut -d "]" -f 1)

echo "执行: npm version $selected_parameter"
version=$(npm version $selected_parameter)

echo "新的版本号：$version"

echo "推送"
git push origin $version main develop

echo "结束"