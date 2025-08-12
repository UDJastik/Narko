extends Node2D

class_name LayeredMap

const Types = preload("res://scripts/osm/OSMTypes.gd")

@export var enable_selection: bool = true
@export var line_width_px: float = 2.0

var _layer_to_canvas: Dictionary = {}
var _features_by_layer: Dictionary = {}
var _selected_feature_ids := {}

signal feature_selected(feature_id: int, layer: int)

class LayerCanvas extends Node2D:
	var layer: int = 0
	var features: Array = []
	var line_width_px: float = 2.0
	var get_color: Callable
	var get_fill: Callable
	var is_selected: Callable

	func _draw() -> void:
		for f in features:
			match f.geometry_kind:
				Types.GeometryKind.WAY:
					var col: Color = get_color.call(layer)
					if _is_polygon(f):
						var colors := PackedColorArray()
						for i in f.nodes.size():
							colors.append(get_fill.call(layer))
						draw_polygon(f.nodes, colors)
					draw_polyline(f.nodes, col, line_width_px * (1.6 if is_selected.call(f.id) else 1.0))
				Types.GeometryKind.NODE:
					var colp: Color = get_color.call(layer)
					draw_circle(f.nodes[0], 3.5 if not is_selected.call(f.id) else 5.0, colp)

	static func _is_polygon(f: Types.Feature) -> bool:
		return f.nodes.size() >= 3 and f.nodes[0].distance_to(f.nodes[-1]) < 1.0

func _ready() -> void:
	# Create a LayerCanvas per layer for easy z-index and toggling
	for layer in Types.FeatureLayer.values():
		var ci := LayerCanvas.new()
		ci.layer = layer
		ci.name = "Layer_%s" % [Types.FeatureLayer.keys()[layer]]
		ci.z_index = layer
		ci.line_width_px = line_width_px
		ci.get_color = func(l): return _color_for_layer(l)
		ci.get_fill = func(l): return _fill_for_layer(l)
		ci.is_selected = func(id): return _selected_feature_ids.has(id)
		add_child(ci)
		_layer_to_canvas[layer] = ci
		_features_by_layer[layer] = []

func clear_all() -> void:
	for layer in _features_by_layer.keys():
		_features_by_layer[layer].clear()
		_update_canvas(layer)

func add_features(features: Array[Types.Feature]) -> void:
	for f in features:
		if not _features_by_layer.has(f.layer):
			_features_by_layer[f.layer] = []
			var ci := LayerCanvas.new()
			ci.layer = f.layer
			ci.name = "Layer_%s" % [Types.FeatureLayer.keys()[f.layer]]
			ci.z_index = f.layer
			ci.line_width_px = line_width_px
			ci.get_color = func(l): return _color_for_layer(l)
			ci.get_fill = func(l): return _fill_for_layer(l)
			ci.is_selected = func(id): return _selected_feature_ids.has(id)
			add_child(ci)
			_layer_to_canvas[f.layer] = ci
		_features_by_layer[f.layer].append(f)
		_update_canvas(f.layer)

func _update_canvas(layer: int) -> void:
	var ci: LayerCanvas = _layer_to_canvas.get(layer, null)
	if ci == null:
		return
	ci.features = _features_by_layer.get(layer, [])
	ci.line_width_px = line_width_px
	ci.queue_redraw()

func _color_for_layer(layer: int) -> Color:
	match layer:
		Types.FeatureLayer.ROAD:
			return Color(0.9, 0.8, 0.6)
		Types.FeatureLayer.BUILDING:
			return Color(0.65, 0.65, 0.7)
		Types.FeatureLayer.WATER:
			return Color(0.4, 0.6, 0.9)
		Types.FeatureLayer.GREEN:
			return Color(0.6, 0.8, 0.6)
		Types.FeatureLayer.LANDUSE:
			return Color(0.7, 0.75, 0.6)
		Types.FeatureLayer.POI:
			return Color(0.95, 0.3, 0.3)
		Types.FeatureLayer.BOUNDARY:
			return Color(0.9, 0.5, 0.2)
		_:
			return Color(0.9, 0.9, 0.9)

func _fill_for_layer(layer: int) -> Color:
	var c := _color_for_layer(layer)
	return Color(c.r, c.g, c.b, 0.3)

func _unhandled_input(event: InputEvent) -> void:
	if not enable_selection:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_global_mouse_position()
		var hit := _pick_feature(mouse_pos)
		if hit != null:
			_selected_feature_ids[hit.id] = true
			emit_signal("feature_selected", hit.id, hit.layer)
			_update_canvas(hit.layer)

func _pick_feature(p: Vector2) -> Types.Feature:
	# Simple nearest polyline/point pick. Can be improved with BVH later.
	var best: Types.Feature = null
	var best_d := 12.0
	for features in _features_by_layer.values():
		for f in features:
			if f.geometry_kind == Types.GeometryKind.NODE:
				var d := p.distance_to(f.nodes[0])
				if d < best_d:
					best_d = d
					best = f
			elif f.nodes.size() >= 2:
				for i in range(f.nodes.size()-1):
					var closest := Geometry2D.get_closest_point_to_segment(p, f.nodes[i], f.nodes[i+1])
					var d := closest.distance_to(p)
					if d < best_d:
						best_d = d
						best = f
	return best

func toggle_layer_visible(layer: int, visible: bool) -> void:
	var ci: Node2D = _layer_to_canvas.get(layer, null)
	if ci:
		ci.visible = visible