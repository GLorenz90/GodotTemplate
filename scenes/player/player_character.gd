extends CharacterBody2D
class_name PlayerCharacter

#region CONSTANT VARIABLES =========================================================================
const LERP_SPEED = 10.0;
const MAX_ATTACK_STEP = 3;

const fallImg = preload("res://images/character/WolfFall.png");
const hurtImg = preload("res://images/character/WolfHurt.png");
const idleImg = preload("res://images/character/WolfIdle.png");
const jumpImg = preload("res://images/character/WolfJump.png");
const runImg = preload("res://images/character/WolfRun.png");
const slash1Img = preload("res://images/character/WolfSlash1.png");
const slash2Img = preload("res://images/character/WolfSlash2.png");
const slash3Img = preload("res://images/character/WolfSlash3.png");
const slashAirImg = preload("res://images/character/WolfJumpAttack.png");
const slashDashImg = preload("res://images/character/WolfSpecial.png");
const slashWallSlideImg = preload("res://images/character/WolfSlash1.png");
const wallSlideImg = preload("res://images/character/WolfWallSlide.png");
const dashImg = preload("res://images/character/WolfDash.png");
#endregion

#region COMPUTED VARIABLES =========================================================================
var isP1 := false;
var isP2 := false;
var inputData := Global.main.templateInputBuffer;
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity");

var isAirDashSpeed := false;
var coyoteTimeRemaining = CharStats.MAX_COYOTE_TIME;

var charState: Enums.CHAR_STATES = Enums.CHAR_STATES.IDLE;
var nextCharState: Enums.CHAR_STATES = Enums.CHAR_STATES.IDLE;
var statePosition: Enums.STATE_POSITIONS = Enums.STATE_POSITIONS.CHANGE;

var isAttacking := false;
var isHurt := false;

var lastCollision = null;
var lastCollisionDirection := 0.0;
var isInputInverseOfDirection := false;
var isInputTowardWall := false;
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
  $AttackDelayTimer.wait_time = CharStats.GET_TOTAL_ATTACK_DELAY();
# end _init

func _physics_process(delta: float) -> void:  
  debugText();
  if(!is_on_floor() && coyoteTimeRemaining > 0.0):
    coyoteTimeRemaining -= delta;
  # end if   
  setInputData();
  updateCollisionDirection();
  updateInputTowardWall();
  processState(delta);
  updateSprite();
  move_and_slide();
# end _physics_process

func setInputData() -> void:
  if(Global.p1_char != null):
    inputData = Global.main.p1InputBuffer;
  elif(Global.p2_char != null):
    inputData = Global.main.p2InputBuffer;
# end setInputData

func debugText() -> void:
  Global.main.debugLabel.text = Enums.CHAR_STATES.keys()[charState] + '\n' + \
  Enums.STATE_POSITIONS.keys()[statePosition] + '\n' + \
  "vel: " + str(velocity) + '\n' + \
  "floor: " + str(is_on_floor()) + '\n' + \
  "wall: " + str(is_on_wall()) + '\n' + \
  "dash timer " + str(!$DashTimer.is_stopped()) + ": " + str($DashTimer.time_left) + '\n' + \
  "jump timer " + str(!$JumpTimer.is_stopped()) + ": " + str($JumpTimer.time_left) + '\n' + \
  "atk del timer " + str(!$AttackDelayTimer.is_stopped()) + ": " + str($AttackDelayTimer.time_left) + '\n' + \
  "attack timer " + str(!$AttackTimer.is_stopped()) + ": " + str($AttackTimer.time_left);
# end debugText
#endregion

#region STATE FUNCTIONS ============================================================================
func processState(delta) -> void:
  match(statePosition):
    Enums.STATE_POSITIONS.CHANGE:
      processEndingState(delta);
      charState = nextCharState;
      processStartingState(delta);
      processRunningState(delta);
      changeStatePosition(Enums.STATE_POSITIONS.RUN);
    Enums.STATE_POSITIONS.RUN:
      processRunningState(delta);
  # end match
#end processState

func processStartingState(delta) -> void:
  match(charState):
    Enums.CHAR_STATES.INIT:
      startInitState(delta);
    Enums.CHAR_STATES.IDLE:
      startIdleState(delta);
    Enums.CHAR_STATES.RUNNING:
      startRunningState(delta);
    Enums.CHAR_STATES.DASHING:
      startDashingState(delta);
    Enums.CHAR_STATES.JUMPING:
      startJumpingState(delta);
    Enums.CHAR_STATES.FALLING:
      startFallingState(delta);
    Enums.CHAR_STATES.WALL_SLIDING:
      startWallSlidingState(delta);
  #end match
