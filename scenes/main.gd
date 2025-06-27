extends Node2D
class_name Main

var debugLabel;

const templateInputBuffer := {
  "char_h": 0.0,
  "char_v": 0.0,
  "char_vector": Vector2(0.0, 0.0),
  "char_attack_pressed": false,
  "char_attack_held": false,
  "char_attack_held_time": 0.0,
  "char_special_pressed": false,
  "char_special_held": false,
  "char_special_held_time": 0.0,
  "char_jump_pressed": false,
  "char_jump_held": false,
  "char_jump_held_time": 0.0,
  "char_dash_pressed": false,
  "char_dash_held": false,
  "char_dash_held_time": 0.0,
  "char_interact_pressed": false,
  "char_interact_held": false,
  "char_interact_held_time": 0.0
  #TODO: p2 controls need to be added to the project
};

var p1InputBuffer := templateInputBuffer;
var p2InputBuffer := templateInputBuffer;

func _init():
  Global.main = self;
# end _init

func _ready() -> void:
  debugLabel = $SubViewportContainer/SubViewport/SceneParent/Label;
# end _ready

func _process(delta: float) -> void:
  process_inputs(delta);
# end _process

func process_inputs(delta) -> void:
  if(Global.p1_char != null):
    p1InputBuffer = {
      "char_h": Input.get_axis("p1_char_left", "p1_char_right"),
      "char_v": Input.get_axis("p1_char_down", "p1_char_up"),
      "char_vector": Vector2(Input.get_axis("p1_char_left", "p1_char_right"), Input.get_axis("p1_char_down", "p1_char_up")),
      "char_attack_pressed": Input.is_action_just_pressed("p1_char_attack"),
      "char_attack_held": Input.is_action_pressed("p1_char_attack"),
      "char_attack_held_time": p1InputBuffer["char_attack_held_time"] + delta if Input.is_action_pressed("p1_char_attack") else 0.0,
      "char_special_pressed": Input.is_action_just_pressed("p1_char_special"),
      "char_special_held": Input.is_action_pressed("p1_char_special"),
      "char_special_held_time": p1InputBuffer["char_special_held_time"] + delta if Input.is_action_pressed("p1_char_special") else 0.0,
      "char_jump_pressed": Input.is_action_just_pressed("p1_char_jump"),
      "char_jump_held": Input.is_action_pressed("p1_char_jump"),
      "char_jump_held_time": p1InputBuffer["char_jump_held_time"] + delta if Input.is_action_pressed("p1_char_jump") else 0.0,
      "char_dash_pressed": Input.is_action_just_pressed("p1_char_dash"),
      "char_dash_held": Input.is_action_pressed("p1_char_dash"),
      "char_dash_held_time": p1InputBuffer["char_dash_held_time"] + delta if Input.is_action_pressed("p1_char_dash") else 0.0,
      "char_interact_pressed": Input.is_action_just_pressed("p1_char_interact"),
      "char_interact_held": Input.is_action_pressed("p1_char_interact"),
      "char_interact_held_time": p1InputBuffer["char_interact_held_time"] + delta if Input.is_action_pressed("p1_char_interact") else 0.0
    };
  # end if
  #debugLabel.text = "Debug:" \
#+ "\n------ Inputs P1 ------" \
#+ "\nchar_h: " + str(p1InputBuffer["char_h"]) \
#+ "\nchar_v: " + str(p1InputBuffer["char_v"]) \
#+ "\nchar_vector: " + str(p1InputBuffer["char_vector"]) \
#+ "\nchar_attack_pressed: " + str(p1InputBuffer["char_attack_pressed"]) \
#+ "\nchar_attack_held: " + str(p1InputBuffer["char_attack_held"]) \
#+ "\nchar_attack_held_time: " + str(p1InputBuffer["char_attack_held_time"]) \
#+ "\nchar_special_pressed: " + str(p1InputBuffer["char_special_pressed"]) \
#+ "\nchar_special_held: " + str(p1InputBuffer["char_special_held"]) \
#+ "\nchar_special_held_time: " + str(p1InputBuffer["char_special_held_time"]) \
#+ "\nchar_jump_pressed: " + str(p1InputBuffer["char_jump_pressed"]) \
#+ "\nchar_jump_held: " + str(p1InputBuffer["char_jump_held"]) \
#+ "\nchar_jump_held_time: " + str(p1InputBuffer["char_jump_held_time"]) \
#+ "\nchar_dash_pressed: " + str(p1InputBuffer["char_dash_pressed"]) \
#+ "\nchar_dash_held: " + str(p1InputBuffer["char_dash_held"]) \
#+ "\nchar_dash_held_time: " + str(p1InputBuffer["char_dash_held_time"]) \
#+ "\nchar_interact_pressed: " + str(p1InputBuffer["char_interact_pressed"]) \
#+ "\nchar_interact_held: " + str(p1InputBuffer["char_interact_held"]) \
#+ "\nchar_interact_held_time: " + str(p1InputBuffer["char_interact_held_time"])
# end process_inputs
