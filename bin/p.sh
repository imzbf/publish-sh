#!/bin/bash

# 定义函数用于选择发布的版本
select_option() {
  args=("$@")
  len=${#args[@]}
  choices=("${args[@]:0:len-1}")
  selectedIndex=0

  while true; do
    # clear
    echo ${args[$len-1]}
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

# 获取本地分支列表
branches=$(git branch --format='%(refname:short)')

# 转换分支列表为数组
branch_options=($branches)

# 调用选择函数选择分支
select_option "${branch_options[@]}" "选择发布分支"

# 获取选择的分支
selected_branch="$selected_option"

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

git checkout develop
echo "拉取远程develop分支"
git pull origin develop

git checkout $selected_branch

echo "拉取远程${selected_branch}分支"
git pull origin $selected_branch
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
)

select_option "${options[@]}" "请选择发布的版本"

selected_parameter=$(echo "$selected_option" | cut -d "[" -f 1 | cut -d "]" -f 1)

echo "执行: npm version $selected_parameter"
version=$(npm version $selected_parameter)

echo "新的版本号：$version"

needMergeArr=("patch" "minor" "major")
needMerge=false
for element in "${needMergeArr[@]}"; do
  if [ "$element" == "$selected_parameter" ]; then
    needMerge=true
  fi
done

if [ $needMerge == true]; then
  git checkout develop
  echo "将${selected_parameter}合并回develop"
  git merge $selected_parameter

echo "推送"
git push origin $version ${$selected_branch} develop

echo "结束"
