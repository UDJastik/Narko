extends Resource

class_name OSMTypes

enum GeometryKind { NODE, WAY, RELATION }

enum FeatureLayer {
	UNKNOWN,
	ROAD,
	BUILDING,
	WATER,
	GREEN,
	LANDUSE,
	POI,
	BOUNDARY
}

class Feature extends Resource:
	var id: int
	var geometry_kind: int
	var nodes: PackedVector2Array = []
	var tags: Dictionary = {}
	var layer: int = FeatureLayer.UNKNOWN

	func _init(_id: int = 0, _gk: int = GeometryKind.NODE, _nodes: PackedVector2Array = [], _tags: Dictionary = {}, _layer: int = FeatureLayer.UNKNOWN):
		id = _id
		geometry_kind = _gk
		nodes = _nodes
		tags = _tags
		layer = _layer