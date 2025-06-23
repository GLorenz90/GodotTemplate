extends CharacterBody2D
class_name PlayerCharacter

@export var SPEED := 500.0;
@export var JUMP_VELOCITY := 400.0;
@export var MAX_SPEED := 1000;
@export var MAX_COYOTE_TIME := 0.2;

func _init() -> void:
  if(Global.p1_char == null):
    Global.p1_char = self;
  elif(Global.p2_char == null):
    Global.p2_char = self;
# end _init
