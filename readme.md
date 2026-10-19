# Godot Boxman（推箱子）

[English](readme_en.md) | 简体中文

一个基于 Godot 3.5.2 的推箱子（Sokoban）游戏，支持中英文界面切换。

## 简介

- 游戏素材下载自免费游戏素材网站：https://kenney.nl/
- 游戏关卡来自：http://sokoban.cn/ 中的经典关卡，去重处理后共 **237 关**
- 支持键盘（方向键 / WASD）操作与鼠标点按菜单，按 **Z** 键可悔棋
- 界面支持 **中文 / English** 切换（主菜单按钮，偏好自动保存）

## 游戏截图

### 主界面

![主界面](assets/img/主界面.png)

### 游戏关卡

![游戏关卡](assets/level_image/level039.png)

### 游戏选关

![游戏选关](assets/img/游戏选关.png)

## 操作说明

- 菜单按键：鼠标点击
- 人物移动：键盘方向键或 【A、S、D、W】
- 悔棋：按 【Z】 撤销上一步
- 将全部箱子推到目标位置即通关；通关后可选下一关或返回主菜单，游戏中也可通过「上一关 / 下一关」按钮切换关卡

## 技术架构

- 引擎：Godot 3.5.2（GDScript）
- 开发环境：Win11（主要）、macOS 12.6.7（偶尔）
- **关卡数据**：`levels_txt/` 下的标准 sokoban ASCII 文本（`#` 墙 `@` 人 `$` 箱 `.` 目标，`*`/`+` 为箱/人压目标）。关卡由 `scene/LevelTemplate.tscn` + `script/level_builder.gd` 在运行时生成，**新增关卡只需往 `levels_txt/` 放一个文本文件**，零编辑器操作
- **导航**：所有界面统一走 `global.gd` 的 `goto_level(索引)` 入口
- **多语言**：文案集中在 `global.gd` 的 `TEXTS` 表，语言偏好持久化在 `user://settings.cfg`
- 导出配置：`export_presets.cfg` 含 `include_filter="*.txt"`，保证导出包携带关卡数据

## 关卡质量验证

`tools/` 目录附有关卡反解析与求解器脚本：

- `tools/parse_levels.py`：tscn → ASCII 反解析（历史迁移工具，237/237 无损校验通过）
- `tools/solve_levels.py`：A* + 死格/冻结剪枝求解器，支持 `SOLVE_LIMIT` 环境变量与指定关卡参数
- 验证结论：**227 关证实可通关**；原 Level071/131/146 三关因关卡数据转录错误无解，已修正地图并复验通过；其余 10 关求解器 300 秒内未出解（未定，不代表无解）

## 在线试玩

可以在我的网站 <http://three-corner.xyz> 上面的小玩意栏目里找到本游戏的 HTML5 版本并进行试玩。

## 打包下载

游戏的 docker 镜像和 win 版二进制可执行文件与 html5 版本已打包完成，放在百度盘供有兴趣的朋友下载；windows 版和 HTML5 版本也可以在源码的 dist 目录中直接获取，右侧的 releases 下载亦可。

### docker 镜像

链接：https://pan.baidu.com/s/1_ukZqLLnVp-5GWDG6Y_wJw?pwd=8888
提取码：8888

### win 版

链接: https://pan.baidu.com/s/1xIEm1tUhqxuSbB-oA55z0A?pwd=8888
提取码: 8888

### html5 版本

链接: https://pan.baidu.com/s/1YpamQMTw50kkVmW73RHtGQ?pwd=8888
提取码: 8888

## 关于

关卡和其他的内容将逐步更新。如果您发现了 bug 或者有其他建议，欢迎发送至我的邮箱：aya234@163.com
