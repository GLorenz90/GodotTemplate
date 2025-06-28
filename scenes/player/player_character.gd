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
var charState: Enums.CHAR_STATES = Enums.CHAR_STATES.IDLE;
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity");
var isDashSpeed := false;
var attackState: Enums.ATTACK_STATES = Enums.ATTACK_STATES.NONE;
var coyoteTimeRemaining = CharStats.MAX_COYOTE_TIME;

var isDashing := false;
var isJumping := false;

var isAttacking := false;
var isHurt := false;
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
  setInputData();
  groundCheck(delta);
  processState(delta);
  updateSprite();
  
  move_and_slide();
# end _process
#endregion

#region STATE FUNCTIONS ============================================================================
func processState(delta) -> void:
  match(charState):
    Enums.CHAR_STATES.INIT:
      doInitState(delta);
    Enums.CHAR_STATES.IDLE:
      doIdleState(delta);
    Enums.CHAR_STATES.RUNNING:
      doRunningState(delta);
    Enums.CHAR_STATES.DASHING:
      doDashingState(delta);
    Enums.CHAR_STATES.JUMPING:
      doJumpingState(delta);
    Enums.CHAR_STATES.FALLING:
      doFallingState(delta);
    Enums.CHAR_STATES.WALL_SLIDING:
      doWallSlidingState(delta);
    Enums.CHAR_STATES.CLIMBING:
      doClimbingState(delta);
  #end match
#end processState

func doInitState(_delta) -> void:
  #TODO: Intro animation
  changeCharState(Enums.CHAR_STATES.IDLE);
# end doInitState

func doIdleState(delta) -> void:
  updateHorizontalVelocity(delta);
  applyGravity(delta);
  
  neutralStateCheck();
  moveStateCheck();
  #attackStateCheck();
# end doInitState

func doRunningState(delta) -> void:
  updateHorizontalVelocity(delta);
  applyGravity(delta);
  
  if(roundf(velocity.x) == 0.0):
    neutralStateCheck();
  else:
    moveStateCheck();
  #attackStateCheck();
# end doInitState

func doDashingState(_delta) -> void:
  if(!isDashing):
    startDashing();
    
  var dashDirection = inputData["char_h"] if inputData["char_h"] != 0 else $Sprite.scale.x;
  velocity.x = CharStats.GET_TOTAL_DASH_SPEED() * dashDirection;
  
  # if we push a direction we aren't dashing toward, stop dashing
  var isInputInverseOfDirection: bool = (inputData["char_h"] && ((inputData["char_h"] > 0 && $Sprite.scale.x < 0) || (inputData["char_h"] < 0 && $Sprite.scale.x > 0)));
  if (isInputInverseOfDirection || $DashTimer.is_stopped() || roundf(velocity.x) == 0.0):
    stopDashing();
    neutralStateCheck();
  elif (isJumpBuffered()):
    stopDashing();
    changeCharState(Enums.CHAR_STATES.JUMPING);
  # end if
  #attackStateCheck();
# end doInitState

func doJumpingState(delta) -> void:
  if(!isJumping):
    startJumping();
    if(inputData["char_dash_held"]):
      isDashSpeed = true;
      
  updateHorizontalVelocity(delta);
  if(inputData["char_jump_held"] && !$JumpTimer.is_stopped()):
    velocity.y = CharStats.GET_TOTAL_JUMP_VELOCITY() * -1;
  elif(velocity.y < 0.0):
    applyGravity(delta);
    if(isTryingToWallSlide()):
      changeCharState(Enums.CHAR_STATES.WALL_SLIDING);
      stopJumping();
  else:
    stopJumping();
    neutralStateCheck();
    # end if
  #attackStateCheck();
# end doInitState

func doFallingState(delta) -> void:
  updateHorizontalVelocity(delta);
  applyGravity(delta);
  
  if (isJumpBuffered()):
    changeCharState(Enums.CHAR_STATES.JUMPING);
  else:
    neutralStateCheck();
    #attackStateCheck();
# end doFallingState

