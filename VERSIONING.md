# Version Management

Nex 采用**完全同步版本策略**。

## 策略

`nex_core` (framework) 和 `nex_new` (installer) **始终使用相同的版本号**。

即使只修改了其中一个包，两个包也会同时升级版本号并发布。

## 版本号位置

- `/VERSION` - 主版本号（所有包共享）
- `/framework/VERSION` - framework 版本号（与主版本号同步）
- `/installer/VERSION` - installer 版本号（与主版本号同步）
- `/framework/mix.exs` - framework 包版本
- `/installer/mix.exs` - installer 包版本

## 发布流程

1. 更新 `/VERSION` 文件
2. 更新 CHANGELOG（两个包都要更新）
3. 运行 `./scripts/publish_hex.sh` - 自动同步版本号并发布所有包

## 为什么选择同步版本？

**优点**：
- 简单明了，版本号永远一致
- 用户容易理解（nex v0.2.1 = nex_core v0.2.1 + nex_new v0.2.1）
- 减少版本管理的心智负担

**缺点**：
- 会有一些"空版本"（某个包无实际变更）
- 发布频率可能略高

我们认为简单性的价值大于缺点。
