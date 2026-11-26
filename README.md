# 酒狐 Minecraft 服务器

酒狐服务器配置仓库，用于通过 GitHub 管理服务器配置与模组，并在 Linux 云服务器上部署。

## 服务器版本

- Minecraft：1.21.1
- NeoForge：21.1.267
- Java：21

## 仓库内容

- `mods/`：服务器模组
- `config/`、`defaultconfigs/`：模组及新世界默认配置
- `server.properties`：服务器配置
- `user_jvm_args.txt`：JVM 参数（当前最大堆内存 6 GB）
- `start.sh`：Linux 启动脚本
- `进服指南.md`：玩家进服及玩法指南

世界存档、备份、日志和玩家/管理名单等运行数据不会纳入 Git。云服上的 `world/` 是实际运行存档；更新仓库时不要删除或覆盖它。备份请在云服务器上单独保存，不要把备份当作 Git 部署内容。

## 首次部署（Linux）

1. 安装 Java 21，并确保云服务器有足够内存。当前 JVM 参数最大堆内存为 6 GB。
2. 克隆仓库：

   ```sh
   git clone <仓库地址>
   cd <仓库目录>
   ```

3. 获取 NeoForge 21.1.267 服务端安装器，并在仓库目录运行安装器：

   ```sh
   java -jar neoforge-21.1.267-installer.jar --installServer
   ```

   安装器 JAR 和生成的 `libraries/` 不保存在仓库中。安装完成后，确认 `libraries/net/neoforged/neoforge/21.1.267/unix_args.txt` 已生成。

4. 确认已阅读并接受 Minecraft EULA；仓库中的 `eula.txt` 当前设置为 `eula=true`。
5. 设置启动脚本权限并启动：

   ```sh
   chmod +x start.sh
   ./start.sh
   ```

首次启动会在服务器目录生成世界和运行数据。自动化安装/部署脚本尚未提供，NeoForge 安装步骤目前需要手动执行。

## 更新部署

每次从本地推送更新后，在云服按以下流程操作：

1. 在服务器控制台输入 `stop`，等待服务器完全关闭。
2. 备份云服的世界和重要配置。
3. 在仓库目录拉取更新：

   ```sh
   git pull --ff-only
   ```

4. 如果 NeoForge 版本有变化，重新安装对应版本并确认启动参数文件存在。
5. 启动服务器：

   ```sh
   ./start.sh
   ```

更新模组或配置前务必先停服。尽量把需要长期保留的配置改动提交回仓库；否则云端手动改过的配置可能在拉取时产生冲突或被后续更新覆盖。

## 不纳入 Git 的运行数据

`.gitignore` 会排除 `world/`、`backups/`（保留说明文件）、日志、NeoForge 生成的依赖文件，以及 `ops.json`、白名单/封禁名单和玩家缓存。这些数据需要在云服单独维护和备份。首次部署后，可通过服务器控制台设置管理员和玩家权限。

## 安全提醒

当前 `server.properties` 使用 `online-mode=false`，并关闭白名单。离线模式无法由 Minecraft 官方账号系统验证玩家身份，公开部署前应确认访问控制方案；不要将管理员账号暴露给不可信玩家。服务器日志可能包含玩家 IP，请勿提交日志或公开分享。
