# 酒狐 Minecraft 服务器

酒狐主题服（女仆 + 酒馆玩法）的服务器工作目录：Minecraft 1.21.1 + NeoForge 21.1.267 + Java 21。

**关于版本管理**：本目录是服务器的实际运行/工作目录。Git 仓库（init、commit、push）由维护者自己在仓库侧操作，本目录不绑定远程仓库。本目录内 prepared 的以下三份文件，就是为了让下次把配置入库时干净、可复现：

- `.gitignore`：排除不该入库的内容（见下）
- `mods-manifest.txt`：mods 全量清单，代替大而散的 jar 入库
- `config/touhou_little_maid/sites/llm.json.template`：女仆 AI 配置模板，代替含 key 的真配置入库

## 目录结构

- `mods/`：服务器模组 jar（66 个，**不入 Git**，由 `mods-manifest.txt` 登记）
- `mods-manifest.txt`：清单（文件名 | SHA1 | 来源），59 个 Modrinth + 7 个手动下载
- `config/`、`defaultconfigs/`：模组配置（含 FTB 任务书 `config/ftbquests/quests/`）
- `config/touhou_little_maid/sites/llm.json.template`：AI 站点配置模板
- `server.properties`：服务器配置
- `user_jvm_args.txt`：JVM 参数（当前最大堆内存 6 GB）
- `start.sh` / `start.bat`：Linux / Windows 启动脚本
- `进服指南.md`：玩家进服及玩法指南

## 不入库的内容（.gitignore）

- `world/`、`backups/`、`logs/`、`crash-reports/`：存档、备份与运行日志，各自服务器本地保存备份。
- `ops.json`、白名单/封禁名单、用户缓存：每台服务器的玩家管理状态，不共享。
- `libraries/`、NeoForge 安装器：可用官方安装器重建。
- `mods/`：jar 大且散，入库只放 `mods-manifest.txt`。
- `config/touhou_little_maid/sites/llm.json`：可能含 API key；入库的是同目录 `llm.json.template`。

## 用 mods-manifest.txt 恢复 mods

在新机器或 jar 丢失时，按清单恢复（共 66 个）：

1. 来源列为 `Modrinth: <slug>` 的模组：打开 `https://modrinth.com/mod/<slug>`，下载与清单中同版本的 NeoForge 1.21.1 文件，放入 `mods/`。
2. 来源列为「手动下载」的（FTB 系列与若干未上架模组）：到 CurseForge 或对应发布页手动下载。
3. 校验：`sha1sum mods/<文件名>`（Windows：`Get-FileHash -Algorithm SHA1`）应与清单中的 SHA1 一致。
4. 新增/更换 mod 后，同步更新 `mods-manifest.txt`，保持清单与实际一致。

## 启动

- Linux：`chmod +x start.sh && ./start.sh`
- Windows：双击 `start.bat`

首次运行需先安装 NeoForge 21.1.267 服务端（`java -jar neoforge-21.1.267-installer.jar --installServer`，安装器不入库），并确认 `eula.txt` 已接受。

## 女仆 AI 配置（llm.json）

真配置 `config/touhou_little_maid/sites/llm.json` 含 API key，不入 Git。新环境恢复步骤（详见模板内注释）：

1. 复制 `llm.json.template` 为同目录 `llm.json`。
2. 在要用的站点（如 deepseek）填入 `"secret_key"`，把 `"enabled"` 改为 `true`。
3. 重启服务器生效。

切勿把带 key 的 llm.json 提交到任何仓库。

## 客户端整合包

仓库保存客户端配置、资源包、光影、设置模板（`client/`）与全量 mod 清单（`client/client-mods-manifest.txt`：文件名 | SHA1 | 来源）；官方 Minecraft 游戏文件、游戏库及 mod jar 本体不提交，打包时按清单获取。打包用 `scripts/pack-client.ps1` 本地一键完成，发布流水线由维护者自建（可参照该脚本逻辑）。

NeoForge 服务端要求连接的客户端也安装 NeoForge；未安装 NeoForge 的原版客户端会在握手阶段被拒绝。因此客户端联机测试必须启动真正的 NeoForge 客户端，普通协议机器人不等同于真实模组客户端。

## 手动部署（当前可用）

