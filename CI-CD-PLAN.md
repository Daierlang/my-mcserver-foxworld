# 酒狐 MC 服务器 CI/CD 流程

本文记录当前流程、已实现的检查和后续建设目标。自动化仍在建设中；生产环境继续以人工部署流程为准。

## 目标与边界

- 为 Minecraft 1.21.1 + NeoForge 21.1.267 服务器配置建立可复现的 CI/CD 流程。
- CI 在隔离的临时目录或容器中运行，不读取、上传、修改或覆盖生产 `world/`、`backups/`、玩家名单及日志。
- 把“服务端启动成功”和“真实 NeoForge 客户端成功加入”作为不同级别的测试。
- 后续 CD 采用受保护的手动触发和环境审批，不采用 PR 或合并后自动部署。
- 自动化未验证前不取代人工部署；备份、回滚和部署目录保护方案确认后才部署到生产环境。

## 仓库现状与限制

- 仓库主要包含服务器配置和模组清单，没有 Gradle/Maven 源码构建项目。
- `libraries/`、NeoForge 安装器和 `mods/` 被 `.gitignore` 排除；干净 checkout 中没有服务端模组 JAR。
- `mods-manifest.txt` 记录了 66 个模组的文件名与 SHA1，但其中 12 个标为手动下载，目前没有 CI 可直接使用的下载地址。
- `client/` 目前保存客户端配置和模板，没有完整启动器 profile 或客户端模组 JAR；也没有可靠的客户端/服务端 mod side 清单。
- 仓库为公开 GitHub 仓库。客户端分发优先使用可复现的 manifest/profile；只有确认允许再分发的模组 JAR 才考虑入库。官方 Minecraft 游戏客户端和游戏库不提交。
- NeoForge 1.21.x 会拒绝未运行 NeoForge 的 vanilla 客户端。因此普通原版客户端或 vanilla 协议机器人不能替代真正的 NeoForge 客户端联机测试。

## CI 流程

### 阶段 1：PR 快速校验（已实现）

Pull Request、push 和手动触发时运行：

- 使用 `bash -n` 检查仓库内 shell 脚本。
- 检查启动脚本引用、EULA、必需文件和模组清单格式，包括 SHA1 格式、重复项及声明数量。
- 检查 JSON/JSON5/TOML 配置语法。
- 对有本地 `mods/` 的环境，可使用 `python scripts/ci_validate.py --check-local-mods` 对照清单校验全部 JAR SHA1；GitHub clean checkout 不包含这些 JAR，因此 CI 不会声称验证了模组二进制。

### 阶段 2：本地真实服务端与客户端验收（当前手动）

GitHub Actions 暂不运行 NeoForge bootstrap、完整模组服启动或客户端加入测试。之前设计的 bootstrap 不包含模组，只能证明干净 NeoForge 服务端启动；它不能代替真实模组服验收，且会增加 CI 时间。开发者应在本地使用实际整合包和临时测试世界完成验收，步骤见 README 的“本地手动验收（服务端与客户端）”。

本地验收包括：核对服务端 JAR 与 manifest SHA1；在隔离目录启动完整服务端并确认成功启动、无模组加载失败；启动对应 NeoForge 客户端；从客户端连接测试服并确认进入世界，再验证与改动相关的功能。不得使用生产世界做测试。

若将来考虑恢复自动化，应先具备所有模组的稳定、版本固定、合法下载来源并验证 JAR 哈希；客户端自动化还需证明客户端运行、测试账号/认证策略及连接流程在 CI runner 上稳定。单纯服务器启动、ping 或 vanilla bot 连接均不能作为完整客户端联机测试。

## CD 流程（待建设）

当前可用流程仍是人工部署：

1. 在服务器控制台执行 `stop`，等待进程完全退出。
2. 备份云服的 `world/` 和需要保留的服务器本地数据。
3. 更新维护者的 Git 工作副本，再只复制需要部署的配置/模组文件；不要用整目录同步覆盖云服。
4. 只在 NeoForge 版本变化时重新安装对应服务端。
5. 启动服务器并检查 `logs/latest.log`；世界、名单、密钥和备份继续由服务器本地维护。

未来自动化的约束：

- 只规划受保护的手动 `workflow_dispatch`，并使用 GitHub Environment 审批。
- 部署不可变且已验证的版本包；SSH 凭据不能暴露给 PR workflow。
- 只同步明确允许的文件，禁止覆盖 `world/`、`backups/`、名单、日志及服务器本地 secrets。
- 部署前备份，部署后检查健康状态；失败时保留日志并回滚文件版本。
- 没有可验证的回滚方案前不开启合并后自动部署。

## 参考实践

- [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)：NeoForge 容器安装和固定版本测试样例。
- [mc-modpack-template](https://github.com/Furglitch/mc-modpack-template/blob/main/.github/workflows/modpack-build.yml)：使用 Packwiz 分别导出客户端与服务端包。
- [GTNewHorizons/DreamAssemblerXXL](https://github.com/GTNewHorizons/DreamAssemblerXXL/blob/master/.github/workflows/daily-modpack-build.yml)：以 manifest 组装客户端/服务端产物，并拆分构建、测试和发布阶段。
- [BentoBoxWorld/Challenges E2E workflow](https://github.com/BentoBoxWorld/Challenges/blob/master/.github/workflows/e2e.yml)：Paper 服务端 + Mineflayer 的较重 E2E 设为手动运行；此插件生态案例不代表 Mineflayer 能加入 NeoForge。
- [NeoForge 1.21.x NetworkRegistry](https://github.com/neoforged/NeoForge/blob/1.21.x/src/main/java/net/neoforged/neoforge/network/registration/NetworkRegistry.java)：说明未运行 NeoForge 的客户端会被网络协商拒绝。
- [NotQuests E2E workflow](https://github.com/AlessioGr/NotQuests/blob/master/.github/workflows/e2e.yml)：区分服务端命令测试与客户端测试。
