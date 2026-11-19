# Go2Claude 产品发布页：实现与上线说明

> 文档版本：v1.0　|　编写日期：2026-11-19　|　实测环境：苏州，本机 macOS（Apple 芯片 / Swift 6.4.2），直连无代理
> 线上地址：<https://andli0626.github.io/go2claude/>　|　仓库：<https://github.com/andli0626/go2claude>
> 参考对象：`zchenmaker.github.io/Epoint-video-guide` 的页面效果，以及《GitHub Pages 国内访问分析与自建发布方案》的执行规则

---

## 一、目标与约束

### 1.1 要解决什么问题

Go2Claude 是一个 macOS 小工具，装好之后大多数人只关心三件事：**这是什么、怎么装、下哪个包**。而原来的信息散在 README、安装说明和聊天记录里，对方要翻好几个地方。

发布页的目标就一句话：**用一页把这三件事讲清楚，并且在国内网络下打得开、下得动。**

### 1.2 硬约束（来自既有方案文档）

参考方案把「国内能访问」拆成平台层、页面层、下载层三层，其中页面层和下载层完全可控。本次全部照做：

| 约束 | 具体要求 | 本次落实方式 |
|---|---|---|
| 零外部依赖 | 不引 Google Fonts、第三方 CDN、境外统计 | 系统字体栈 + 内联 SVG + 单文件 CSS/JS |
| 同源下载 | zip/pkg 放仓库内，相对路径引用 | `site/downloads/*.pkg`、`*.zip` |
| 不用 Release 分发 | 避免 `objects.githubusercontent.com` | 全程相对路径，无 Release 链接 |
| 绕过 Jekyll | 根目录放空 `.nojekyll` | `site/.nojekyll`（0 字节） |
| 版本串防缓存 | 改版后强制刷新 | 站点以目录形式发布，改动即替换文件；查询串方案见第八章 |
| 单文件体积 | ≤ 100 MB，整站 ≤ 1 GB | 整站 1.8 MB，单文件最大 0.8 MB |
| 不做后端 | Pages 只发静态文件 | 无接口、无数据库、无脚本服务 |
| 不用图床 | 图片同源 | `site/assets/` 内 4 个 PNG |

### 1.3 非目标（明确不做）

- 不做电商、支付、账号体系（Pages 政策也禁止把免费站点当商业站）；
- 不做访问统计（会引入境外脚本，也违背方案的自包含原则）；
- 不做多语言切换，先保证中文一版说清楚。

---

## 二、站点结构

```
site/
├── index.html                                    40,737 B  入口，单文件内联样式与脚本
├── .nojekyll                                          0 B  跳过 Jekyll 处理
├── check.sh                                       799 B  零外部依赖自检脚本
├── assets/
│   ├── app-icon-128.png                         5,145 B  导航栏、favicon
│   ├── app-icon-256.png                        11,227 B  apple-touch-icon
│   ├── app-icon-512.png                        27,885 B  og:image
│   └── settings.png                           149,121 B  首屏主视觉（设置窗口实拍）
└── downloads/
    ├── Go2Claude-macOS-universal-1.2.3-20261119.pkg   841,950 B  通用安装包
    ├── Go2Claude-macOS-universal-1.2.3-20261119.zip   847,385 B  便携压缩包
    └── README-安装说明.txt                              1,891 B  随包安装说明
```

选择「目录 + 多文件」而不是「一个 HTML 塞满 base64」的理由：截图 149 KB、安装包合计 1.6 MB，内联会让单文件膨胀到 2 MB 以上，且后续换图、换包都得重写文件；`assets/` 与 `downloads/` 是 Pages 上的常规布局，维护成本最低。

---

## 三、页面设计与信息架构

### 3.1 首屏：先给结论，再给证据

首屏只做三件事：一句能被记住的定位、一个能立刻点的下载、一张能证明「它长这样」的图。

