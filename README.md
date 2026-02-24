# ETS2 Docker Dedicated Server

中文版见：[`README.zh-CN.md`](https://github.com/kKsk03/ETS2-Dedicated-Server-Docker/blob/main/README.zh-CN.md)  

You need a working `Docker` environment prepared in advance before following this guide.

## Deployment Flow

### 1. Place project files in a server directory

```bash
mkdir -p /home/ets2_server
cd /home/ets2_server
# Copy repository files here. Run all later commands in /home/ets2_server
```

### 2. Create `.env`

```bash
cp .env.example .env
```

`.env` parameter reference:

- `TZ`: Container timezone. Examples: `Asia/Shanghai`, `UTC`.
- `ETS2_AUTO_UPDATE`: Whether to run update automatically on every container start. Recommended: `true`.
- `ETS2_VALIDATE_ON_UPDATE`: Whether to add `validate` during update. Slower, but verifies file integrity.
- `ETS2_BRANCH`: Steam branch. Default is `public`; set another branch name if needed.
- `ETS2_DATA_HOME`: Data root path inside container. Default: `/data/ets2data`, usually no change needed.
- `ETS2_FIX_PERMISSIONS`: Whether to auto-fix `/data` permissions on container startup. Default: `true`.
- `ETS2_REQUIRE_SERVER_PACKAGES`: Whether to strictly check `server_packages.sii/.dat` before startup. Recommended: `true`.

### 3. Create directories and write initial config

Use this exact path: `data/ets2data/Euro Truck Simulator 2`

```bash
mkdir -p "data/ets2data/Euro Truck Simulator 2"
cp "docker/defaults/server_config.sii" "data/ets2data/Euro Truck Simulator 2/server_config.sii"
```

### 4. Export required files in `ETS2`

1. Open this file:
   `C:\Users\<username>\Documents\Euro Truck Simulator 2\config.cfg`
2. Search and change:
   - `uset g_developer "0"` to `uset g_developer "1"`
   - `uset g_console "0"` to `uset g_console "1"`
   Then save the file.
3. Start the game, configure the `Mod` set you want, then enter your save.
4. Press `~` to open the in-game console.
5. Run: `export_server_packages`
6. In `C:\Users\<username>\Documents\Euro Truck Simulator 2`, you should get:
   - `server_packages.sii`
   - `server_packages.dat`

### 5. Create `Steam GSLT` (optional)

> You can skip this, but then the search ID will not stay fixed. Creating one is recommended.

1. Open: [Steam GSLT](https://steamcommunity.com/dev/managegameservers)
2. Log in and create a token with game `AppID`: `227300`
3. Copy the generated token for later use

### 6. Place dependency files and edit config

1. Put `server_packages.sii` in `data/ets2data/Euro Truck Simulator 2/server_packages.sii`
2. Put `server_packages.dat` in `data/ets2data/Euro Truck Simulator 2/server_packages.dat`
3. Edit `data/ets2data/Euro Truck Simulator 2/server_config.sii`

Adjust the config as needed based on each field name, and if you created a token, make sure to fill it in.

### 7. Start the service

```bash
docker compose up -d --build
```

This command builds the image first, then starts the server.

### 8. Check logs to confirm startup

```bash
docker compose logs -f ets2-server
```

When you see a search ID, startup is successful:

```bash
[MP] Session search id: xxxxxxxxxxxxx/xxx
[MP] Session name: xxxxxxx
[MP] Session description: xxxxxx
[MP] Maximum number of players: x
[MP] Connection virtual ports: xxx / xxx
[MP] Connection server ports: 27015 / 27016
[MP] Friends only: False
```

## Directory Structure

```text
.
|-- Dockerfile
|-- compose.yaml
|-- .env.example
|-- docker/
|   |-- entrypoint.sh
|   `-- defaults/server_config.sii
`-- data/
    |-- server/                     # dedicated files downloaded automatically by SteamCMD
    `-- ets2data/
        `-- Euro Truck Simulator 2/ # fixed directory name required by the game
            |-- server_config.sii
            |-- server_packages.sii
            `-- server_packages.dat
```

## Port Mapping

Default mappings:

- `27015/tcp`
- `27015/udp`
- `27016/udp`

If you change the dedicated ports in `server_config.sii`, you must also update `compose.yaml`.

Also make sure these ports are allowed in the server firewall.
