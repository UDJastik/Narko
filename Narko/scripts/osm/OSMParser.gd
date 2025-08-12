extends Resource

class_name OSMParser

const Types = preload("res://scripts/osm/OSMTypes.gd")
const MapProjection = preload("res://scripts/osm/MapProjection.gd")

static func classify_layer(tags: Dictionary) -> int:
	if tags.has("building"):
		return Types.FeatureLayer.BUILDING
	if tags.get("highway", "") != "":
		return Types.FeatureLayer.ROAD
	if tags.has("water") or tags.get("natural", "") in ["water", "coastline"] or tags.get("waterway", "") != "":
		return Types.FeatureLayer.WATER
	if tags.get("landuse", "") in ["forest", "meadow", "grass", "park"] or tags.get("natural", "") in ["wood", "scrub", "grassland"]:
		return Types.FeatureLayer.GREEN
	if tags.has("landuse"):
		return Types.FeatureLayer.LANDUSE
	if tags.has("amenity") or tags.has("shop") or tags.has("tourism"):
		return Types.FeatureLayer.POI
	if tags.has("boundary"):
		return Types.FeatureLayer.BOUNDARY
	return Types.FeatureLayer.UNKNOWN

static func parse(overpass_json: Dictionary, projection: MapProjection) -> Array[Types.Feature]:
	var elements = overpass_json.get("elements", [])
	var id_to_node_latlon: Dictionary = {}

	# First pass: collect nodes
	for e in elements:
		if e.get("type") == "node":
			id_to_node_latlon[e.get("id")] = Vector2(e.get("lon", 0.0), e.get("lat", 0.0))

	var features: Array[Types.Feature] = []

	# Second pass: ways and nodes as features
	for e in elements:
		var t = e.get("type")
		if t == "way":
			var nodes_ll: PackedVector2Array = []
			for nid in e.get("nodes", []):
				if id_to_node_latlon.has(nid):
					var ll: Vector2 = id_to_node_latlon[nid]
					nodes_ll.append(Vector2(ll.y, ll.x)) # store as (lat, lon)
			var tags: Dictionary = e.get("tags", {})
			var layer := classify_layer(tags)
			var nodes_local: PackedVector2Array = []
			for latlon in nodes_ll:
				nodes_local.append(projection.latlon_to_local(latlon.x, latlon.y))
			features.append(Types.Feature.new(e.get("id", 0), Types.GeometryKind.WAY, nodes_local, tags, layer))
		elif t == "node":
			var lat := float(e.get("lat", 0.0))
			var lon := float(e.get("lon", 0.0))
			var tags_n: Dictionary = e.get("tags", {})
			if tags_n.is_empty():
				continue
			var layer_n := classify_layer(tags_n)
			var p := projection.latlon_to_local(lat, lon)
			features.append(Types.Feature.new(e.get("id", 0), Types.GeometryKind.NODE, PackedVector2Array([p]), tags_n, layer_n))

	return features