extends CharacterBody2D
class_name PlayerCharacter

#region CONSTANT VARIABLES =========================================================================
enum CHAR_STATES {
  INIT,
  IDLE,
  RUNNING,
  DASHING,
  JUMPING,
  FALLING,
  WALL_SLIDING,
  CLIMBING,
  ATTACKING,
  HURT
}

const LERP_SPEED = 10.0;

const fallImg = preload("res://images/character/WolfFall.png");
const hurtImg = preload("res://images/character/WolfHurt.png");
const idleImg = preload("res://images/character/WolfIdle.png");
const jumpImg = preload("res://images/character/WolfJump.png");
const runImg = preload("res://images/character/WolfRun.png");
const slash1Img = preload("res://images/character/WolfSlash1.png");
const slash2Img = preload("res://images/character/WolfSlash2.png");
const wallSlideImg = preload("res://images/character/WolfWallSlide.png");
const dashImg = preload("res://images/character/WolfDash.png");
#endregion

#region COMPUTED VARIABLES =========================================================================
var isP1 := false;
var isP2 := false;
var inputData := Global.main.templateInputBuffer;
var state: CHAR_STATES = CHAR_STATES.IDLE;
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity");
var isDashSpeed := false;
var coyoteTimeRemaining = CharStats.MAX_COYOTE_TIME;
#endregion

#region BUILT IN FUNCTIONS =========================================================================
func _ready() -> void:
  if(Global.p1_char == null):
    Global.p1_char = self;
    isP1 = true;
  elif(Global.p2_char == null):
    Global.p2_char = self;
    isP2 = true;
  # end if
  
  $DashTimer.wait_time = CharStats.GET_TOTAL_DASH_TIME();
  $JumpTimer.wait_time = CharStats.GET_TOTAL_JUMP_TIME();
# end _init

func _process(delta: float) -> void:  
  if(is_on_floor()):
    resetJumpFlags();
  elif(coyoteTimeRemaining > 0.0):
    coyoteTimeRemaining -= delta;
    
  updateSprite();
  setInputData();
  processState(delta);
  
  move_and_slide();
# end _process
#endregion

#region STATE FUNCTIONS ============================================================================
func processState(delta) -> void:
  match(state):
    CHAR_STATES.INIT:
      doInitState(delta);
    CHAR_STATES.IDLE:
      doIdleState(delta);
    CHAR_STATES.RUNNING:
      doRunningState(delta);
    CHAR_STATES.DASHING:
      doDashingState(delta);
    CHAR_STATES.JUMPING:
      doJumpingState(delta);
    CHAR_STATES.FALLING:
      doFallingState(delta);
    CHAR_STATES.WALL_SLIDING:
      doWallSlidingState(delta);
    CHAR_STATES.CLIMBING:
      doClimbingState(delta);
    CHAR_STATES.ATTACKING:
      doAttackingState(delta);
    CHAR_STATES.HURT:
      doHurtState(delta);
  #end match
#end processState

func doInitState(delta) -> void:
  #TODO: Intro animation
  state = CHAR_STATES.IDLE;
# end doInitState

func doIdleState(delta) -> void:
  updateHorizontalVelocity(delta);
  applyGravity(delta);
  
  neutralStateCheck();
  moveStateCheck();
# end doInitState

func doRunningState(delta) -> void:
  updateHorizontalVelocity(delta);
  applyGravity(delta);
  
  if(roundf(velocity.x) == 0.0):
    neutralStateCheck();
  else:
    moveStateCheck();
# end doInitState