func doWallSlidingState(delta) -> void:
  resetJumpFlags();
  var lastCollision = get_last_slide_collision();
  var lastCollisionDirection = 0;
  if(lastCollision):
    lastCollisionDirection = sign(lastCollision.get_position().x - global_position.x);
    if(isJumpBuffered()):
      changeCharState(Enums.CHAR_STATES.JUMPING);
      # Move away from the wall when we jump
      velocity.x += CharStats.GET_TOTAL_WALK_SPEED() * lastCollisionDirection * -1;
      return
    # end if
  # end if
  
  var isInputTowardWall: bool = (is_on_wall_only() && lastCollisionDirection == sign(inputData["char_h"]));
  if (isInputTowardWall && !is_on_floor()):
    updateVerticalVelocity(delta);
    #attackStateCheck();
  else:
    # nudge off of wall
    velocity.x += CharStats.GET_TOTAL_WALK_SPEED() * lastCollisionDirection * -.5;
    neutralStateCheck();
    resetJumpFlags();
# end doSlidingState

func doClimbingState(delta) -> void:
  updateVerticalVelocity(delta);
#end doClimbingState

func neutralStateCheck() -> void:
  if(isDashBuffered()):
    changeCharState(Enums.CHAR_STATES.DASHING);
  elif(is_on_floor()):
    changeCharState(Enums.CHAR_STATES.IDLE);
  elif(is_on_wall() && inputData["char_h"] != 0.0):
    changeCharState(Enums.CHAR_STATES.WALL_SLIDING);
  elif(!is_on_floor()):
    changeCharState(Enums.CHAR_STATES.FALLING);
# end idleFallOrSlideStateCheck

func moveStateCheck() -> void:
  if(isDashBuffered()):
    changeCharState(Enums.CHAR_STATES.DASHING);
  elif(isJumpBuffered()):
    changeCharState(Enums.CHAR_STATES.JUMPING);
  elif(isTryingToRun()):
    changeCharState(Enums.CHAR_STATES.RUNNING);
  elif(!is_on_floor()):
    changeCharState(Enums.CHAR_STATES.FALLING);
# end moveStateCheck

#func attackStateCheck() -> void:
  #if(isAttackBuffered()):
    #$AttackDelayTimer.stop();
    #$AttackTimer.stop();
    #if(is_on_floor()):
      #if(isDashing):
        #print("SLASH_DASH");
        #attackState = Enums.ATTACK_STATES.SLASH_DASH;
      #else:
        #match(attackState):
          #Enums.ATTACK_STATES.SLASH_2:
            #attackState = Enums.ATTACK_STATES.SLASH_3;
          #Enums.ATTACK_STATES.SLASH_1:
            #attackState = Enums.ATTACK_STATES.SLASH_2;
          #Enums.ATTACK_STATES.NONE:
            #attackState = Enums.ATTACK_STATES.SLASH_1;
        ## end match
      ## end if
    #elif(is_on_wall()):
      #attackState = Enums.ATTACK_STATES.SLASH_WALL_SLIDE;
    #elif(!is_on_floor() && !is_on_wall()):
      #attackState = Enums.ATTACK_STATES.SLASH_AIR;
    ## end if
  ## end if
## end attackStateCheck

func changeCharState(newState: Enums.CHAR_STATES):
  if(charState != newState):
    charState = newState;
# end changeState
#endregion

#region SIGNALS ====================================================================================
func _on_attack_timer_timeout() -> void:
  $AttackDelayTimer.stop();
  attackState = Enums.ATTACK_STATES.NONE;
# end _on_attack_timer_timeout

#endregion

#region UTILITY FUNCTIONS ==========================================================================
func groundCheck(delta) -> void:
  if(is_on_floor()):
    resetJumpFlags();
  elif(coyoteTimeRemaining > 0.0):
    coyoteTimeRemaining -= delta;
# end groundCheck

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

func updateVerticalVelocity(_delta) -> void:
  if(is_on_wall()):
    velocity.y = CharStats.GET_TOTAL_WALL_SLIDE_VELOCITY();
  elif (inputData["char_v"] && charState == Enums.CHAR_STATES.CLIMBING):
    velocity.y = inputData["char_v"] * CharStats.GET_TOTAL_WALK_SPEED() * -1;
  else:
    velocity.y = 0;
  #end if
# end updateVelocity

