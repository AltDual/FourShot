class_name WeaponResource
extends Resource

@export var weapon_name: String = "Pistol"
@export var damage: int = 1000
@export var fire_rate: float = 0.05
@export var bullet_speed: float = 300.0
@export var bullet_range: float = 800.0
@export var mag_size: int = 30     # How much ammo the gun holds
@export var reload_time: float = 1.5 # How long it takes to reload in seconds

@export var pattern: String = "circle"  # "single", "spread", "circle"
@export var pellet_count: int = 5
@export var spread_angle: float = 30.0

@export var is_automatic: bool = false

@export var weapon_sprite_side: Texture2D

var current_ammo: int = -1