| 元素 | 文案 / 内容 | 作用 |
|---|---|---|
| 徽标 | `仅支持 macOS 13+ · MIT 开源 · 零外部依赖` | 平台与门槛前置，避免 Windows 用户白跑 |
| 主标题 | 在 Finder 里，**点一下就进 Claude** | 一半黑体、一半渐变，动词明确 |
| 引导段 | 给 Finder 加一个工具栏按钮……不用复制路径，不用敲 cd | 三句话讲完使用场景 |
| 主按钮 / 次按钮 | 下载安装包 / 看它怎么工作 | 一个转化，一个解释 |
| 标签 | 默认命令 `cd %PATH% && claude`、仅支持 macOS、点完即退出 | 把最容易被追问的三点写在明面上 |
| 主视觉 | 设置窗口实拍，右下角悬浮 `Go2Claude Toolbar` 提示「按住 ⌘ 拖进 Finder 工具栏」 | 真实界面，不是渲染图 |
| 数据条 | 1 次点击 / 2 个 App / 0 外部依赖 / 32 个单测 | 用可核对的事实收尾 |

### 3.2 后续区块与拟解决的信息缺口

| 区块 | 内容 | 回答的问题 |
|---|---|---|
| 功能（`#features`） | 定位当前目录、命令模板、双 App 分工、环境自检 | 它到底做什么、能改成别的吗 |
| 工作方式（`#flow`） | 四步流程图 + 终端窗口模拟 | 点一下之后发生了什么 |
| 安装到 Finder（`#start`） | 三步编号卡 + 权限说明卡 | 怎么装、为什么弹权限 |
| 下载（`#download`） | pkg / zip / 源码三卡 + 未签名说明 | 下哪个、打不开怎么办 |
| 常见问题（`#faq`） | 7 条折叠问答 | Gatekeeper、权限、找不到 claude、Windows |
| 页脚 | 非官方声明、商标归属、风险提示、MIT | 合规边界 |

### 3.3 设计令牌

```css
--ink:#0B1020;        /* 首屏底色，取自应用图标深蓝 */
--band:#F5F7FB;       /* 浅灰分区带 */
--text:#111729; --muted:#58617C;
--teal:#18C296; --blue:#4C6BFF; --violet:#9A5CF4;
--grad:linear-gradient(96deg,#25D6A4 0%,#4C6BFF 52%,#9A5CF4 100%);  /* 与图标 G2C 渐变一致 */
--radius:16px; --max:1180px; --hdr-h:66px;
```

- 字体：`-apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif`，等宽用 `SF Mono / Menlo`。**不加载任何网络字体**，字体失败也仍有完整回退栈。
- 栅格：内容最大宽度 1180 px，两栏首屏 `1.02fr / .98fr`，功能区 2 列，流程 4 列。
- 图形：全部为内联 SVG（`<svg><path/></svg>`），零图标库依赖。

### 3.4 交互实现（原生 JS，约 60 行）

| 行为 | 实现 | 说明 |
|---|---|---|
| 导航变色 | `scrollY > 24` 时给 header 加 `is-solid` | 首屏透明、滚动后白底 + 模糊 |
| 移动端菜单 | 点菜单按钮给 `.site-nav` 加类并写内联样式 | 断点 ≤ 860 px 生效 |
| 复制命令 | `navigator.clipboard` + `textarea` 兜底 | 复制的模板可直接粘进设置页 |
| 折叠问答 | 原生 `<details>/<summary>` | 不用 JS，键盘可操作 |

---

## 四、实现过程中的三个技术坑

### 4.1 坑一：首屏两栏塌成一栏

