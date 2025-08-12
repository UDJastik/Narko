extends Control

class_name MapSelectionOverlay

signal selection_started()
signal selection_changed(viewport_rect: Rect2)
signal selection_committed(viewport_rect: Rect2)
signal selection_committed_bbox(bbox: Dictionary)
signal selection_canceled()

var _enabled_internal: bool = true
@export var enabled: bool:
    set(value):
        _enabled_internal = value
        _update_mouse_filter()
    get:
        return _enabled_internal
@export var allow_cancel_with_right_click: bool = true
@export var allow_commit_with_double_click: bool = true
@export var allow_commit_with_enter: bool = true
@export var commit_on_release: bool = true

@export var fill_color: Color = Color(0.2, 0.6, 1.0, 0.2)
@export var border_color: Color = Color(0.2, 0.6, 1.0, 0.9)
@export var border_width: float = 2.0

# Optional converter to translate viewport rect to a lat/lon bbox
# Signature: Callable(Rect2) -> Dictionary {min_lat, min_lon, max_lat, max_lon}
@export var convert_rect_to_bbox: Callable

var _is_dragging: bool = false
var _drag_origin: Vector2 = Vector2.ZERO
var _current_rect: Rect2 = Rect2()
var _last_click_time_ms: int = 0
var _double_click_interval_ms: int = 300

func _ready() -> void:
    _update_mouse_filter()

func _gui_input(event: InputEvent) -> void:
    if not enabled:
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and not _is_dragging:
            _begin_drag(event.position)
        elif not event.pressed and _is_dragging:
            _end_drag(commit := commit_on_release)
            if allow_commit_with_double_click and event.double_click:
                _emit_commit_signals()
        _update_last_click_time()
        accept_event()
        return

    if allow_cancel_with_right_click and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        if event.pressed:
            if _is_dragging:
                _end_drag(commit := false)
            else:
                _cancel_selection()
            accept_event()
            return

    if allow_commit_with_enter and event is InputEventKey and not event.echo and event.pressed:
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            if _current_rect.size.length() > 0.0:
                _emit_commit_signals()
                accept_event()
                return

    if event is InputEventMouseMotion:
        if _is_dragging:
            _update_drag(event.position)
            accept_event()
            return

func _begin_drag(start_pos: Vector2) -> void:
    _is_dragging = true
    _drag_origin = start_pos
    _current_rect = Rect2(start_pos, Vector2.ZERO)
    emit_signal("selection_started")
    queue_redraw()

func _update_drag(current_pos: Vector2) -> void:
    var top_left: Vector2 = Vector2(min(_drag_origin.x, current_pos.x), min(_drag_origin.y, current_pos.y))
    var bottom_right: Vector2 = Vector2(max(_drag_origin.x, current_pos.x), max(_drag_origin.y, current_pos.y))
    var rect := Rect2(top_left, bottom_right - top_left)

    rect.position = rect.position.clamp(Vector2.ZERO, size)
    var rect_bottom_right := rect.position + rect.size
    rect_bottom_right = rect_bottom_right.clamp(Vector2.ZERO, size)
    rect.size = rect_bottom_right - rect.position

    _current_rect = rect
    emit_signal("selection_changed", _current_rect)
    queue_redraw()

func _end_drag(commit: bool) -> void:
    _is_dragging = false
    if not commit:
        _current_rect = Rect2()
        emit_signal("selection_canceled")
    queue_redraw()

func _cancel_selection() -> void:
    _is_dragging = false
    _current_rect = Rect2()
    emit_signal("selection_canceled")
    queue_redraw()

func _emit_commit_signals() -> void:
    if _current_rect.size.length() <= 0.0:
        return
    emit_signal("selection_committed", _current_rect)
    if convert_rect_to_bbox and convert_rect_to_bbox.is_valid():
        var bbox := convert_rect_to_bbox.call(_current_rect)
        if typeof(bbox) == TYPE_DICTIONARY:
            emit_signal("selection_committed_bbox", bbox)

func _update_last_click_time() -> void:
    _last_click_time_ms = Time.get_ticks_msec()

func _is_double_click() -> bool:
    return false

func get_selection_rect() -> Rect2:
    return _current_rect

func clear_selection() -> void:
    _current_rect = Rect2()
    queue_redraw()

func _draw() -> void:
    if _current_rect.size == Vector2.ZERO:
        return
    draw_rect(_current_rect, fill_color, true)
    draw_rect(_current_rect, border_color, false, border_width)

func _update_mouse_filter() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP if _enabled_internal else Control.MOUSE_FILTER_IGNORE