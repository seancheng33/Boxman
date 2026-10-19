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

	_show_page(0)

func _level_count() -> int:
	return GlobalVar.get_level_list().size()

func _page_count() -> int:
	return int(ceil(_level_count() / float(PAGE_SIZE)))

func _show_page(p: int):
	page = clamp(p, 0, _page_count() - 1)
	page_label.text = GlobalVar.t("select.page") % [page + 1, _page_count()]
	for c in grid.get_children():
		c.queue_free()
	var start: int = page * PAGE_SIZE
	var end: int = min(start + PAGE_SIZE, _level_count())
	var first_unlocked := -1
	for i in range(start, end):
		var btn := Button.new()
		btn.text = str(i + 1)
		btn.rect_min_size = Vector2(72, 52)
		btn.add_font_override("font", btn_font)
		var unlocked: bool = GlobalVar.is_level_unlocked(i)
		btn.disabled = not unlocked
		btn.self_modulate = Color(1, 1, 1, 1) if unlocked else Color(0.35, 0.35, 0.35, 0.85)
		btn.connect("pressed", self, "_on_level_pressed", [i])
		grid.add_child(btn)
		if first_unlocked < 0 and unlocked:
			first_unlocked = i
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
	selected_index = index
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
