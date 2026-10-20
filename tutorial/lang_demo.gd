extends Control

# 教学演示：多语言支持——TranslationServer + tr()
# 界面上的字要能中英切换。做法：
# 1. 用代码把两套词条灌进 TranslationServer（小项目零资源文件）
# 2. 取字一律走 tr("KEY")——注意 tr 是"取值那一刻"翻译
# 3. 切语言 = set_locale + 手动刷新 + 把选择写进存档

const LANG_PATH := "user://progress.cfg"

var locale := "zh"

@onready var title_label := $TitleLabel
@onready var sub_label := $SubLabel
@onready var start_btn := $StartBtn
@onready var quit_btn := $QuitBtn
@onready var lang_btn := $LangBtn
@onready var tip_label := $TipLabel

func _ready() -> void:
	_setup_translations()
	locale = load_lang()
	TranslationServer.set_locale(locale)
	refresh_texts()
	# 初始焦点给开始按钮：没焦点时 Tab 导航不会启动
	start_btn.grab_focus()

func _setup_translations() -> void:
	var zh := Translation.new()
	zh.locale = "zh"
	zh.add_message("TITLE", "推 箱 子")
	zh.add_message("SUB", "—— 一个教程系列做出来的小游戏 ——")
	zh.add_message("START", "开始游戏")
	zh.add_message("QUIT", "退出")
	zh.add_message("LANG", "English")
	zh.add_message("TIP", "点下面的按钮切换语言")
	TranslationServer.add_translation(zh)

	var en := Translation.new()
	en.locale = "en"
	en.add_message("TITLE", "Boxman")
	en.add_message("SUB", "— a tiny game built by a tutorial series —")
	en.add_message("START", "Start Game")
	en.add_message("QUIT", "Quit")
	en.add_message("LANG", "中文")
	en.add_message("TIP", "Tap the button below to switch")
	TranslationServer.add_translation(en)

func refresh_texts() -> void:
	# 关键：tr() 是"取值那一刻"翻译，改完 locale 必须手动刷一遍
	title_label.text = tr("TITLE")
	sub_label.text = tr("SUB")
	start_btn.text = tr("START")
	quit_btn.text = tr("QUIT")
	lang_btn.text = tr("LANG")
	tip_label.text = tr("TIP")

func _on_start() -> void:
	get_tree().change_scene_to_file("res://select_page_demo.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _on_lang() -> void:
	locale = "en" if locale == "zh" else "zh"
	TranslationServer.set_locale(locale)
	save_lang()
	refresh_texts()

func load_lang() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(LANG_PATH) != OK:
		return "zh"
	# 兜底值仍然要给：老存档里没有 lang 这一节
	return cfg.get_value("lang", "locale", "zh")

func save_lang() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("lang", "locale", locale)
	cfg.save(LANG_PATH)