# end processStartingState

func processRunningState(delta) -> void:
  match(charState):
    Enums.CHAR_STATES.INIT:
      runInitState(delta);
    Enums.CHAR_STATES.IDLE:
      runIdleState(delta);
    Enums.CHAR_STATES.RUNNING:
      runRunningState(delta);
    Enums.CHAR_STATES.DASHING:
      runDashingState(delta);
    Enums.CHAR_STATES.JUMPING:
      runJumpingState(delta);
    Enums.CHAR_STATES.FALLING:
      runFallingState(delta);
    Enums.CHAR_STATES.WALL_SLIDING:
      runWallSlidingState(delta);
  #end match
# end processStartingState

func processEndingState(delta) -> void:
  match(charState):
    Enums.CHAR_STATES.INIT:
      endInitState(delta);
    Enums.CHAR_STATES.IDLE:
      endIdleState(delta);
    Enums.CHAR_STATES.RUNNING:
      endRunningState(delta);
    Enums.CHAR_STATES.DASHING:
      endDashingState(delta);
    Enums.CHAR_STATES.JUMPING:
      endJumpingState(delta);
    Enums.CHAR_STATES.FALLING:
      endFallingState(delta);
    Enums.CHAR_STATES.WALL_SLIDING:
      endWallSlidingState(delta);
  #end match
# end processStartingState

func changeCharState(newState: Enums.CHAR_STATES):
  nextCharState = newState;
  changeStatePosition(Enums.STATE_POSITIONS.CHANGE);
  # end if
# end changeState

func changeStatePosition(newStatePosition: Enums.STATE_POSITIONS):
  if(statePosition != newStatePosition):
    statePosition = newStatePosition;
  # end if
# end changeStatePosition
#endregion

#region STARTING STATE FUNCTIONS ===================================================================
func startInitState(_delta) -> void:
  pass;
# end startInitState

func startIdleState(_delta) -> void:
  pass;
# end startIdleState

func startRunningState(delta) -> void:
  updateHorizontalVelocity(delta);
# end startRunningState

func startDashingState(delta) -> void:
  $DashTimer.start();
  updateHorizontalVelocity(delta);
# end startDashingState

func startJumpingState(delta) -> void:
  $JumpTimer.start();
  updateVerticalVelocity(delta);
  isAirDashSpeed = inputData["char_dash_held"];
  inputData["char_jump_held_time"] = 1.0; #prevent double jump from wall buffer
  coyoteTimeRemaining = 0.0;
# end startJumpingState

func startFallingState(delta) -> void:
  updateVerticalVelocity(delta);
# end startFallingState

func startWallSlidingState(delta) -> void:
  updateVerticalVelocity(delta);
# end startWallSlidingState
#endregion

#region RUNNING STATE FUNCTIONS ====================================================================
func runInitState(_delta) -> void:
  #TODO: Intro animation
  changeCharState(Enums.CHAR_STATES.IDLE);
# end runInitState

func runIdleState(delta) -> void:
  if(isDashBuffered()):
    changeCharState(Enums.CHAR_STATES.DASHING);
  elif(isJumpBuffered()):
    changeCharState(Enums.CHAR_STATES.JUMPING);
  elif(!is_on_floor()):
    changeCharState(Enums.CHAR_STATES.FALLING);
  elif(isAttemptingRun(delta)):
    changeCharState(Enums.CHAR_STATES.RUNNING);
  else:
    updateHorizontalVelocity(delta);
    updateVerticalVelocity(delta);
  # end if
# end runInitState

func runRunningState(delta) -> void:
  if(isJumpBuffered()):
    changeCharState(Enums.CHAR_STATES.JUMPING);
  elif(isDashBuffered()):
    changeCharState(Enums.CHAR_STATES.DASHING);
  elif(!is_on_floor()):
    changeCharState(Enums.CHAR_STATES.FALLING);
  elif(velocity.x == 0.0):
    changeCharState(Enums.CHAR_STATES.IDLE);
  else:
    updateHorizontalVelocity(delta);
    updateVerticalVelocity(delta);
  # end if
# end runRunningState

func runDashingState(delta) -> void:
  # if we push a direction we aren't dashing toward, stop dashing
  isInputInverseOfDirection = (inputData["char_h"] && ((inputData["char_h"] > 0 && $Sprite.scale.x < 0) || (inputData["char_h"] < 0 && $Sprite.scale.x > 0)));
  if (isInputInverseOfDirection || $DashTimer.is_stopped() || velocity.x == 0.0):
    if(is_on_floor()):
      if(inputData["char_h"] && velocity.x != 0.0):
        changeCharState(Enums.CHAR_STATES.RUNNING);
      else:
        changeCharState(Enums.CHAR_STATES.IDLE);
    else:
      if(is_on_wall_only()):
        changeCharState(Enums.CHAR_STATES.WALL_SLIDING);
      else:
        changeCharState(Enums.CHAR_STATES.FALLING);
    # end if
  elif (isJumpBuffered()):
    changeCharState(Enums.CHAR_STATES.JUMPING);
  else:
    updateHorizontalVelocity(delta);