func applyGravity(delta) -> void:
  velocity.y = clamp(velocity.y + (gravity * delta * 2), -CharStats.MAX_VELOCITY, CharStats.MAX_VELOCITY)
# end applyGravity

func canJump() -> bool:
  return is_on_floor() || is_on_wall() || coyoteTimeRemaining > 0;
# end canJump

func isJumpBuffered() -> bool:
  return canJump() && (inputData["char_jump_pressed"] || (inputData["char_jump_held"] && inputData["char_jump_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME));
# end isJumpBuffered

func isDashBuffered() -> bool:
  return is_on_floor() && (inputData["char_dash_pressed"] || (inputData["char_dash_held"] && inputData["char_dash_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME));
# end isDashBuffered

func canAttack() -> bool:
  return $AttackDelayTimer.is_stopped() && CharStats.COMBO_ATTACK_STATES.has(attackState);
# end isAttackBlocked

func isAttackBuffered() -> bool:
  return canAttack() && (inputData["char_attack_pressed"] || (inputData["char_attack_held"] && inputData["char_attack_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME));
# end isAttackBuffered

func isSpecialBuffered() -> bool:
  return canAttack() && (inputData["char_special_pressed"] || (inputData["char_special_held"] && inputData["char_special_held_time"] <= CharStats.MAX_INPUT_BUFFER_TIME));
# end isSpecialBuffered

func isTryingToRun() -> bool:
  return inputData["char_h"] != 0 && is_on_floor();
# end isTryingToRun

func isTryingToWallSlide() -> bool:
  return is_on_wall() && inputData["char_h"] != 0.0;
# end isTryingToWallSlide

func startJumping() -> void:
  isJumping = true;
  $JumpTimer.start();
# end stopJumping

func stopJumping() -> void:
  isJumping = false;
  $JumpTimer.stop();
# end stopJumping

func startDashing() -> void:
  isDashing = true;
  $DashTimer.start();
# end startDashing

func stopDashing() -> void:
  isDashing = false;
  $DashTimer.stop();
# end stopDashing

func startAttacking() -> void:
  isAttacking = true;
  $AttackDelayTimer.start();
  $AttackTimer.start();
# end stopDashing

func stopAttacking() -> void:
  isAttacking = false;
  $AttackDelayTimer.stop();
  $AttackTimer.stop();
# end stopDashing

func resetJumpFlags() -> void:
  $JumpTimer.stop();
  isDashSpeed = false;
  coyoteTimeRemaining = CharStats.MAX_COYOTE_TIME;
# end resetJumpFlags

func debugText() -> void:
  Global.main.debugLabel.text = Enums.CHAR_STATES.keys()[charState] + '\n' + \
  Enums.ATTACK_STATES.keys()[attackState] + '\n' + \
  str(velocity) + '\n' + \
  "dash timer " + str(!$DashTimer.is_stopped()) + ": " + str($DashTimer.time_left) + '\n' + \
  "jump timer " + str(!$JumpTimer.is_stopped()) + ": " + str($JumpTimer.time_left) + '\n' + \
  "atk del timer " + str(!$AttackDelayTimer.is_stopped()) + ": " + str($AttackDelayTimer.time_left) + '\n' + \
  "attack timer " + str(!$AttackTimer.is_stopped()) + ": " + str($AttackTimer.time_left);
# end debugText
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
  elif(isAttacking):
    match(attackState):     
      Enums.ATTACK_STATES.NONE:
        $Sprite.texture = idleImg;
      Enums.ATTACK_STATES.SLASH_1:
        $Sprite.texture = slash1Img;
      Enums.ATTACK_STATES.SLASH_2:
        $Sprite.texture = slash2Img;
      Enums.ATTACK_STATES.SLASH_3:
        $Sprite.texture = slash3Img;
      Enums.ATTACK_STATES.SLASH_AIR:
        $Sprite.texture = slashAirImg;
      Enums.ATTACK_STATES.SLASH_DASH:
        $Sprite.texture = slashDashImg;
      Enums.ATTACK_STATES.SLASH_WALL_SLIDE:
        $Sprite.texture = slashWallSlideImg;
    #end match
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
# END updateSprite
#endregion
