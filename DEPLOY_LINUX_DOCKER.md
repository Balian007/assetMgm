# Docker 部署到 Linux 指南

## 1. 前置条件

- Docker Engine 24+
- Docker Compose v2+
- Linux 服务器可访问以下端口（按需开放）：`80`（前端）、`8080`（后端）、`3306`（MySQL）

## 2. 初始化环境变量

```bash
cp .env.example .env
```

然后编辑 `.env`，至少修改以下敏感配置：

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`
- `JWT_SECRET`

## 3. 启动服务

```bash
docker compose up -d --build
```

查看运行状态与日志：

```bash
docker compose ps
docker compose logs -f mysql
docker compose logs -f backend
docker compose logs -f frontend
```

## 4. 访问地址

- 前端：`http://<服务器IP>/`
- 后端 API：`http://<服务器IP>:8080/`
- Swagger：`http://<服务器IP>:8080/swagger-ui.html`

## 5. 数据初始化说明

- MySQL 首次启动时会自动执行以下 SQL：
  - `asset-mgm-backend/src/main/resources/db/schema.sql`
  - `asset-mgm-backend/src/main/resources/db/mock_data.sql`
- 数据目录挂载在 Docker volume：`mysql_data`，重启容器不会丢失数据。

## 6. 导入已生成的模拟数据（可选）

若已存在 `tasks/mock_seed_generated.sql`，可执行：

```bash
docker compose exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" asset_mgm' < tasks/mock_seed_generated.sql
```

## 7. 常用运维命令

重启全部服务：

```bash
docker compose restart
```

停止并删除容器（保留数据卷）：

```bash
docker compose down
```

停止并删除容器及数据卷（会清空数据库）：

```bash
docker compose down -v
```

## 8. 更新发布

```bash
git pull
docker compose up -d --build
```

## 9. 备份建议

数据库备份：

```bash
docker compose exec -T mysql sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --databases asset_mgm' > backup_asset_mgm.sql
```

同时建议备份上传目录所在卷 `backend_uploads`，用于恢复附件/文件。

## 10. 一键初始化并部署（推荐）

```bash
cd /path/to/assetMgm
sudo bash scripts/linux/bootstrap_and_deploy.sh /path/to/assetMgm
```

可选环境变量：

- `OPEN_BACKEND_PORT=true`：自动放行 `8080`
- `EXPOSE_MYSQL=true`：自动放行 `3306`（仅在确有远程数据库访问需求时开启）

示例：

```bash
OPEN_BACKEND_PORT=true sudo bash scripts/linux/bootstrap_and_deploy.sh /path/to/assetMgm
```

## 11. 日常运维脚本

先赋予脚本执行权限：

```bash
chmod +x scripts/linux/*.sh
```

更新部署（会自动保存当前后端/前端镜像用于回滚）：

```bash
sudo bash scripts/linux/deploy_update.sh /path/to/assetMgm
```

回滚到上一版：

```bash
sudo bash scripts/linux/rollback.sh /path/to/assetMgm
```

查看日志：

```bash
# 全部服务
bash scripts/linux/logs.sh /path/to/assetMgm

# 指定服务
bash scripts/linux/logs.sh /path/to/assetMgm backend
bash scripts/linux/logs.sh /path/to/assetMgm frontend
bash scripts/linux/logs.sh /path/to/assetMgm mysql
```
