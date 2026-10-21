extends Control

## 发布演示：版本号唯一来源 + 产物清单 + 发布说明草稿
##
## 发布前最怕两件事：版本号写着 v1.2.1、实际传上去的是上一版；
## 产物漏了文件、玩家下载完才发现跑不起来。
## 本工程把这两件事做成一个可点的体检面板：
##   1. 版本号只从 project.godot 的 config/version 读，绝不手抄第二份
##   2. 扫一遍导出目录，列出每个文件的体积，超过 100MB 一眼看到
##   3. 生成一份发布说明草稿，一键复制到剪贴板

const ARTIFACTS := [
	["Windows 版", "export_test"],
	["网页版", "export_test_web"],
]
const BIG_FILE_MB := 100.0

@onready var ver_label: Label = $VerLabel
@onready var list_label: Label = $ListLabel
@onready var notes_panel: PanelContainer = $NotesPanel
@onready var notes_label: Label = $NotesPanel/NotesLabel
@onready var scan_btn: Button = $ScanBtn
@onready var notes_btn: Button = $NotesBtn
@onready var copy_btn: Button = $CopyBtn

var notes_text := ""


func _ready() -> void:
	ver_label.text = "版本号（来自 project.godot）：v%s" % _ver()
	scan_btn.grab_focus()
	_on_scan()


func _ver() -> String:
	# 版本号的唯一来源。项目设置里改一次，游戏里、发布页、tag 三边一致
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func _human(n: int) -> String:
	# 写清楚点：三元混进格式化容易看走眼，分两行反而省事
	if n > 1048576:
		return "%.1f MB" % (n / 1048576.0)
	return "%d KB" % (n / 1024)


func _out_dir(sub: String) -> String:
	# res:// 指向 pck 内部，导出后摸不到开发机目录；只有编辑器 / 命令行跑时
	# 全局化才等于磁盘路径。所以走 ProjectSettings.globalize_path 拿绝对路径。
	# 注意 globalize 回来的串带尾部斜杠，先去掉再取上一级，否则只退半级。
	var project_dir := ProjectSettings.globalize_path("res://").trim_suffix("/")
	return project_dir.get_base_dir().path_join(sub)


func _on_scan() -> void:
	var out := []
	var total := 0
	var found := 0
	for pair in ARTIFACTS:
		var dir_path := _out_dir(pair[1])
		var d := DirAccess.open(dir_path)
		if d == null:
			out.append("[%s] 目录不存在（先跑导出命令）" % pair[0])
			continue
		found += 1
		var files := d.get_files()
		files.sort()
		out.append("[%s] %d 个文件" % [pair[0], files.size()])
		for f in files:
			var size := FileAccess.get_file_as_bytes(dir_path + "/" + f).size()
			total += size
			var mark := "  <-- 偏大，确认要不要传" if size > BIG_FILE_MB * 1048576 else ""
			out.append("  %-28s %9s%s" % [f, _human(size), mark])
	list_label.text = "\n".join(out)
	if found == 0:
		list_label.text += "\n（还没导出过，先跑一遍导出命令再来体检）"
	else:
		list_label.text += "\n合计 %s" % _human(total)


func _on_notes() -> void:
	notes_text = "\n".join([
		"## v%s" % _ver(),
		"",
		"### 下载",
		"- Windows：boxman-win.zip（解压后双击 game.exe）",
		"- 网页版：boxman-web.zip（需本地起静态服务器，见 README）",
		"",
		"### 更新内容",
		"- 解锁制：初始开放前 5 关，通关自动解锁下一关",
		"- 选关分页 + 关卡实时预览",
		"- 便携存档：进度存在 exe 同级目录",
		"",
		"> 导出自检：%s" % ("两个产物目录都存在" if DirAccess.open(_out_dir("export_test")) != null else "产物缺失，先补导出"),
	])
	notes_label.text = notes_text
	notes_panel.visible = true


func _on_copy() -> void:
	if notes_text == "":
		notes_label.text = "先点「生成发布说明」"
		notes_panel.visible = true
		return
	DisplayServer.clipboard_set(notes_text)
	notes_label.text = "已复制到剪贴板，直接粘到 GitHub Release 描述框"