CI/CD 自动化仍在建设中，当前继续使用人工部署：

1. 在服务器控制台执行 `stop`，等待进程完全退出。
2. 备份云服的 `world/` 和需要保留的服务器本地数据。
3. 更新维护者的 Git 工作副本，再将需要部署的配置/模组文件复制到服务器。不要用整目录同步覆盖云服。
4. 只在 NeoForge 版本变化时重新安装对应服务端，并确认 `libraries/net/neoforged/neoforge/21.1.267/unix_args.txt` 等启动文件存在。
5. 启动服务器并检查 `logs/latest.log`。玩家数据、名单、密钥、世界和备份继续由服务器本地维护。

## CI/CD（建设中）

完整设计、当前限制和后续阶段见 [CI-CD-PLAN.md](./CI-CD-PLAN.md)。

当前服务器 CI（`.github/workflows/ci.yml`）在 Pull Request、push 和手动触发时运行：

- 检查 shell 脚本语法、启动所需文件、模组清单格式与哈希格式，以及 JSON/JSON5/TOML 配置语法；运行校验器单元测试。
- **GitHub Actions 暂不运行服务端启动、客户端启动或客户端加入测试。** 之前的无模组 NeoForge bootstrap 不能代表真实模组服，而且会增加 CI 运行时间；完整开服和联机验收改由开发者在本地使用实际模组包完成。

本地复现静态检查（Python 3.11+）：

```sh
python -m pip install -r requirements-ci.txt
python scripts/ci_validate.py
python -m unittest discover --start-directory tests --pattern "test_ci_validate.py"
```

本地已有 `mods/` 时，可额外核对每个 JAR 与 manifest 中的 SHA1：`python scripts/ci_validate.py --check-local-mods`。

### 本地手动验收（服务端与客户端）

每次修改服务端/客户端模组、配置或版本后，在本地用实际整合包做以下验收。使用临时测试目录和新世界，不要直接使用生产服务器目录或生产世界：

1. 确认服务端与客户端均为 Minecraft 1.21.1、NeoForge 21.1.267，并准备好对应的完整模组包。服务端本地有 `mods/` 时，先运行 `python scripts/ci_validate.py --check-local-mods` 检查 JAR 是否匹配服务端清单。
2. 在隔离的临时服务端目录中启动实际 NeoForge 服务端，观察 `logs/latest.log`，确认完成启动且没有模组加载失败或持续崩溃；保持服务端运行以供客户端连接。
3. 使用 PCL 启动匹配的 NeoForge 客户端，确认客户端能进入主菜单且没有模组加载错误。
4. 从该客户端连接正在运行的测试服务端，确认握手成功并进入世界；简单移动、交互，并按本次变更测试相关模组功能。测试结束后正常退出客户端，再正常停止服务端。
5. 记录测试使用的 Minecraft/NeoForge 版本、模组清单状态和失败现象。日志可能含玩家 IP 或其他本地信息，不要未经检查就提交或外传。

后续目标流程：

1. 在本地持续执行上面的真实模组服与客户端联机验收；只有当完整模组包可被稳定、合法地复现，且自动化确实带来价值时，再考虑恢复 CI 服务端冒烟或增加客户端端到端测试。
2. 规划受保护的手动部署 workflow：触发后需环境审批，部署前备份，只同步明确允许的文件，部署后检查健康状态并保留回滚方式。

自动服务端启动测试、客户端联机测试和自动 CD 当前均未启用；人工测试与人工部署流程仍是当前操作依据。

流程设计参考：

