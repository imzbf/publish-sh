# publish-sh

本地合并代码，构建 tag 并提交脚本。

## 使用

方式一：下载代码，然后在项目内执行`npm link`
方式二：`npm install https://github.com/imzbf/publish-sh.git -g`

卸载方式均为：`npm uninstall publish-sh -g`

### 使用

在需要发布的项目中执行`pb`

流程示意：

```mermaid
flowchart TD
    A@{ shape: circle, label: "开始" } --> B[选择开发分支]
    B --> C[选择发布分支]
    C --> D{是否有未提交的更改？}
    D --> |是| F[拉取远程开发分支]
    D --> |否| E[输入提交信息，提交]
    E --> F
    F --> G[拉取远程发布分支]
    G --> H[合并本地开发分支到发布分支]
    H --> I{是否添加tag？}
    I --> |是| J[根据package.json中的版本号生成预发、测试等版本号供选择]
    I --> |否| K{是否合并代码回开发分支？}
    J --> L{是否是patch\minor\major版本}
    K --> |是| M[合并代码到开发分支]
    K --> |否| R
    L --> |是| O[合并代码到开发分支]
    L --> |否| P{是否推送tag到origin}
    O --> P
    M --> R
    P --> |是| Q[推送开发、发布分支和tag到origin]
    P --> |否| R[推送开发、发布分支到origin]
    Q --> V@{ shape: dbl-circ, label: "结束" }
    R --> V
```
