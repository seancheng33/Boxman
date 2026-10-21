extends Control

## Web 版存档演示：把 user:// 在浏览器里的真实身份摊开给你看。
##
## 桌面版里 user:// 是磁盘上的一���文件夹，网页版里它其实是一套虚拟文件系统
## （Godot 4.2 用 IndexedDB + IDBFS 模拟），数据留在浏览器的沙箱里。
## 本工程把三件事摊开：
##   1. user:// 全局化之后长什么样（一个 /idbfs/ 虚拟路径）
##   2. 写进去的文件能不能读回来
##   3. 存档究竟落在浏览器的哪个存储里

@onready var mode_label: Label = $ModeLabel
@onready var path_label: Label = $PathLabel
@onready var content_label: Label = $ContentLabel
@onready var write_btn: Button = $WriteBtn
@onready var read_btn: Button = $ReadBtn
@onready var delete_btn: Button = $DeleteBtn
@onready var storage_btn: Button = $StorageBtn

const SAVE_NAME := "web_save.txt"
const CONTENT := ["unlocked=6", "written_by=web_demo"]

var is_web := false
var user_path := ""


func _ready() -> void:
	is_web = OS.has_feature("web")
	user_path = ProjectSettings.globalize_path("user://")
	if is_web:
		mode_label.text = "网页版：user:// 落在浏览器沙箱（IndexedDB / IDBFS）"
	else:
		mode_label.text = "非网页版：user:// 是真实磁盘目录"
	refresh_paths()
	write_btn.grab_focus()


func refresh_paths() -> void:
	path_label.text = "user:// 全局化 = " + user_path


func _save_path() -> String:
	return "user://" + SAVE_NAME


func _on_write() -> void:
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
	if f == null:
		content_label.text = "写入失败（错误码 %d）" % FileAccess.get_open_error()
		return
	for line in CONTENT:
		f.store_line(line)
	f.close()
	content_label.text = "已写入。点「读回」验证。"
	_on_read()


func _on_read() -> void:
	if not FileAccess.file_exists(_save_path()):
		content_label.text = "读不到：文件不存在（网页版第一次点「读回」就是这样）"
		return
	var f := FileAccess.open(_save_path(), FileAccess.READ)
	if f == null:
		content_label.text = "打开失败（错误码 %d）" % FileAccess.get_open_error()
		return
	var body := f.get_as_text()
	f.close()
	content_label.text = "读回内容：\n" + body


func _on_delete() -> void:
	if FileAccess.file_exists(_save_path()):
		var err := DirAccess.remove_absolute(_save_path())
		if err == OK:
			content_label.text = "已删除。网页版清缓存也会一起没。"
		else:
			content_label.text = "删除失败（错误码 %d）" % err
	else:
		content_label.text = "没有文件可删"


func _on_storage() -> void:
	if not is_web:
		content_label.text = "只有网页版才查得到浏览器存储。"
		return
	# 用 JavaScriptBridge 问浏览器要存储信息（同步 API，Promise 拿不到）
	var js := """
	(function() {
		var out = [];
		try {
			out.push('localStorage 条目数：' + (window.localStorage ? localStorage.length : '不可用'));
			out.push('sessionStorage 条目数：' + (window.sessionStorage ? sessionStorage.length : '不可用'));
		} catch (e) { out.push('storage 访问异常：' + e); }
		if (window.indexedDB) {
			out.push('indexedDB 可用：' + !!window.indexedDB);
		} else {
			out.push('indexedDB 不可用');
		}
		if (navigator.storage && navigator.storage.persisted) {
			out.push('持久化许可需用户手势，脚本查不到');
		}
		out.push('user:// 实际落在浏览器的 IndexedDB 里（IDBFS 虚拟盘）');
		return out.join('\\n');
	})()
	"""
	var res = JavaScriptBridge.eval(js, true)
	if res is Array and res.size() >= 2:
		content_label.text = "浏览器存储：\n" + str(res[1])
	else:
		content_label.text = "浏览器存储查询失败：%s" % str(res)
