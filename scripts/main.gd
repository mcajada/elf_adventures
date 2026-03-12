extends Node2D

@onready var info_label: Label = $UI/InfoLabel

func _ready() -> void:
	info_label.text = "Game start"
