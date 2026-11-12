extends RecoveryTask

## Set a request limit: a pipe of traffic runs into a gate, and the gate opens as wide as the limit. Small round dots are real
## customers (they ask for a few requests a minute), square dots are bots (the quietest asks for 60, most ask for hundreds).
## The player moves the slider (the limit, in requests per address a minute) and watches who gets through, then presses SET
## LIMIT. Two meters answer live: how many customers are let in and how many attackers. Layout: RateDial.tscn (the controls
## are built here). content: {heading, pick, set_limit, unit, customer_max, bot_min, bot_max, min_ok, max_ok, too_low, too_high,
## legend_customers, legend_bots, meter_customers, meter_bots, start}.
## The right limit lets every customer in (the limit is at least the most a customer asks for) and keeps the flood out
## (at most the quietest bot's rate): min_ok to max_ok.

const SLIDER_THEME := preload("res://assets/ui/slider/slider_theme.tres")

var slider: HSlider
var customers_meter: ProgressBar
var bots_meter: ProgressBar
var _pipe: Control
var _value_label: Label
var _set_button: Button
var _meters_label: Label


func setup_task() -> void:
	var heading := Label.new()
	heading.theme_type_variation = &"RecoveryAccent"
	heading.text = str(content.get("heading", ""))
	body.add_child(heading)
	_pipe = PipeView.new()
	_pipe.custom_minimum_size = Vector2(0, 92)
	_pipe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pipe.set("customer_max", float(content.get("customer_max", 25)))
	_pipe.set("bot_min", float(content.get("bot_min", 60)))
	_pipe.set("bot_max", float(content.get("bot_max", 600)))
	body.add_child(_pipe)
	var legend := Label.new()
	legend.theme_type_variation = &"RecoveryMuted"
	legend.text = "%s    %s" % [content.get("legend_customers", "o = a customer"), content.get("legend_bots", "[] = a bot")]
	body.add_child(legend)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	_value_label = Label.new()
	_value_label.custom_minimum_size = Vector2(150, 0)
	row.add_child(_value_label)
	slider = HSlider.new()
	slider.theme = SLIDER_THEME
	slider.min_value = 1
	slider.max_value = 200
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_slider_changed)
	row.add_child(slider)
	_set_button = Button.new()
	_set_button.text = str(content.get("set_limit", "SET LIMIT"))
	_set_button.pressed.connect(set_limit_pressed)
	row.add_child(_set_button)
	var meters := GridContainer.new()
	meters.columns = 3
	meters.add_theme_constant_override("h_separation", 8)
	body.add_child(meters)
	customers_meter = _meter(meters, str(content.get("meter_customers", "Customers let in")))
	bots_meter = _meter(meters, str(content.get("meter_bots", "Attackers let in")))


func _meter(grid: GridContainer, text: String) -> ProgressBar:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(130, 0)
	grid.add_child(label)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.show_percentage = true
	bar.custom_minimum_size = Vector2(170, 12)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(bar)
	grid.add_child(Control.new())
	return bar


func reset_state() -> void:
	slider.editable = true
	slider.set_value_no_signal(float(content.get("start", 200)))
	_on_slider_changed(slider.value)
	set_feedback(str(content.get("pick", "")))


func limit() -> int:
	return int(slider.value)


## The share of customers the limit lets in: customers ask for 1 up to customer_max requests, evenly.
func customers_in(limit_value: float) -> float:
	var top := float(content.get("customer_max", 25))
	return clampf((limit_value - 1.0) / (top - 1.0), 0.0, 1.0)


## The share of attackers the limit lets in: the bots ask for bot_min up to bot_max requests, evenly.
func attackers_in(limit_value: float) -> float:
	var low := float(content.get("bot_min", 60))
	var high := float(content.get("bot_max", 600))
	return clampf((limit_value - low) / (high - low), 0.0, 1.0)


func _on_slider_changed(value: float) -> void:
	_value_label.text = str(content.get("unit", "Limit: %d a minute")) % int(value)
	customers_meter.value = customers_in(value) * 100.0
	bots_meter.value = attackers_in(value) * 100.0
	_pipe.set("limit", value)


func set_limit_pressed() -> void:
	if solved:
		return
	var value := limit()
	if value < int(content.get("min_ok", 30)):
		note_mistake(str(content.get("too_low", "")).format({"limit": value}))
		return
	if value > int(content.get("max_ok", 60)):
		note_mistake(str(content.get("too_high", "")).format({"limit": value}))
		return
	slider.editable = false
	succeed()


## The pipe, the gate and the dots, drawn in code.
class PipeView extends Control:
	const BACK := Color(0.101960786, 0.10980392, 0.17254902, 1)
	const WALL := Color(0.3372549, 0.42352942, 0.5254902, 1)
	const GATE := Color(1, 0.8039216, 0.45882353, 1)
	const GATE_X := 0.62
	const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
	var limit := 200.0
	var customer_max := 25.0
	var bot_min := 60.0
	var bot_max := 600.0
	var _dots: Array[Dictionary] = []
	var _next := 0.0

	func _process(delta: float) -> void:
		_next -= delta
		if _next <= 0.0:
			_next = 0.16
			var bot := randf() < 0.35
			_dots.append({
				"x": 0.0, "y": randf_range(0.2, 0.8), "bot": bot,
				"ask": randf_range(bot_min, bot_max) if bot else randf_range(1.0, customer_max),
				"speed": 90.0, "back": false, "life": 1.0,
			})
		var gate_x := size.x * GATE_X
		var kept: Array[Dictionary] = []
		for dot in _dots:
			dot["x"] = float(dot["x"]) + float(dot["speed"]) * delta
			if not dot["back"] and float(dot["x"]) >= gate_x - 4.0 and float(dot["ask"]) > limit:
				dot["back"] = true # the gate does not let it through
				dot["speed"] = -40.0
			if dot["back"]:
				dot["life"] = float(dot["life"]) - delta * 1.6
			if float(dot["x"]) < size.x and float(dot["life"]) > 0.0:
				kept.append(dot)
		_dots = kept
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), BACK)
		var top := 8.0
		var bottom := size.y - 8.0
		draw_rect(Rect2(0, top - 2, size.x, 2), WALL)
		draw_rect(Rect2(0, bottom, size.x, 2), WALL)
		var gate_x := floorf(size.x * GATE_X)
		var open := lerpf(6.0, bottom - top, clampf((limit - 1.0) / 199.0, 0.0, 1.0)) # the gate opens as wide as the limit
		var mid := (top + bottom) / 2.0
		draw_rect(Rect2(gate_x, top, 4, mid - open / 2.0 - top), GATE)
		draw_rect(Rect2(gate_x, mid + open / 2.0, 4, bottom - mid - open / 2.0), GATE)
		draw_string(FONT, Vector2(2, 8), "TRAFFIC", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, WALL)
		draw_string(FONT, Vector2(gate_x - 14, size.y - 1), "LIMIT %d" % int(limit), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GATE)
		draw_string(FONT, Vector2(size.x - 40, 8), "THE SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, WALL)
		for dot in _dots:
			var at := Vector2(float(dot["x"]), top + (bottom - top) * float(dot["y"])).floor()
			var fade := clampf(float(dot["life"]), 0.0, 1.0)
			if dot["bot"]:
				draw_rect(Rect2(at - Vector2(2, 2), Vector2(5, 5)), Color(GameColors.bad, fade))
			else:
				draw_circle(at, 2.5, Color(0.4509804, 0.7, 0.96862745, fade))
