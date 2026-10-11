class_name SimRng
extends RefCounted
## Seeded random source for the simulation. Every roll in a game goes through one of
## these so a game is reproducible from its seed.

var _rng := RandomNumberGenerator.new()
var seed_value: int


func _init(p_seed: int = 0) -> void:
	seed_value = p_seed
	_rng.seed = p_seed


## Uniform integer 1..n inclusive (a die).
func d(n: int) -> int:
	return _rng.randi_range(1, n)


## Uniform integer lo..hi inclusive.
func between(lo: int, hi: int) -> int:
	return _rng.randi_range(lo, hi)


## Uniform 0..n-1, matching C's rand() % n idiom used upstream.
func below(n: int) -> int:
	return _rng.randi_range(0, n - 1)


## True with probability p percent.
func chance(p: int) -> bool:
	return d(100) <= p


func gaussian(mean: float, sd: float) -> float:
	return _rng.randfn(mean, sd)


func pick(arr: Array) -> Variant:
	return arr[_rng.randi_range(0, arr.size() - 1)]


func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func save_state() -> int:
	return _rng.state


func restore_state(s: int) -> void:
	_rng.state = s