- [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)：NeoForge 容器安装和固定版本测试样例。
- [mc-modpack-template](https://github.com/Furglitch/mc-modpack-template/blob/main/.github/workflows/modpack-build.yml)：Packwiz 分别导出客户端与服务端包。
- [NeoForge 1.21.x NetworkRegistry](https://github.com/neoforged/NeoForge/blob/1.21.x/src/main/java/net/neoforged/neoforge/network/registration/NetworkRegistry.java)：客户端/服务端 modded 握手实现。

## 协作注意事项

- `world/` 不共享：各自维护本地存档与备份，绝不提交或覆盖他人的 world。
- 备份、日志不入 Git，在各服务器上单独保存。
- `server.properties` 当前 `online-mode=false` 且白名单关闭（离线模式），公开部署前确认访问控制方案；日志含玩家 IP，勿提交或外传。

## 协作者操作流程

任务认领方式、状态定义和迁移到 GitHub Issues 的规则见 [协作任务清单.md](./协作任务清单.md)。

### 获取并启动客户端

1. 向维护者获取当前确认可用的客户端整合包 ZIP（可由维护者用 `scripts/pack-client.ps1` 打包生成，或自建流水线发布）。
2. 确认整合包对应 Minecraft 1.21.1 和 NeoForge 21.1.267。在 PCL 中使用独立版本目录，将 ZIP 内的 `mods/`、`config/`、`resourcepacks/`、`shaderpacks/` 和可选的 `options.txt` 解压到该目录。`options.txt` 会覆盖本地设置；不需要时可不复制。
3. 从 PCL 启动该 NeoForge 版本，先确认能进入主菜单且没有模组加载错误。原版客户端不能加入 NeoForge 服务端。

### 本地测试服务端和联机

修改模组、配置或版本后，按上方“本地手动验收（服务端与客户端）”执行完整测试：使用隔离目录和新世界启动完整服务端，再由匹配的 NeoForge 客户端连接并进入世界。不得使用生产服目录或生产世界测试。

### 提交协作变更

1. 从最新主分支创建自己的分支，只提交需要共享的配置、清单、脚本或文档；不要提交 `mods/` 中的 JAR、世界存档、备份、日志、玩家资料或含密钥的配置。
2. 本地运行静态校验和单元测试：

   ```powershell
   python scripts\ci_validate.py
   python -m unittest discover --start-directory tests --pattern "test_ci_validate.py"
   ```

   本机有完整服务端 `mods/` 时，再运行 `python scripts\ci_validate.py --check-local-mods`。
3. 若变更涉及模组或配置，完成前述本地开服、客户端启动和加入测试。在 Pull Request 中说明改了什么、使用的 Minecraft/NeoForge 版本及测试结果；GitHub CI 只做静态校验，不会替代这些本地测试。
4. 由维护者审核并负责生产部署。协作者不要直接覆盖生产服务器文件或世界；部署前备份和部署操作按“手动部署”一节执行。

### 客户端包的维护状态

`client/` 保存客户端配置、资源包、光影、设置模板与 `client/client-mods-manifest.txt`（mod 清单，已入库）。`scripts/pack-client.ps1` 按清单从本机版本目录复制现成 jar，缺失项从 Modrinth 下载并校验 SHA1；来源为「手动下载」且本地缺失的 mod 会警告并跳过，发布前维护者必须确认没有缺项，并核对 JAR 与清单哈希。

### 协作：改客户端内容的标准流程

**场景 A：加 mod**

1. 把 jar 放到任意位置，运行 `powershell -File scripts\add-client-mod.ps1 -Jar <jar 路径>`。脚本自动算 SHA1 并经 Modrinth API 反查来源：
   - Modrinth 上架的 mod → manifest 追加 `Modrinth: <slug>` 行；**jar 本体不入 Git**，别人打包时按 SHA1 自动下载。
   - 非 Modrinth 的 mod → jar 自动复制到 `client\manual-mods\`（随仓库分发），manifest 追加「手动下载」行。
2. 自己执行 `git add` / `git commit` / `git push`（脚本结尾会打印具体命令提示）。
3. manifest 中已有同名条目时脚本会提示并退出，不重复登记。

**场景 B：改共享配置**

直接修改 `client\config\`（或 `resourcepacks\`、`shaderpacks\`、`options.txt.template`）下的对应文件，然后 `git add` / `git commit` / `git push`。这些文件整体随仓库分发，打包时整目录复制进 zip。

**场景 C：出 zip**

双击 `scripts\pack-client.bat`（或命令行运行 `powershell -File scripts\pack-client.ps1`，两者等价），产物为 `dist\酒狐客户端_<日期>.zip`，可直接发给不便用 git 的朋友（注意 `dist\` 不入库）。打包顺序：PCL 版本目录现成 jar → `client\manual-mods\` → Modrinth 按 SHA1 下载。

拉取更新后（`git pull`），重跑一次 `pack-client.ps1` 即得最新客户端包。

