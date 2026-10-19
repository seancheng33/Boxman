extends Panel

# 选关界面：分页数字网格 + 右侧实时预览（SubViewport 渲染不可交互的关卡实例）
# 预览复用 LevelTemplate 的运行时构建，自动继承分关配色主题。

const LEVEL_SCENE := preload("res://scene/LevelTemplate.tscn")
const FONT_DATA := preload("res://assets/fonts/Unifont.ttf")

const PAGE_SIZE := 60
const GRID_COLUMNS := 10
const TILE := 64

onready var grid: GridContainer = $VBox/Content/Grid
onready var page_label: Label = $VBox/PageBar/page_label
onready var preview_rect: TextureRect = $VBox/Content/PreviewSide/PreviewRect
onready var enter_button: Button = $VBox/Content/PreviewSide/enter

var page := 0
var selected_index := -1
var preview_viewport: Viewport
var preview_level: Node
var btn_font: DynamicFont
var _buttons := {}

func _ready():
	btn_font = DynamicFont.new()
	btn_font.font_data = FONT_DATA
	btn_font.size = 22
	$VBox/PageBar/prev_page.text = GlobalVar.t("page.prev")
	$VBox/PageBar/next_page.text = GlobalVar.t("page.next")
	enter_button.text = GlobalVar.t("select.enter")

	# 预览视口：独立 Viewport（不经 SubViewportContainer 挂载，不接收任何输入）
	preview_viewport = Viewport.new()
	preview_viewport.size = Vector2(512, 512)
	preview_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	add_child(preview_viewport)
	preview_rect.texture = preview_viewport.get_texture()
	# Godot 3 的 Viewport 纹理 Y 轴与屏幕坐标系相反，直接上 TextureRect 会上下颠倒
	preview_rect.flip_v = true

	# 还原游戏状态：优先定位上次游玩的关卡，否则停在本页第一个已解锁关
	var anchor := GlobalVar.last_level_index
	if anchor < 0 or not GlobalVar.is_level_unlocked(anchor) or anchor >= _level_count():
		anchor = 0
	_show_page(int(anchor / float(PAGE_SIZE)), anchor)

func _level_count() -> int:
	return GlobalVar.get_level_list().size()

func _page_count() -> int:
	return int(ceil(_level_count() / float(PAGE_SIZE)))

func _show_page(p: int, select_hint: int = -1):
	page = clamp(p, 0, _page_count() - 1)
	page_label.text = GlobalVar.t("select.page") % [page + 1, _page_count()]
	for c in grid.get_children():
		c.queue_free()
	var start: int = page * PAGE_SIZE
	var end: int = min(start + PAGE_SIZE, _level_count())
	var first_unlocked := -1
	_buttons.clear()
	for i in range(start, end):
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.rect_min_size = Vector2(72, 52)
		btn.add_font_override("font", btn_font)
		var unlocked: bool = GlobalVar.is_level_unlocked(i)
		btn.disabled = not unlocked
		btn.self_modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.35, 0.35, 0.85)
		if unlocked and GlobalVar.is_level_cleared(i):
			# 已通关的关卡数字标绿，一眼看出进度
			btn.add_color_override("font_color", Color(0.13, 0.55, 0.13))
		btn.connect("pressed", self, "_on_level_pressed", [i])
		grid.add_child(btn)
		_buttons[i] = btn
		if first_unlocked < 0 and unlocked:
			first_unlocked = i
	# select_hint：外部指定的预选关（上次游玩的关）；无效则选本页第一个已解锁关
	if select_hint >= start and select_hint < end and GlobalVar.is_level_unlocked(select_hint):
		_select(select_hint)
	else:
		_select(first_unlocked)

func _on_prev_page_pressed():
	_show_page(page - 1)

func _on_next_page_pressed():
	_show_page(page + 1)

func _on_level_pressed(index: int):
	if not GlobalVar.is_level_unlocked(index):
		return
	_select(index)

func _on_enter_pressed():
	if selected_index >= 0 and GlobalVar.is_level_unlocked(selected_index):
		GlobalVar.goto_level(selected_index)

func _select(index: int):
	# 选中态高亮：恢复旧选中按钮颜色，再把新选中的数字标橙
	if _buttons.has(selected_index) and is_instance_valid(_buttons[selected_index]):
		var old: Button = _buttons[selected_index]
		if GlobalVar.is_level_cleared(selected_index):
			old.add_color_override("font_color", Color(0.13, 0.55, 0.13))
		else:
			old.remove_color_override("font_color")
	selected_index = index
	if _buttons.has(index) and is_instance_valid(_buttons[index]):
		_buttons[index].add_color_override("font_color", Color(0.85, 0.35, 0.0))
	_refresh_preview()

func _refresh_preview():
	if selected_index < 0:
		return
	if preview_level != null:
		preview_level.queue_free()
		preview_level = null
	# 预览复用运行时构建流程：设置全局索引后实例化关卡模板
	GlobalVar.current_level_index = selected_index
	preview_level = LEVEL_SCENE.instance()

	# 按关卡内容包围盒设置视口尺寸并居中显示
	var data: Dictionary = GlobalVar.load_level_data(GlobalVar.get_level_list()[selected_index])
	if data.empty():
		preview_viewport.add_child(preview_level)
		return
	var minc := Vector2(INF, INF)
	var maxc := Vector2(-INF, -INF)
	for arr in [data.walls, data.dests, data.boxes]:
		for v in arr:
			minc = Vector2(min(minc.x, v.x), min(minc.y, v.y))
			maxc = Vector2(max(maxc.x, v.x), max(maxc.y, v.y))
	if data.player.x > -9000:
		minc = Vector2(min(minc.x, data.player.x), min(minc.y, data.player.y))
		maxc = Vector2(max(maxc.x, data.player.x), max(maxc.y, data.player.y))
	var size_px: Vector2 = (maxc - minc + Vector2(1, 1)) * TILE
	preview_viewport.size = Vector2(
		clamp(size_px.x, TILE, 1280),
		clamp(size_px.y, TILE, 1280))
	preview_level.position = -minc * TILE
	preview_viewport.add_child(preview_level)