func doDashingState(delta) -> void:
  if($DashTimer.is_stopped()):
    $DashTimer.start();
    
  var dashDirection = inputData["char_h"] if inputData["char_h"] != 0 else $Sprite.scale.x;
  velocity.x = CharStats.GET_TOTAL_DASH_SPEED() * dashDirection;
  
  # if we push a direction we aren't dashing toward, stop dashing
  var isInputInverseOfDirection: bool = (inputData["char_h"] && ((inputData["char_h"] > 0 && $Sprite.scale.x < 0) || (inputData["char_h"] < 0 && $Sprite.scale.x > 0)));
  if (isInputInverseOfDirection || state != CHAR_STATES.DASHING):
    if(!$DashTimer.is_stopped()):
      $DashTimer.stop();
    # end if
    neutralStateCheck();
  elif (isJumpBuffered() && canJump()):
    state = CHAR_STATES.JUMPING;
  #end if
# end doInitState

func doJumpingState(delta) -> void:
  if($JumpTimer.is_stopped()):
    $JumpTimer.start();
    if(inputData["char_dash_held"]):
      isDashSpeed = true;
  velocity.y = CharStats.GET_TOTAL_JUMP_VELOCITY() * -1;
  updateHorizontalVelocity(delta);
  
  if(!inputData["char_jump_held"]):
    if(!$JumpTimer.is_stopped()):
      $JumpTimer.stop();
    # end if
    neutralStateCheck();
# end doInitState

func doFallingState(delta) -> void:
  updateHorizontalVelocity(delta);
  applyGravity(delta);
  
  if (isJumpBuffered() && canJump()):
    state = CHAR_STATES.JUMPING;
  else:
    neutralStateCheck();
# end doFallingState

func doWallSlidingState(delta) -> void:
  resetJumpFlags();
  var lastCollision = get_last_slide_collision();
  var lastCollisionDirection = 0;
  if(lastCollision):
    lastCollisionDirection = sign(lastCollision.get_position().x - global_position.x);
    if(isJumpBuffered()):
      state = CHAR_STATES.JUMPING;
      velocity.x += CharStats.GET_TOTAL_WALK_SPEED() * lastCollisionDirection * -1;
      return
    # end if
  # end if
  
  var isInputTowardWall: bool = (is_on_wall_only() && lastCollisionDirection == sign(inputData["char_h"]));
  if (isInputTowardWall):
    velocity.y = CharStats.GET_TOTAL_WALL_SLIDE_VELOCITY();
  else:
    if(is_on_floor()):
      state = CHAR_STATES.IDLE;
    else:
      state = CHAR_STATES.FALLING;
# end doSlidingState

func doClimbingState(delta) -> void:
  updateVerticalVelocity(delta);
#end doClimbingState

func doAttackingState(delta) -> void:
  pass;
# end doAttackingState

func doHurtState(delta) -> void:
  pass;
# end doAttackingState

func neutralStateCheck() -> void:
  if(state != CHAR_STATES.IDLE && is_on_floor()):
    state = CHAR_STATES.IDLE;
  elif(state != CHAR_STATES.WALL_SLIDING && is_on_wall() && inputData["char_h"] != 0.0):
    state = CHAR_STATES.WALL_SLIDING;
  elif(state != CHAR_STATES.FALLING && !is_on_floor() && !(is_on_wall() && inputData["char_h"] != 0.0)):
    state = CHAR_STATES.FALLING;
# end idleFallOrSlideStateCheck

func moveStateCheck() -> void:
  if(state != CHAR_STATES.DASHING && isDashBuffered() && is_on_floor()):
    state = CHAR_STATES.DASHING;
  elif(state != CHAR_STATES.JUMPING && isJumpBuffered() && canJump()):
    state = CHAR_STATES.JUMPING;
  elif(state != CHAR_STATES.RUNNING && inputData["char_h"] != 0 && is_on_floor()):
    state = CHAR_STATES.RUNNING;
  elif(state != CHAR_STATES.FALLING && !is_on_floor()):
    state = CHAR_STATES.FALLING;
# end moveStateCheck
#endregion

#region SIGNALS ====================================================================================
func _on_dash_timer_timeout() -> void:
  neutralStateCheck();
# end _on_dash_timer_timeout

func _on_jump_timer_timeout() -> void:
  neutralStateCheck();
# end _on_jump_timer_timeout
#endregion