# end runDashingState

func runJumpingState(delta) -> void:
  #if still or moving down
  if(velocity.y >= 0.0):
    if(isAttemptingWallSlide()):
      changeCharState(Enums.CHAR_STATES.WALL_SLIDING);
    elif(is_on_floor()):
      changeCharState(Enums.CHAR_STATES.IDLE);
    else:
      changeCharState(Enums.CHAR_STATES.FALLING);
    # end if
  elif(isJumpBuffered()):
    changeCharState(Enums.CHAR_STATES.JUMPING);
  else:
    updateHorizontalVelocity(delta);
    updateVerticalVelocity(delta);
  # end if
# end runInitState

func runFallingState(delta) -> void:  
  if(isAttemptingWallSlide()):
    changeCharState(Enums.CHAR_STATES.WALL_SLIDING);
  elif(isJumpBuffered()):
    changeCharState(Enums.CHAR_STATES.JUMPING);
  elif(is_on_floor()):
    changeCharState(Enums.CHAR_STATES.IDLE);
  else:
    updateHorizontalVelocity(delta);
    updateVerticalVelocity(delta);
  # end if
# end runFallingState

func runWallSlidingState(delta) -> void:
  if(is_on_floor()):
    changeCharState(Enums.CHAR_STATES.IDLE);
  elif(!is_on_wall()):
    changeCharState(Enums.CHAR_STATES.FALLING);
  else:
    if(isJumpBuffered()):
      changeCharState(Enums.CHAR_STATES.JUMPING);
    elif(isAttemptingWallSlide()):
      updateVerticalVelocity(delta);
    else:
      changeCharState(Enums.CHAR_STATES.FALLING);
    # end if
  # end if
# end runSlidingState
#endregion

#region ENDING STATE FUNCTIONS =====================================================================
func endInitState(_delta) -> void:
  pass;
# end endInitState

func endIdleState(_delta) -> void:
  pass;
# end endIdleState

func endRunningState(_delta) -> void:
  pass;
# end endRunningState

func endDashingState(_delta) -> void:
  $DashTimer.stop();
# end endDashingState

func endJumpingState(_delta) -> void:
  $JumpTimer.stop();
  if(nextCharState == Enums.CHAR_STATES.JUMPING && is_on_wall()):
    isAirDashSpeed = inputData["char_dash_held"];
    velocity.x = (CharStats.GET_TOTAL_DASH_SPEED() if isAirDashSpeed else CharStats.GET_TOTAL_WALK_SPEED()) * lastCollisionDirection * -1.0;
  # end if
# end endJumpingState

func endFallingState(_delta) -> void:
  resetJumpFlags();
  if(nextCharState == Enums.CHAR_STATES.JUMPING && is_on_wall()):
    isAirDashSpeed = inputData["char_dash_held"];
    velocity.x = (CharStats.GET_TOTAL_DASH_SPEED() if isAirDashSpeed else CharStats.GET_TOTAL_WALK_SPEED()) * lastCollisionDirection * -1.0;
  # end if
# end endFallingState

func endWallSlidingState(_delta) -> void:
  if(nextCharState == Enums.CHAR_STATES.JUMPING):
    isAirDashSpeed = inputData["char_dash_held"];
    velocity.x = (CharStats.GET_TOTAL_DASH_SPEED() if isAirDashSpeed else CharStats.GET_TOTAL_WALK_SPEED()) * lastCollisionDirection * -1.0;
  else:
    velocity.x = CharStats.WALL_NUDGE_SPEED * lastCollisionDirection * -1.0;
  # end if
  lastCollisionDirection = 0;
# end endWallSlidingState
#endregion

#region UTILITY FUNCTIONS ==========================================================================
func updateHorizontalVelocity(delta) -> void:
  if(charState == Enums.CHAR_STATES.DASHING):
    var dashDirection = inputData["char_h"] if inputData["char_h"] != 0 else $Sprite.scale.x;
    velocity.x = CharStats.GET_TOTAL_DASH_SPEED() * dashDirection;
  elif(inputData["char_h"]):
    velocity.x = move_toward(velocity.x, inputData["char_h"] * (CharStats.GET_TOTAL_DASH_SPEED() if isAirDashSpeed && !is_on_floor() else CharStats.GET_TOTAL_WALK_SPEED()), CharStats.GET_TOTAL_WALK_SPEED() * delta * LERP_SPEED); 
    #velocity.x = inputData["char_h"] * CharStats.GET_TOTAL_WALK_SPEED();
  else:
    velocity.x = move_toward(velocity.x, 0, CharStats.GET_TOTAL_WALK_SPEED() * delta * LERP_SPEED);
  #end if
