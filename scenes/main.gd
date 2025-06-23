extends Node2D
class_name Main

var p1_input_buffer = {
  "p1_char_h": 0.0,
  "p1_char_v": 0.0,
  "p1_char_attack_pressed": false,
  "p1_char_attack_held": false,
  "p1_char_attack_held_time": 0.0,
  "p1_char_special_pressed": false,
  "p1_char_special_held": false,
  "p1_char_special_held_time": 0.0,
  "p1_char_jump_pressed": false,
  "p1_char_jump_held": false,
  "p1_char_jump_held_time": 0.0,
  "p1_char_dash_pressed": false,
  "p1_char_dash_held": false,
  "p1_char_dash_held_time": 0.0,
  "p1_char_interact_pressed": false,
  "p1_char_interact_held": false,
  "p1_char_interact_held_time": 0.0
  #TODO: p2 controls need to be added to the project
};

func _init():
  Global.main = self;
# end _init

func _process(delta: float) -> void:
  process_inputs(delta);
# end _process

func process_inputs(delta) -> void:
  if(Global.p1_char != null):
    p1_input_buffer = {
      "p1_char_h": Input.get_axis("p1_char_left", "p1_char_right"),
      "p1_char_v": Input.get_axis("p1_char_down", "p1_char_up"),
      "p1_char_attack_pressed": Input.is_action_just_pressed("p1_char_attack"),
      "p1_char_attack_held": Input.is_action_pressed("p1_char_attack"),
      "p1_char_attack_held_time": p1_input_buffer["p1_char_attack_held_time"] + delta if Input.is_action_pressed("p1_char_attack") else 0.0,
      "p1_char_special_pressed": Input.is_action_just_pressed("p1_char_special"),
      "p1_char_special_held": Input.is_action_pressed("p1_char_special"),
      "p1_char_special_held_time": p1_input_buffer["p1_char_special_held_time"] + delta if Input.is_action_pressed("p1_char_special") else 0.0,
      "p1_char_jump_pressed": Input.is_action_just_pressed("p1_char_jump"),
      "p1_char_jump_held": Input.is_action_pressed("p1_char_jump"),
      "p1_char_jump_held_time": p1_input_buffer["p1_char_jump_held_time"] + delta if Input.is_action_pressed("p1_char_jump") else 0.0,
      "p1_char_dash_pressed": Input.is_action_just_pressed("p1_char_dash"),
      "p1_char_dash_held": Input.is_action_pressed("p1_char_dash"),
      "p1_char_dash_held_time": p1_input_buffer["p1_char_dash_held_time"] + delta if Input.is_action_pressed("p1_char_dash") else 0.0,
      "p1_char_interact_pressed": Input.is_action_just_pressed("p1_char_interact"),
      "p1_char_interact_held": Input.is_action_pressed("p1_char_interact"),
      "p1_char_interact_held_time": p1_input_buffer["p1_char_interact_held_time"] + delta if Input.is_action_pressed("p1_char_interact") else 0.0
      #TODO: p2 controls need to be added to the project
    };
  # end if
# end process_inputs
