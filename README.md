# 文本选择搜索（ShareRunner）

一个 HarmonyOS 文本搜索中转应用：在任意应用中选中文字后，通过系统文本选择菜单的「搜索」或分享面板把文字传入本应用，选择搜索引擎即可跳转搜索。搜索引擎支持自定义。

应用本身不抓取网页、不保存搜索历史，只负责接收文本、拼接搜索 URL，并交给系统打开。

## 功能

- **文本选择菜单搜索**：注册 `ohos.want.action.search`，接收系统传入的选中文本。
- **分享面板接入**：以 ShareExtension 接收 `general.text` 纯文本（最多 1 个文件）。
- **自定义搜索引擎**：名称 + URL 模板，`%s` 代表关键词，执行时自动做 URL 编码。
- **技能管理**：新建、编辑、左滑删除，并可用测试文本直接验证跳转。
- **内置常用引擎**：百度、必应、知乎、哔哩哔哩、淘宝。
- **本地持久化**：配置保存在本机 preferences 中，无账号体系。
- **手机 / 平板适配**：沉浸式窗口、深浅色系统栏与安全区处理。

## 工作流程

```mermaid
flowchart LR
  A[任意应用选中文本] --> B[文本选择菜单 · 搜索]
  A --> C[系统分享面板]
  B --> D[SearchAbility]
  C --> E[ShareExtAbility]
  D --> F[SearchPicker<br>选择搜索引擎]
  E --> G[SharePicker<br>选择搜索引擎]
  F --> H[拼接搜索 URL<br>%s → 编码后的文本]
  G --> H
  H --> I[openLink<br>系统浏览器 / 搜索 App]
```

## 使用方式

### 1. 管理搜索引擎

打开应用后可以：

- 点击「+ 新建」添加搜索引擎；
- 点击列表项编辑名称或 URL 模板；
- 左滑删除；
- 在「测试文本」中输入内容，点击搜索引擎右侧「搜索」验证效果。

URL 模板需要满足：

1. 包含 `%s` 占位符；
2. 以协议开头，例如 `https://`。

示例：

| 名称 | URL 模板 |
| --- | --- |
| 百度 | `https://www.baidu.com/s?wd=%s` |
| 必应 | `https://www.bing.com/search?q=%s` |
| Google | `https://www.google.com/search?q=%s` |
| DuckDuckGo | `https://duckduckgo.com/?q=%s` |
| GitHub | `https://github.com/search?q=%s` |

### 2. 从文本选择菜单搜索

在任意应用中选中文字 → 打开系统文本选择菜单 → 选择「搜索」→ 选择「文本选择搜索」→ 选择搜索引擎。

### 3. 从分享面板搜索

选中或分享文字 → 打开系统分享面板 → 选择「ShareRunner」→ 选择搜索引擎。

> 菜单中显示的名称取决于系统与调用方应用；搜索入口是否出现，取决于系统版本及该应用是否提供「搜索」菜单项。

## 项目结构

```text
.
├── AppScope/                      # 应用级配置与图标
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/      # 应用主入口
│       │   ├── searchability/     # 文本选择菜单搜索入口
│       │   ├── shareext/          # 分享面板扩展
│       │   ├── pages/             # Index / SearchPicker / SharePicker
│       │   ├── model/             # 搜索引擎模型与本地存储
│       │   └── common/            # 沉浸式窗口与安全区处理
│       ├── module.json5           # Ability / Extension 声明
│       └── resources/             # 字符串、颜色、图标等资源
├── build-profile-example.json5    # 签名配置示例（占位符）
└── build-profile.json5            # 本地签名配置（已 gitignore）
```

## 构建与运行

### 环境要求

- DevEco Studio（需支持 HarmonyOS SDK 26.0.0）
- HarmonyOS SDK 26.0.0
- HarmonyOS 设备或模拟器（API 26）

### 首次构建

仓库不包含根目录的 `build-profile.json5`（其中通常含有本机签名信息，已加入 `.gitignore`）。首次克隆后：

```bash
cp build-profile-example.json5 build-profile.json5
```

然后在 DevEco Studio 中配置签名：

- 推荐使用 DevEco Studio 的自动签名：`File` → `Project Structure` → `Signing Configs`，登录华为账号后生成；
- 或手动编辑 `build-profile.json5`，将示例中的证书、Profile、keystore 路径和密码替换为本机配置。

最后连接设备或模拟器，运行 `entry` 模块。

> `build-profile.json5` 包含签名凭据，请勿提交到版本库。

## 实现说明

- **技术栈**：ArkTS / ArkUI，Stage 模型。
- **搜索入口**：`SearchAbility` 处理 `ohos.want.action.search`，依次尝试从 `query`、`key_text`、`text`、`selectedText`、`keyword`、`content`、`searchText` 参数中读取文本，最后回退到 `uri`。
- **分享入口**：`ShareExtAbility` 处理 `ohos.want.action.sendData`，从共享记录的 `content`、`title`、`uri` 中提取文本。
- **URL 生成**：对文本执行 `trim()` 和 `encodeURIComponent()`，替换模板中的所有 `%s`。
- **配置存储**：使用 `@kit.ArkData` 的 `preferences`，存储名为 `sharerunner_skills`。
- **打开方式**：通过 `openLink` 交给系统处理，由系统决定使用哪个浏览器或应用打开。

## 隐私说明

- 搜索引擎配置仅保存在本机。
- 选中的文字仅用于拼接搜索 URL，并随 URL 交给所选的搜索引擎；应用本身不收集、不上传文本。
- 应用未声明网络权限，不包含统计或广告 SDK。

## 已知限制

- 分享扩展目前只处理纯文本（`general.text`），图片和文件分享暂不支持。
- 仅支持通过 URL 模板发起搜索，不支持 POST 或需要登录态的搜索接口。
- 搜索结果页面由系统浏览器或对应 App 打开，本应用不提供内置浏览器。

## 发布前注意

- 当前 `bundleName` 为占位值 `com.example.sharerunner`，正式发布前请修改为自有包名。
- 请替换应用图标、应用名称和签名配置。