# end updateVelocity

func updateVerticalVelocity(delta) -> void:
  if(charState == Enums.CHAR_STATES.WALL_SLIDING):
    velocity.y = CharStats.GET_TOTAL_WALL_SLIDE_VELOCITY();
  elif (charState == Enums.CHAR_STATES.CLIMBING):
    velocity.y = inputData["char_v"] * CharStats.GET_TOTAL_WALK_SPEED() * -1;
  elif(charState == Enums.CHAR_STATES.JUMPING && inputData["char_jump_held"] && !$JumpTimer.is_stopped()):
    velocity.y = CharStats.GET_TOTAL_JUMP_VELOCITY() * -1;
  elif (!is_on_floor()):
    velocity.y = clamp(velocity.y + (gravity * delta * 2), -CharStats.MAX_VELOCITY, CharStats.MAX_VELOCITY)
  else:
    velocity.y = 0;
  #end if
# end updateVelocity

func canJump() -> bool:
  return is_on_floor() || is_on_wall() || coyoteTimeRemaining > 0.0;
# end canJump

func isJumpBuffered() -> bool:
  return canJump() && (inputData["char_jump_pressed"] || (inputData["char_jump_held"] && inputData["char_jump_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME));
# end isJumpBuffered

func isDashBuffered() -> bool:
  return is_on_floor() && (inputData["char_dash_pressed"] || (inputData["char_dash_held"] && inputData["char_dash_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME));
# end isDashBuffered

func canAttack() -> bool:
  return $AttackDelayTimer.is_stopped();
# end isAttackBlocked

func isAttackBuffered() -> bool:
  return canAttack() && (inputData["char_attack_pressed"] || (inputData["char_attack_held"] && inputData["char_attack_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME));
# end isAttackBuffered

func isSpecialBuffered() -> bool:
  return canAttack() && (inputData["char_special_pressed"] || (inputData["char_special_held"] && inputData["char_special_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME));
# end isSpecialBuffered

func isAttemptingRun(delta) -> bool:
  updateHorizontalVelocity(delta);
  return (inputData["char_h"] != 0.0) && is_on_floor() && !isInputTowardWall && !test_move(global_transform, velocity * delta);
# end isAttemptingRun

func isAttemptingWallSlide() -> bool:
  return !is_on_floor() && isInputTowardWall;
# end isAttemptingWallSlide

func updateCollisionDirection() -> void:
  lastCollision = get_last_slide_collision();
  if(is_on_wall()):
    lastCollisionDirection = sign(lastCollision.get_position().x - global_position.x);
  else:
    lastCollisionDirection = 0;
  # end if
# end updateCollisionDirection

func updateInputTowardWall() -> void:
  isInputTowardWall = lastCollisionDirection != 0 && inputData["char_h"] != 0.0 && lastCollisionDirection == sign(inputData["char_h"]);
  # end if
# end updateInputTowardWall

func startAttacking() -> void:
  isAttacking = true;
  $AttackDelayTimer.start();
  $AttackTimer.start();
# end startAttacking

func stopAttacking() -> void:
  isAttacking = false;
  $AttackDelayTimer.stop();
  $AttackTimer.stop();
# end stopAttacking

func resetJumpFlags() -> void:
  isAirDashSpeed = false;
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
  
  if(isHurt):
    $Sprite.texture = hurtImg;
  else: 
    match(charState):
      Enums.CHAR_STATES.INIT:
        $Sprite.texture = idleImg;
      Enums.CHAR_STATES.IDLE:
        $Sprite.texture = idleImg;
      Enums.CHAR_STATES.RUNNING:
        $Sprite.texture = runImg;
      Enums.CHAR_STATES.DASHING:
        $Sprite.texture = dashImg;
      Enums.CHAR_STATES.JUMPING:
        $Sprite.texture = jumpImg;
      Enums.CHAR_STATES.FALLING:
        $Sprite.texture = fallImg;
      Enums.CHAR_STATES.WALL_SLIDING:
        $Sprite.texture = wallSlideImg;
      Enums.CHAR_STATES.CLIMBING:
        $Sprite.texture = idleImg;
    #end match
# end updateSprite
#endregion