#region UTILITY FUNCTIONS ==========================================================================
func setInputData() -> void:
  if(Global.p1_char != null):
    inputData = Global.main.p1InputBuffer;
  elif(Global.p2_char != null):
    inputData = Global.main.p2InputBuffer;
# end setInputData

func updateHorizontalVelocity(delta) -> void:
  if (inputData["char_h"]):
    velocity.x = move_toward(velocity.x, inputData["char_h"] * (CharStats.GET_TOTAL_DASH_SPEED() if isDashSpeed else CharStats.GET_TOTAL_WALK_SPEED()), CharStats.GET_TOTAL_WALK_SPEED() * delta * LERP_SPEED); 
    #velocity.x = inputData["char_h"] * CharStats.GET_TOTAL_WALK_SPEED();
  else:
    velocity.x = move_toward(velocity.x, 0, CharStats.GET_TOTAL_WALK_SPEED() * delta * LERP_SPEED);
    #velocity.x = 0;
  #end if
# end updateVelocity

func updateVerticalVelocity(delta) -> void:
  if (inputData["char_v"]):
    velocity.y = inputData["char_v"] * delta * CharStats.GET_TOTAL_WALK_SPEED() * -1;
  else:
    velocity.y = 0;
  #end if
# end updateVelocity

func applyGravity(delta) -> void:
  velocity.y = min(CharStats.MAX_VELOCITY, velocity.y + (gravity * delta * 2))
# end applyGravity

func canJump() -> bool:
  return is_on_floor() || coyoteTimeRemaining > 0;
# end canJump

func isJumpBuffered() -> bool:
  return inputData["char_jump_pressed"] || (inputData["char_jump_held"] && inputData["char_jump_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME);
# end isJumpBuffered

func isDashBuffered() -> bool:
  return inputData["char_dash_pressed"] || (inputData["char_dash_held"] && inputData["char_dash_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME);
# end isJumpBuffered

func isAttackBuffered() -> bool:
  return inputData["char_attack_pressed"] || (inputData["char_attack_held"] && inputData["char_attack_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME);
# end isJumpBuffered

func isSpecialBuffered() -> bool:
  return inputData["char_special_pressed"] || (inputData["char_special_held"] && inputData["char_special_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME);
# end isJumpBuffered

func resetJumpFlags() -> void:
  isDashSpeed = false;
  coyoteTimeRemaining = CharStats.MAX_COYOTE_TIME;
# end resetJumpFlags
#endregion

#region SPRITE FUNCTIONS ===========================================================================
func updateSprite() -> void:
  if velocity.x > 0:
    $Sprite.scale.x = 1;
  #end if
  if velocity.x < 0:
    $Sprite.scale.x = -1;
  #end if
  if velocity.x == 0 && inputData["char_h"] != 0:
    $Sprite.scale.x = roundi(inputData["char_h"]);
    
  match(state):
    CHAR_STATES.INIT:
      $Sprite.texture = idleImg;
    CHAR_STATES.IDLE:
      $Sprite.texture = idleImg;
    CHAR_STATES.RUNNING:
      if(velocity.x == 0.0):
        $Sprite.texture = idleImg;
      else:
        $Sprite.texture = runImg;
    CHAR_STATES.DASHING:
      $Sprite.texture = dashImg;
    CHAR_STATES.JUMPING:
      $Sprite.texture = jumpImg;
    CHAR_STATES.FALLING:
      if(velocity.y > 0.0):
        $Sprite.texture = fallImg;
      else:
        $Sprite.texture = jumpImg;
    CHAR_STATES.WALL_SLIDING:
      $Sprite.texture = wallSlideImg;
    CHAR_STATES.CLIMBING:
      $Sprite.texture = idleImg;
    CHAR_STATES.ATTACKING:
      $Sprite.texture = slash1Img;
    CHAR_STATES.HURT:
      $Sprite.texture = hurtImg;
  #end match
# END updateSprite
#endregion