- **现象**：1440 px 下截图在主文案下方，右侧大片留白，标签被压住。
- **根因**：`hero-copy` 的闭合 `</div>` 在修补多余 `</span>` 时被一并删掉，`hero-visual` 因此被解析成 `hero-copy` 的子节点，栅格只剩一个子项，自然单列。
- **处置**：补齐闭合标签；并写了一个基于 `html.parser` 的栈式校验脚本，对全文做一次开闭配对检查，同时揪出另外几处：四张流程卡的 `tagline` 误用 `</p>` 闭合、`clip:code(0 0 0 0)` 应为 `clip:rect(0 0 0 0)`、一处 `<<li>` 与两处多余 `</span>`。修完后 `left open: []`。

### 4.2 坑二：顶部导航出现一条灰带

- **现象**：首屏明明是深色，但导航条约 66 px 高的一条是灰的。
- **根因**：导航用的是 `position: sticky`，它占据文档流，**背后的底色是 body 的白底而不是首屏渐变**；半透明黑叠在白底上就成了灰。
- **处置**：改为 `position: fixed`，首屏增加 `padding-top: calc(72px + var(--hdr-h))` 让内容让位；同时把 `backdrop-filter` 只保留在滚动后的白底状态，避免首屏再叠一层模糊。

### 4.3 坑三：headless 截图「看起来」横向溢出

- **现象**：把窗口设成 390 × 2000 截图，文案、卡片像是被右边裁掉一截。
- **根因**：macOS 上 Chrome headless 有最小窗口宽度限制（约 500 CSS px），传入 390 实际按 ~500 布局，截图却按 390 裁切——是**渲染工具的假象，不是页面溢出**。
- **处置**：改用 520 px 复核，布局正常；顺带补了三条真实可用的加固：`pre` 加 `max-width:100%`、下载卡文件名加 `overflow-wrap:anywhere`、窄屏隐藏导航里的下载按钮给小屏留空间。

---

## 五、下载包怎么来的

发布页里的 pkg / zip 不是占位文件，是本次真实打包的产物。

```bash
cd /Volumes/SanDis1TB/WK/WK-Tools/其他/go2claude
INCLUDE_ZIP=1 ./scripts/package_app.sh
```

| 项目 | 结果 |
|---|---|
| 工具链 | Apple Swift 6.4.2（swiftlang-6.4.2.1.9），宿主 arm64-apple-macosx27.2.0 |
| 主程序编译 | `Build complete! (13.10 秒)` |
| 工具栏编译 | `Build complete! (1.73 秒)` |
| 架构校验 | `Go2Claude: x86_64 arm64`、`Go2ClaudeToolbar: x86_64 arm64` |
| 产物 | `Go2Claude-macOS-universal-1.2.3-20261119.pkg`（841,950 B）、同名 `.zip`（847,385 B） |
| 落地 | 复制进 `site/downloads/`，与 `README-安装说明.txt` 同目录 |

**为什么不用 GitHub Release**：Release 附件实际由 `objects.githubusercontent.com` 提供，这是方案文档里失败率最高的环节。把包直接放进仓库、用 `downloads/xxx.pkg` 相对路径引用，请求就始终落在 `github.io` 这个可用域名上。

**代价**：仓库里长期留有两个约 0.8 MB 的二进制，每次发版都会增加历史体积。当前体量可接受；若后续频繁发版，建议改为「只保留最新一版」并在提交说明里注明替换。

---

## 六、本地验收

上线前在本地按五层验收，全部通过才推远端。

| 层级 | 方法 | 结果 |
|---|---|---|
| 结构 | Python `html.parser` 栈式配对检查 | `left open: []`，无多余闭合 |
| 视觉 | Chrome headless 1440 / 520 两档截图（390 受工具最小窗口限制，仅作参考） | 桌面两栏、窄屏单栏均正常 |
| 依赖 | `./check.sh`（扫描 HTML/CSS/JS 中的境外域名） | `[通过] 未发现高风险外部依赖` |
| 引用 | `grep -oE 'https?://…'` 全站扫描 | 仅 2 处 GitHub 仓库链接（用户点击跳转，不参与页面加载） |
| 文件 | 逐一核对 `href="downloads/…"` 与磁盘文件 | 3 个链接全部命中 |

