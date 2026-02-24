# ETS2 Docker 专用服务器

英文版见：[`README.md`](https://github.com/kKsk03/ETS2-Dedicated-Server-Docker/blob/main/README.md)  

需自行准备好完整 `Docker` 环境，方便后续进行直接配置。  

## 部署流程

### 1. 把项目文件放到服务器目录

```bash
mkdir -p /home/ets2_server
cd /home/ets2_server
# 把仓库文件复制到这里，后续命令都在 /home/ets2_server 执行
```

### 2. 创建 `.env`

```bash
cp .env.example .env
```

`.env` 参数说明：

- `TZ` : 容器时区。示例：`Asia/Shanghai`、`UTC`。
- `ETS2_AUTO_UPDATE` : 是否在容器每次启动时自动执行更新。建议设置为 `true`。
- `ETS2_VALIDATE_ON_UPDATE` : 更新时是否加 `validate`。会更慢，但会校验文件完整性。
- `ETS2_BRANCH` : Steam 分支。默认 `public`；需要测试分支时填对应分支名。
- `ETS2_DATA_HOME` : 容器内的数据根目录。默认 `/data/ets2data`，通常不需要改。
- `ETS2_FIX_PERMISSIONS` : 容器启动时自动尝试修复 `/data` 权限。默认 `true`。
- `ETS2_REQUIRE_SERVER_PACKAGES` : 启动前是否强制检查 `server_packages.sii/.dat`。建议设置为 `true`。

### 3. 创建目录并写入初始配置

路径按下面照抄即可：`data/ets2data/Euro Truck Simulator 2`

```bash
mkdir -p "data/ets2data/Euro Truck Simulator 2"
cp "docker/defaults/server_config.sii" "data/ets2data/Euro Truck Simulator 2/server_config.sii"
```

### 4. 在 `ETS2` 游戏中导出依赖文件

1. 打开设置路径  
    一般位于： `C:\Users\<用户名>\Documents\Euro Truck Simulator 2\config.cfg`  
2. 搜索并进行更改：  
    - `uset g_developer "0"` 改为 `uset g_developer "1"`
    - `uset g_console "0"` 改为 `uset g_console "1"`
    然后保存文件
3. 启动游戏，调整好您想要配置的 `Mod`，然后进入存档。  
4. 按 `~` 打开游戏控制台。  
5. 输入执行：`export_server_packages`  
6. 在 `C:\Users\<用户名>\Documents\Euro Truck Simulator 2` 文件夹下可以找到导出的以下两个文件：  
    - `server_packages.sii`  
    - `server_packages.dat`

### 5. 创建 `Steam GSLT`（可选）

> 可以不创建，但是这样会无法固定搜索ID。因此建议创建

1. 打开链接：[Steam GSLT](https://steamcommunity.com/dev/managegameservers)  
2. 登录并创建 `token`，使用游戏 `AppID` : `227300`  
3. 复制生成的 `token` 备用

### 6. 放置依赖文件并修改配置

1. 把 `server_packages.sii` 放到：`data/ets2data/Euro Truck Simulator 2/server_packages.sii`
2. 把 `server_packages.dat` 放到：`data/ets2data/Euro Truck Simulator 2/server_packages.dat`
3. 编辑：`data/ets2data/Euro Truck Simulator 2/server_config.sii`

根据文字意思自行修改配置文件即可，切记如果生成了 `token`，请填写进去。  

### 7. 启动服务

```bash
docker compose up -d --build
```

该指令会开始构建镜像，构建完毕后会进行服务器的启动。  

### 8. 查看日志确认启动

```bash
docker compose logs -f ets2-server
```

当您见到搜索ID出来后，则代表启动成功：  

```bash
[MP] Session search id: xxxxxxxxxxxxx/xxx
[MP] Session name: xxxxxxx
[MP] Session description: xxxxxx
[MP] Maximum number of players: x
[MP] Connection virtual ports: xxx / xxx
[MP] Connection server ports: 27015 / 27016
[MP] Friends only: False
```

## 目录结构

```text
.
|-- Dockerfile
|-- compose.yaml
|-- .env.example
|-- docker/
|   |-- entrypoint.sh
|   `-- defaults/server_config.sii
`-- data/
    |-- server/                     # SteamCMD 自动下载的 dedicated 文件
    `-- ets2data/
        `-- Euro Truck Simulator 2/ # 这是游戏要求的固定目录名
            |-- server_config.sii
            |-- server_packages.sii
            `-- server_packages.dat
```

## 端口映射

默认映射：

- `27015/tcp`
- `27015/udp`
- `27016/udp`

如果你在 `server_config.sii` 修改 dedicated 端口，需要同步修改 `compose.yaml`。

请切记务必要在服务器的防火墙中放行这些端口。  
