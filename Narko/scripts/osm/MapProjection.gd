extends Resource

class_name MapProjection

# Web Mercator projection helper for 2D top-down rendering in Godot.
# Converts WGS84 lat/lon to local (x, y) in pixels via meters offsets
# from a chosen center point and a pixels_per_meter scale.

@export var center_latitude: float = 0.0
@export var center_longitude: float = 0.0
@export var pixels_per_meter: float = 1.0

const EARTH_RADIUS_M: float = 6378137.0
const MIN_LAT: float = -85.05112878
const MAX_LAT: float = 85.05112878

var _center_mercator: Vector2

func _init(center_lat: float = 0.0, center_lon: float = 0.0, ppm: float = 1.0) -> void:
	center_latitude = clampf(center_lat, MIN_LAT, MAX_LAT)
	center_longitude = wrapf(center_lon, -180.0, 180.0)
	pixels_per_meter = max(0.0001, ppm)
	_center_mercator = _latlon_to_mercator(center_latitude, center_longitude)

func set_center(center_lat: float, center_lon: float) -> void:
	center_latitude = clampf(center_lat, MIN_LAT, MAX_LAT)
	center_longitude = wrapf(center_lon, -180.0, 180.0)
	_center_mercator = _latlon_to_mercator(center_latitude, center_longitude)

func set_pixels_per_meter(ppm: float) -> void:
	pixels_per_meter = max(0.0001, ppm)

func latlon_to_local(lat: float, lon: float) -> Vector2:
	# Returns local canvas coordinates (pixels) for a given WGS84 point.
	var m := _latlon_to_mercator(clampf(lat, MIN_LAT, MAX_LAT), wrapf(lon, -180.0, 180.0))
	var delta_m := m - _center_mercator
	# Godot 2D Y grows downwards; Mercator Y grows upwards -> invert Y
	return Vector2(delta_m.x, -delta_m.y) * pixels_per_meter

func bbox_latlon_to_local(south: float, west: float, north: float, east: float) -> Rect2:
	var p1 := latlon_to_local(south, west)
	var p2 := latlon_to_local(north, east)
	var rect := Rect2(p1, Vector2.ZERO)
	rect = rect.expand(p2)
	return rect

static func _latlon_to_mercator(lat: float, lon: float) -> Vector2:
	var x := deg_to_rad(lon) * EARTH_RADIUS_M
	var clamped_lat := clampf(lat, MIN_LAT, MAX_LAT)
	var y := log(tan(PI * 0.25 + deg_to_rad(clamped_lat) * 0.5)) * EARTH_RADIUS_M
	return Vector2(x, y)