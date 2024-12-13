#!/bin/bash

# 定义函数用于选择发布的版本
select_option() {
  args=("$@")
  len=${#args[@]}
  choices=("${args[@]:0:len-1}")
  selectedIndex=0

  while true; do
    clear
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
select_option "${branch_options[@]}" "选择开发分支"
# 获取开发的分支
develop_branch="$selected_option"

select_option "${branch_options[@]}" "选择发布分支"
# 获取发布的分支
publish_branch="$selected_option"

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

git checkout $develop_branch
echo "拉取远程 $develop_branch 分支"
git pull origin $develop_branch

git checkout $publish_branch

echo "拉取远程${publish_branch}分支"
git pull origin $publish_branch
echo "合并 $develop_branch 分支"
git merge $develop_branch

read_input() {
    local input
    while :; do
      read -p "是否添加tag（y/n）: " input
      # 如果输入不为空，则退出循环
      if [[ -n "$input" ]]; then
          break
      fi

      # clear
    done
    # 返回有效输入
    echo "$input"
}

# 调用函数读取输入
create_tag=$(read_input)

if [ $create_tag != "n" ]; then
  # 获取当前版本号
  current_version=$(grep '"version"' package.json | sed -E 's/.*"version": "([^"]+)".*/\1/')

  # 分解版本号，处理pre-release的情况
  if [[ "$current_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)$ ]]; then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    patch=${BASH_REMATCH[3]}
    prerelease=${BASH_REMATCH[4]}
  else
    IFS='.' read -r major minor patch <<< "$current_version"
    prerelease=""
  fi

  # 计算新的版本号
  next_patch="$major.$minor.$((patch + 1))"
  next_minor="$major.$((minor + 1)).0"
  next_major="$((major + 1)).0.0"
  next_prepatch="$major.$minor.$((patch + 1))-0"
  next_preminor="$major.$((minor + 1)).0-0"
  next_premajor="$((major + 1)).0.0-0"

  # 根据是否是 pre-release 来决定如何生成下一个 prerelease 版本
  if [ -n "$prerelease" ]; then
    next_prerelease="$major.$minor.$patch-$((prerelease + 1))"
  else
    next_prerelease="$major.$minor.$((patch + 1))-0"
  fi

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

  selected_parameter=$(echo "$selected_option" | cut -d " " -f 1)

  version=$(npm version $selected_parameter)

  needMergeArr=("patch" "minor" "major")
  needMerge=false
  for element in "${needMergeArr[@]}"; do
    if [ "$element" == "$selected_parameter" ]; then
      needMerge=true
    fi
  done

  git checkout $develop_branch

  if [ $needMerge == true ]; then
    echo "将${publish_branch}合并回 $develop_branch "
    git merge $publish_branch
  fi

  options=(
    "否"
    "是"
  )

  select_option "${options[@]}" "是否推送tag"
  push_tag="$selected_option"

  echo "推送代码"
  if [ $push_tag == "是" ]; then
    git push origin $version $publish_branch $develop_branch
  else
    git push origin $publish_branch $develop_branch
  fi
else
  git checkout $develop_branch

  options=(
    "否"
    "是"
  )

  select_option "${options[@]}" "是否合回代码"
  merge_back="$selected_option"

  if [ $merge_back == "是" ]; then
    echo "将${publish_branch}合并回 $develop_branch "
    git merge $publish_branch
  fi

  echo "推送代码"
  git push origin $publish_branch $develop_branch
fi

echo "结束"