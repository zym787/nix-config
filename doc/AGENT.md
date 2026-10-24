# Agent 指引

> 本文档供 AI agent 读取。修改配置前先读 `doc/ARCHITECTURE.md`。

## 当前状态

- 已完成从「单文件」到 `hosts/` + `users/` + `common/` + `settings/` 架构的迁移
- 当前主机：`e490`；当前用户：`drinkto`
- 构建：`sudo nixos-rebuild build --flake .#e490`
- 切换：`sudo nixos-rebuild switch --flake .#e490`
- `modules/` 目前未创建；出现真正按需启用的模块时再建
- 迁移记录见 `doc/OPTIMIZATION.md`

## 修改配置时的硬性规则

1. **禁止硬编码 `/nix/store` 路径**，用 `${pkgs.xxx}/相对路径`
2. **文件只留生效配置**，旧代码删除，交给 `git log`
3. **系统级选项**（`services.*`、`users.*`、`boot.*`）→ `hosts/` 或 `common/nixos/`
4. **用户级选项**（`home.*`、`programs.*` 中的用户配置）→ `users/` 或 `common/home/`
5. **主机名**禁用 `nixos`、`default`、`localhost`
6. **每次只改一件事**，改完先 `nixos-rebuild build` ，最后有用户确认是否 `switch`
7. **删除软件时**同步清理配置引用和 `~/.config/autostart/` 残留

## 新增文件的落点

| 要加的内容 | 放哪里 |
| :--- | :--- |
| 新的系统服务 | `common/nixos/<name>.nix`，在 `hosts/<host>/default.nix` 中 import |
| 新的用户级程序配置 | `common/home/<name>.nix` 或（可选模块）`modules/home-manager/<name>.nix`，在 `users/<name>/default.nix` 中 import |
| 新的全局变量 | `settings/default.nix` |
| 新的包分组 | `settings/packages.nix` |
| 新的主机 | 复制 `hosts/<现有>/` 为新目录，改 `variables.nix` |
| 新的用户 | 复制 `users/<现有>/` 为新目录，改 `username`，在主机入口启用 |

## 常见错误对照

| 报错 | 原因 | 修复 |
| :--- | :--- | :--- |
| `The option ... does not exist` | 层级写错 | 系统级选项不要写进 `users/` |
| `Refusing to evaluate package ... insecure` | 不安全包 | 追加到 `permittedInsecurePackages` |
| `A definition for option ... is not of type` | 类型错误 | 查文档，如 `experimental-features` 是列表 |
| `Failed to connect` / `i/o timeout` | 网络 | 检查 `substituters` 或代理 |
| `cannot find flake 'flake:xxx'` | flake 输入未定义 | 检查 `flake.nix` 的 `inputs` |
| 进程在跑但配置已删除 | XDG autostart 残留 | 删 `~/.config/autostart/*.desktop` |