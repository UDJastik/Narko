extends Node2D

class_name OSMController

const OverpassClient = preload("res://scripts/osm/OverpassClient.gd")
const MapProjection = preload("res://scripts/osm/MapProjection.gd")
const OSMParser = preload("res://scripts/osm/OSMParser.gd")
const LayeredMap = preload("res://scripts/osm/LayeredMap.gd")

@export var center_latitude: float = 55.751244
@export var center_longitude: float = 37.618423
@export var pixels_per_meter: float = 0.75
@export var fetch_radius_m: float = 500.0

var projection: MapProjection
var client: OverpassClient
var map_node: LayeredMap

func _ready() -> void:
	projection = MapProjection.new(center_latitude, center_longitude, pixels_per_meter)
	client = OverpassClient.new()
	add_child(client)
	map_node = LayeredMap.new()
	add_child(map_node)
	await _fetch_and_render()

func _fetch_and_render() -> void:
	var bbox := _bbox_from_radius(center_latitude, center_longitude, fetch_radius_m)
	var query := _make_overpass_query(bbox)
	var json := await client.query_with_retries(query)
	if json.is_empty():
		push_warning("Overpass returned empty result")
		return
	var features = OSMParser.parse(json, projection)
	map_node.clear_all()
	map_node.add_features(features)

func _bbox_from_radius(lat: float, lon: float, radius_m: float) -> Dictionary:
	# Rough bbox assuming small area in meters; use mercator meters offsets.
	var center_m := MapProjection._latlon_to_mercator(lat, lon)
	var dx := radius_m
	var dy := radius_m
	var sw_m := center_m + Vector2(-dx, -dy)
	var ne_m := center_m + Vector2(dx, dy)
	var sw_ll := _mercator_to_latlon(sw_m)
	var ne_ll := _mercator_to_latlon(ne_m)
	return {"south": sw_ll.x, "west": sw_ll.y, "north": ne_ll.x, "east": ne_ll.y}

static func _mercator_to_latlon(m: Vector2) -> Vector2:
	var lon := rad_to_deg(m.x / MapProjection.EARTH_RADIUS_M)
	var lat := rad_to_deg(2.0 * atan(exp(m.y / MapProjection.EARTH_RADIUS_M)) - PI/2.0)
	return Vector2(lat, lon)

func _make_overpass_query(b: Dictionary) -> String:
	# Fetch roads, buildings, waterways, landuse, green, poi within bbox
	var bbox_str := "%f,%f,%f,%f" % [b["south"], b["west"], b["north"], b["east"]]
	var parts := []
	parts.append("(way[\"highway\"](%s););\n" % bbox_str)
	parts.append("(way[\"building\"](%s););\n" % bbox_str)
	parts.append("(way[\"waterway\"](%s););\n" % bbox_str)
	parts.append("(way[\"natural\"=\"water\"](%s););\n" % bbox_str)
	parts.append("(way[\"landuse\"](%s););\n" % bbox_str)
	parts.append("(node[\"amenity\"](%s);node[\"shop\"](%s);node[\"tourism\"](%s););\n" % [bbox_str, bbox_str, bbox_str])
	var q := "[out:json][timeout:25];\n(%s);\nout body;\n>;\nout skel qt;" % parts.join("")
	return q