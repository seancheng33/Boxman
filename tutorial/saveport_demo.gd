extends Control

# 教学演示：便携化存档——存到 exe 同级目录，失败回退 user://
# user:// 的问题：导出后藏在玩家系统目录深处，想备份都找不到。
# 便携化的思路：优先把存档写在 exe 旁边，跟着游戏走；
# 写不了（编辑器里跑、网页版、无权限）就老老实实回退 user://

var storage_dir := ""
var mode_text := ""

@onready var path_label := $PathLabel
@onready var mode_label := $ModeLabel
@onready var content_label := $ContentLabel
@onready var write_btn := $WriteBtn
@onready var read_btn := $ReadBtn
@onready var delete_btn := $DeleteBtn

func _ready() -> void:
	storage_dir = _resolve_storage()
	if storage_dir == ProjectSettings.globalize_path("user://"):
		mode_text = "回退模式：user://（编辑器/网页版/无写权限）"
	else:
		mode_text = "便携模式：exe 同级目录"
	refresh_paths()
	# 初始焦点给第一个按钮，键盘党 Tab 顺位走
	write_btn.grab_focus()

func _resolve_storage() -> String:
	# 编辑器里跑：exe 是编辑器本体，别往编辑器安装目录写
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("user://")
	# 网页版没有本地文件系统，也回退
	if OS.has_feature("web"):
		return ProjectSettings.globalize_path("user://")
	# 导出版：试试 exe 同级目录可不可写——写探针验证，最老实
	var exe_dir := OS.get_executable_path().get_base_dir()
	var probe := exe_dir.path_join("write_test.tmp")
	var f := FileAccess.open(probe, FileAccess.WRITE)
	if f != null:
		f.close()
		DirAccess.remove_absolute(probe)
		return exe_dir
	# 目录只读（装在 Program Files 之类）：回退
	return ProjectSettings.globalize_path("user://")

func _save_path() -> String:
	return storage_dir.path_join("demo_save.txt")

func refresh_paths() -> void:
	mode_label.text = mode_text
	path_label.text = "存档位置：" + _save_path()

func _on_write() -> void:
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
	if f == null:
		content_label.text = "写入失败（错误码 %d）" % FileAccess.get_open_error()
		return
	f.store_line("unlocked=6")
	f.store_line("written_by=portable_demo")
	f.close()
	content_label.text = "已写入。点「读回」验证。"
	_read_back()

func _read_back() -> void:
	if not FileAccess.file_exists(_save_path()):
		content_label.text = "存档还不存在"
		return
	var f := FileAccess.open(_save_path(), FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	content_label.text = "读回内容：\n" + text

func _on_delete() -> void:
	if FileAccess.file_exists(_save_path()):
		DirAccess.remove_absolute(_save_path())
	content_label.text = "存档已删除" if not FileAccess.file_exists(_save_path()) else "删除失败"