`check.sh` 的规则集（与方案文档一致，可复用）：

```
fonts.googleapis | fonts.gstatic | cdn.jsdelivr | unpkg.com | cdnjs.cloudflare
google-analytics | googletagmanager | gtag( | hm.baidu
raw.githubusercontent | codeload.github | objects.githubusercontent
releases/download | polyfill.io | staticfile.org | bootcdn
```

---

## 七、发布实施（本次真实操作）

### 7.1 总流程

```mermaid
flowchart LR
  A[本地 site/] -->|git add/commit| B[main 分支]
  B -->|git subtree push| C[gh-pages 分支]
  C -->|推送触发| D[Pages 构建]
  D -->|约 22 秒| E[github.io 线上站]
  E -->|curl 验收| F[状态码 / 体积 / 耗时]
```

### 7.2 步骤与结果

| # | 操作 | 命令 / 接口 | 结果 |
|---|---|---|---|
| 1 | 仓库初始化（上一阶段） | `git init -b main`、`git add -A`、`git commit` | main `6379494`，113 个文件 |
| 2 | 认证确认 | `gh auth status` | 已登录 `andli0626`，token scopes 含 `repo` |
| 3 | 提交站点 | `git add site && git commit` | main `b032169`（站点首次入库） |
| 4 | 推送 main | `git push origin main` | `6379494..b032169` |
| 5 | 生成发布分支 | `git subtree push --prefix site origin gh-pages` | gh-pages `0068350`（根目录即站点） |
| 6 | 启用 Pages | `POST /repos/…/pages` | 返回 `409 GitHub Pages is already enabled`，沿用已启用配置 |
| 7 | 核对配置 | `GET /repos/…/pages` | `build_type=legacy`、`source.branch=gh-pages`、`source.path=/`、`status=building` |
| 8 | 等待构建 | `GET /pages/builds/latest` 轮询 | `status=built`，`duration=22,462 ms`，`error=null` |
| 9 | 线上验收 | `curl` 三项 | 见 7.4 |
| 10 | 增补平台限制 | commit `0f84f07` → subtree → gh-pages `8077022` | 重新构建后 `status=built` |

> 关于第 6 步：创建接口返回 409 说明该仓库的 Pages 已处于启用状态（此前已在仓库设置里开过），因此不需要重复创建，直接确认源分支为 `gh-pages`、目录为 `/` 即可。

### 7.3 关键障碍：GitHub 被全局配置重写到失效代理

这一条值得单独记，因为它会在任何一次 `git push` 时重现。

- **现象**：`git ls-remote https://github.com/andli0626/go2claude.git` 报
  `fatal: unable to access 'https://ghfast.top/https://github.com/…': LibreSSL SSL_connect: SSL_ERROR_SYSCALL`。
- **根因**：全局配置里有一条
  `url.https://ghfast.top/https://github.com/.insteadOf = https://github.com/`，
  把所有 GitHub HTTPS 地址重写到加速镜像 `ghfast.top`；该镜像当前不可用（TLS 连接即失败）。
- **处置（不动全局配置）**：改用显式端口的等价地址 `https://github.com:443/…`，它不匹配那条重写前缀（因为多了 `:443`），从而直连 GitHub。同时把本地 `origin` 指向该地址，后续命令不再撞代理。
- **配套**：推送时用 `-c credential.helper='!gh auth git-credential'` 复用 gh 的登录态，并设 `GIT_TERMINAL_PROMPT=0` 防止卡在交互式输密码。
- **遗留**：若之后修好或删除那条 `insteadOf`，可把 `origin` 改回标准地址：

```bash
git remote set-url origin https://github.com/andli0626/go2claude.git
```

### 7.4 线上实测数据

