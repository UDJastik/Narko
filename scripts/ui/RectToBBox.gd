extends Resource

class_name RectToBBox

# Конвертер требует двух коллбеков: из экранных координат в географические (lat, lon)
# и доступ к узлу камеры/карты для вычисления координат мировых границ по пикселям.
# Чтобы не привязываться к конкретной реализации карты, используем переданные Callables.

@export var screen_to_latlon: Callable # Callable(Vector2) -> Vector2(lat, lon)

func to_bbox(rect: Rect2) -> Dictionary:
    if not screen_to_latlon or not screen_to_latlon.is_valid():
        return {}
    var p0: Vector2 = rect.position
    var p1: Vector2 = rect.position + rect.size

    var tl: Vector2 = screen_to_latlon.call(Vector2(p0.x, p0.y))
    var br: Vector2 = screen_to_latlon.call(Vector2(p1.x, p1.y))

    var min_lat = min(tl.x, br.x)
    var max_lat = max(tl.x, br.x)
    var min_lon = min(tl.y, br.y)
    var max_lon = max(tl.y, br.y)

    return {
        "min_lat": min_lat,
        "min_lon": min_lon,
        "max_lat": max_lat,
        "max_lon": max_lon,
    }