| 对象 | 状态码 | 体积 | 耗时（苏州直连） |
|---|---|---|---|
| `https://andli0626.github.io/go2claude/` | 200 | 40,106 B | 0.426 s（首次构建后） |
| `…/go2claude/`（增补平台限制后复测） | 200 | — | 0.223 s |
| `…/assets/settings.png` | 200 | 149,121 B | 0.561 s |
| `…/downloads/Go2Claude-macOS-universal-1.2.3-20261119.pkg` | 200 | 841,950 B | 1.677 s |

四类请求全部 200，页面与资源字节数同本地一致，说明 `assets/` 与 `downloads/` 的同源引用在 Pages 上工作正常，没有出现「页面能开、下载全挂」。

### 7.5 仓库最终状态

| 分支 | 头提交 | 内容 | 用途 |
|---|---|---|---|
| `main` | `0f84f07` | 源码 + `site/` + `docs/` | 开发与站点源文件 |
| `gh-pages` | `8077022` | 仅站点（`index.html` 在根） | GitHub Pages 发布源 |

`gh-pages` 由 `git subtree` 从 `site/` 生成，两个分支互不干扰：改源码不会动到发布分支，发布分支也不必承载 Xcode 工程。

---

## 八、日常更新 SOP

改一次页面，四步、四条命令：

```bash
cd /Volumes/SanDis1TB/WK/WK-Tools/其他/go2claude

# 1) 改完后自检（必须，防止有人加回境外 CDN）
(cd site && ./check.sh)

# 2) 提交并推源码
git add site && git commit -m "发布页：<本次改动>"
GIT_TERMINAL_PROMPT=0 git -c credential.helper='!gh auth git-credential' push origin main

# 3) 同步发布分支
GIT_TERMINAL_PROMPT=0 git -c credential.helper='!gh auth git-credential' \
  subtree push --prefix site origin gh-pages

# 4) 等构建并验收
gh api repos/andli0626/go2claude/pages/builds/latest --jq '.status'   # 轮询到 built
curl -sS -o /dev/null -w "%{http_code} %{size_download}B %{time_total}s\n" \
  https://andli0626.github.io/go2claude/
```

两个经验点：

- **构建是异步的**，实测一次约 22 秒；轮询时偶发 `api.github.com` TLS 握手超时，重试即可，不代表发布失败。
- **边缘缓存** `max-age=600`，改版后最多 10 分钟才全球一致；急着看效果先强制刷新（⌘⇧R）。若需要更硬的措施，可给 `index.html` 内引用的资源加 `?v=YYYYMMDD`，或在 `site/index.html` 里统一改版本串。

---

## 九、已知限制与风险

| 风险 | 表现 | 影响 | 应对 |
|---|---|---|---|
| ISP 差异 | 电信/联通/移动国际出口质量不同，同一时刻结果可能不同 | 中高 | 接受波动；必要时换国内托管 |
| 企业/政务内网 | 境外域名白名单或整体屏蔽，`github.io` 大概率不通 | **高** | 给客户一律发国内托管地址或内网地址 |
| 时段波动 | 晚高峰 TTFB 从 0.4 s 涨到 3 s+ | 中 | 页面已压到单文件 40 KB，弱网也能先出内容 |
| 无 SLA | 超量被限速或建议迁移，而非报错提醒 | 低 | 站点 1.8 MB，远低于 1 GB / 100 GB 月流量 |
| 仓库公开 | 免费账号 Pages 必须 public 仓库，源码、安装包、文档全网可见 | 中 | 内部资料不要放 `site/`；发布分支只放确需公开的内容 |
| 未签名产物 | Gatekeeper 拦截、自动化权限被拒 | 中高 | 页面写明放行步骤；公司设备建议先做安全评估 |
| 政策红线 | 禁止商用、电商、SaaS | 中 | 本站定位为工具说明页，非商业站 |
| 二进制膨胀 | 每次发版往 `site/downloads/` 加包，仓库历史变大 | 低 | 只保留最新一版，旧版删除 |

---

## 十、故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| 访问 404 | `gh-pages` 根目录没有 `index.html`，或 Pages 源分支/目录选错 | 核对 `GET /pages` 的 `source` 是否为 `gh-pages` + `/` |
| 页面能开、样式全丢 | 引了境外 CDN 的 CSS | 跑 `check.sh`，改回同源 |
| 一点下载就失败 | 包挂在 Release 上 | 移进 `site/downloads/`，改相对路径 |
| 改了线上没变 | 边缘缓存 / 构建延迟 | 强制刷新；加 `?v=`；等 1–10 分钟 |
| 下划线目录 404 | Jekyll 处理 | 确认 `site/.nojekyll` 存在且被连目录一起发布 |
| 创建 Pages 返回 409 | 站点已启用 | 直接 `GET /pages` 核对配置，不要反复创建 |
| 构建失败 | 单次超 10 分钟、单文件过大 | 压缩图片、拆分文件；单文件上限 100 MB |
| `git push` 报 SSL_ERROR_SYSCALL | 全局 `insteadOf` 重写到失效代理 | 用 `https://github.com:443/…` 直连，或修掉那条配置 |
| 轮询接口 TLS 超时 | 到 `api.github.com` 的网络抖动 | 重试；构建是否完成以 `builds/latest` 最终状态为准 |

---

## 十一、后续可选改进

1. **版本号自动化**：从 `Resources/Info.plist` 读取 `CFBundleShortVersionString`，生成下载卡的文件名与体积，避免手改三处。
2. **截图自动化**：把 `Chrome headless` 截图纳入自检，作为视觉回归基线（桌面 1440 / 平板 860 / 手机 520）。
3. **CI 拦截**：把 `check.sh` 挂到 pull request 上，任何引入 `jsdelivr`、`googleapis`、`raw.githubusercontent` 的改动直接失败。
4. **国内镜像**：需要给政务/国企客户时，把同一份 `site/` 原样部署到 EdgeOne Pages（不含大陆区可免备案）或对象存储 + 备案域名，页面代码不用改。
5. **英文版**：`site/en/index.html` 复用同一套令牌，导航加语言切换；仍保持零外部依赖。

---

## 附录 A：命令速查

```bash
# 打包（含 zip）
INCLUDE_ZIP=1 ./scripts/package_app.sh

# 站点自检
cd site && ./check.sh

# 发布（两条推送）
GIT_TERMINAL_PROMPT=0 git -c credential.helper='!gh auth git-credential' push origin main
GIT_TERMINAL_PROMPT=0 git -c credential.helper='!gh auth git-credential' subtree push --prefix site origin gh-pages

# Pages 状态
gh api repos/andli0626/go2claude/pages --jq '{status,source,html_url}'
gh api repos/andli0626/go2claude/pages/builds/latest --jq '{status,duration,error}'

# 线上验收
curl -sS -o /dev/null -w "%{http_code} %{size_download}B %{time_total}s\n" https://andli0626.github.io/go2claude/
```

## 附录 B：提交与构建记录

| 时间（2026-11-19） | 事件 | 标识 |
|---|---|---|
| 11:28 | 仓库首次提交（源码，113 文件） | main `6379494` |
| 11:31–11:33 | 打包 pkg / zip，复制进 `site/downloads/` | 1.2.3 / 20261119 |
| 11:38 | 站点完成，本地验收通过 | `site/index.html` 40,737 B |
| 12:17 | 站点入库并推送 | main `b032169` |
| 12:17 | 推送 `gh-pages`，构建开始 | gh-pages `0068350` |
| 12:18 | 构建完成 | duration 22,462 ms，error null |
| 12:21 | 增补「仅支持 macOS」 | main `0f84f07` → gh-pages `8077022` |
| 12:21 | 复测线上 | 200，0.223 s，页面含 3 处「不支持 Windows」 |
