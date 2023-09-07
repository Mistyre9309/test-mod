ACT_SPIN_POUND_LAND =           allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_ATTACKING)
ACT_SPIN_JUMP =                 allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_SPIN_POUND =                allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING)

ANGLE_QUEUE_SIZE = 9
SPIN_TIMER_SUCCESSFUL_INPUT = 4

--function spin_checker(m)
--  if (m.controller.buttonDown & Y_BUTTON) ~= 0 then
--    set_mario_action(m,ACT_SPIN_JUMP,0)
--  end
--end

function mario_update_spin_input(m)
  local e = gMarioStateExtras[m.playerIndex]
  local rawAngle = atan2s(-m.controller.stickY, m.controller.stickX)
  e.spinInput = 0

  -- prevent issues due to the frame going out of the dead zone registering the last angle as 0
  if e.lastIntendedMag > 0.5 and m.intendedMag > 0.5 then
      local angleOverFrames = 0
      local thisFrameDelta = 0
      local i = 0

      local newDirection = e.spinDirection
      local signedOverflow = 0

      if rawAngle < e.stickLastAngle then
          if e.stickLastAngle - rawAngle > 0x8000 then
              signedOverflow = 1
          end
          if signedOverflow ~= 0 then
              newDirection = 1
          else
              newDirection = -1
          end
      elseif rawAngle > e.stickLastAngle then
          if rawAngle - e.stickLastAngle > 0x8000 then
              signedOverflow = 1
          end
          if signedOverflow ~= 0 then
              newDirection = -1
          else
              newDirection = 1
          end
      end

      if e.spinDirection ~= newDirection then
          for i=0,(ANGLE_QUEUE_SIZE-1) do
              e.angleDeltaQueue[i] = 0
          end
          e.spinDirection = newDirection
      else
          for i=(ANGLE_QUEUE_SIZE-1),1,-1 do
              e.angleDeltaQueue[i] = e.angleDeltaQueue[i-1]
              angleOverFrames = angleOverFrames + e.angleDeltaQueue[i]
          end
      end

      if e.spinDirection < 0 then
          if signedOverflow ~= 0 then
              thisFrameDelta = math.floor((1.0*e.stickLastAngle + 0x10000) - rawAngle)
          else
              thisFrameDelta = e.stickLastAngle - rawAngle
          end
      elseif e.spinDirection > 0 then
          if signedOverflow ~= 0 then
              thisFrameDelta = math.floor(1.0*rawAngle + 0x10000 - e.stickLastAngle)
          else
              thisFrameDelta = rawAngle - e.stickLastAngle
          end
      end

      e.angleDeltaQueue[0] = thisFrameDelta
      angleOverFrames = angleOverFrames + thisFrameDelta

      if angleOverFrames >= 0xA000 then
          e.spinBufferTimer = SPIN_TIMER_SUCCESSFUL_INPUT
      end


      -- allow a buffer after a successful input so that you can switch directions
      if e.spinBufferTimer > 0 then
          e.spinInput = 1
          e.spinBufferTimer = e.spinBufferTimer - 1
      end
  else
      e.spinDirection = 0
      e.spinBufferTimer = 0
  end

  e.stickLastAngle = rawAngle
  e.lastIntendedMag = m.intendedMag
end

function act_spin_jump(m)
  local e = gMarioStateExtras[m.playerIndex]
  if m.actionTimer == 0 then
      -- determine clockwise/counter-clockwise spin
      if e.spinDirection < 0 then
          m.actionState = 1
      end
  elseif m.actionTimer == 1 or m.actionTimer == 4 then
      play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
  end

  local spinDirFactor = 1  -- negative for clockwise, positive for counter-clockwise
  if m.actionState == 1 then
      spinDirFactor = -1
  end

  if (m.input & INPUT_B_PRESSED) ~= 0 then
      return set_mario_action(m, ACT_DIVE, 0)
  end

  if (m.input & INPUT_Z_PRESSED) ~= 0 then
      play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)

      m.vel.y = -50.0
      mario_set_forward_vel(m, 0.0)

      -- choose which direction to be facing on land (practically random if no input)
      if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
          m.faceAngle.y = m.intendedYaw
      else
          m.faceAngle.y = limit_angle(e.rotAngle)
      end

      return set_mario_action(m, ACT_SPIN_POUND, m.actionState)
  end

  play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, CHAR_SOUND_YAHOO)

  common_air_action_step(m, ACT_DOUBLE_JUMP_LAND, MARIO_ANIM_TWIRL,
                         AIR_STEP_CHECK_HANG)

  e.rotAngle = e.rotAngle + 0x2867
  if (e.rotAngle >  0x10000) then e.rotAngle = e.rotAngle - 0x10000 end
  if (e.rotAngle < -0x10000) then e.rotAngle = e.rotAngle + 0x10000 end
  m.marioObj.header.gfx.angle.y = limit_angle(m.marioObj.header.gfx.angle.y + (e.rotAngle * spinDirFactor))

  m.actionTimer = m.actionTimer + 1

  return false
end

function act_spin_jump_gravity(m)
  if (m.flags & MARIO_WING_CAP) ~= 0 and m.vel.y < 0.0 and (m.input & INPUT_A_DOWN) ~= 0 then
      m.marioBodyState.wingFlutter = 1
      m.vel.y = m.vel.y - 0.7
      if m.vel.y < -37.5 then
          m.vel.y = m.vel.y + 1.4
          if m.vel.y > -37.5 then
              m.vel.y = -37.5
          end
      end
  else
      if m.vel.y > 0 then
          m.vel.y = m.vel.y - 4
      else
          m.vel.y = m.vel.y - 1.4
      end

      if m.vel.y < -75.0 then
          m.vel.y = -75.0
      end
  end

  return 0
end

function act_spin_pound(m)
    local e = gMarioStateExtras[m.playerIndex]
    if m.actionTimer == 0 then
        m.actionState = m.actionArg
    end

    local spinDirFactor = 1  -- negative for clockwise, positive for counter-clockwise
    if m.actionState == 1 then spinDirFactor = -1 end

    set_mario_animation(m, MARIO_ANIM_TWIRL)

    if (m.input & INPUT_B_PRESSED) ~= 0 then
        mario_set_forward_vel(m, 10.0)
        m.vel.y = 35
        set_mario_action(m, ACT_DIVE, 0)
    end

    local stepResult = perform_air_step(m, 0)
    if stepResult == AIR_STEP_LANDED then
        if should_get_stuck_in_ground(m) ~= 0 then
            queue_rumble_data_mario(m, 5, 80)
            play_sound(CHAR_SOUND_OOOF2, m.marioObj.header.gfx.cameraToObject)
            m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE
            set_mario_action(m, ACT_BUTT_STUCK_IN_GROUND, 0)
        else
            play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_HEAVY_LANDING)
            if check_fall_damage(m, ACT_HARD_BACKWARD_GROUND_KB) == 0 then
                m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE | PARTICLE_HORIZONTAL_STAR
                set_mario_action(m, ACT_SPIN_POUND_LAND, 0)
            end
        end
        set_camera_shake_from_hit(SHAKE_GROUND_POUND)
    elseif stepResult == AIR_STEP_HIT_WALL then
        mario_set_forward_vel(m, -16.0)
        if m.vel.y > 0.0 then
            m.vel.y = 0.0
        end

        m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
        set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
    end

    -- set facing direction
    -- not part of original Extended Moveset
    local yawDiff = m.faceAngle.y - m.intendedYaw
    e.rotAngle = limit_angle(e.rotAngle + yawDiff)
    m.faceAngle.y = m.intendedYaw

    e.rotAngle = e.rotAngle + 0x3053
    if e.rotAngle >  0x10000 then e.rotAngle = e.rotAngle - 0x10000 end
    if e.rotAngle < -0x10000 then e.rotAngle = e.rotAngle + 0x10000 end
    m.marioObj.header.gfx.angle.y = limit_angle(m.marioObj.header.gfx.angle.y + e.rotAngle * spinDirFactor)

    m.actionTimer = m.actionTimer + 1

    return 0
end

function act_spin_pound_land(m)
    m.actionState = 1

    if m.actionTimer <= 8 then
        if (m.input & INPUT_UNKNOWN_10) ~= 0 then
            return drop_and_set_mario_action(m, ACT_SHOCKWAVE_BOUNCE, 0)
        end

        if (m.input & INPUT_OFF_FLOOR) ~= 0 then
            return set_mario_action(m, ACT_FREEFALL, 0)
        end

        if (m.input & INPUT_ABOVE_SLIDE) ~= 0 then
            return set_mario_action(m, ACT_BUTT_SLIDE, 0)
        end

        if (m.input & INPUT_A_PRESSED) ~= 0 then
            return set_jumping_action(m, ACT_GROUND_POUND_JUMP, 0)
        end

        if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
            mario_set_forward_vel(m, 60)

            play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
            return set_mario_action(m, ACT_ROLL, 0)
        end

        stationary_ground_step(m)
        set_mario_animation(m, MARIO_ANIM_LAND_FROM_DOUBLE_JUMP)
    else
        if (m.input & INPUT_UNKNOWN_10) ~= 0 then
            return set_mario_action(m, ACT_SHOCKWAVE_BOUNCE, 0)
        end

        if (m.input & (INPUT_NONZERO_ANALOG | INPUT_A_PRESSED | INPUT_OFF_FLOOR | INPUT_ABOVE_SLIDE)) ~= 0 then
            return check_common_action_exits(m)
        end

        stopping_step(m, MARIO_ANIM_LAND_FROM_DOUBLE_JUMP, ACT_IDLE)
    end

    m.actionTimer = m.actionTimer + 1

    return 0
end

function check_spin(m)
    mario_update_spin_input(m)
    
    local e = gMarioStateExtras[m.playerIndex]
    -- spin
    if (m.action == ACT_JUMP or
        m.action == ACT_WALL_KICK_AIR or
        m.action == ACT_DOUBLE_JUMP or
        m.action == ACT_BACKFLIP or
        m.action == ACT_SIDE_FLIP) and e.spinInput ~= 0 then
        set_mario_action(m, ACT_SPIN_JUMP, 1)
        e.spinInput = 0
    end
end
hook_event(HOOK_MARIO_UPDATE, check_spin)

function check_action(m, action)
    if gMarioStateExtras[m.playerIndex].spinInput ~= 0 and (m.input & INPUT_ABOVE_SLIDE) == 0 and (m.action == ACT_TURNING_AROUND and analog_stick_held_back(m) == 0) then
        if action == ACT_JUMP or
           action == ACT_DOUBLE_JUMP or
           action == ACT_TRIPLE_JUMP or
           action == ACT_SPECIAL_TRIPLE_JUMP or
           action == ACT_SIDE_FLIP or
           action == ACT_BACKFLIP then
            m.vel.y = 65.0
            m.faceAngle.y = m.intendedYaw
            return ACT_SPIN_JUMP
        end
    end
end
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, check_action)

hook_mario_action(ACT_SPIN_JUMP,                 { every_frame = act_spin_jump, gravity = act_spin_jump_gravity })
hook_mario_action(ACT_SPIN_POUND,                { every_frame = act_spin_pound })
hook_mario_action(ACT_SPIN_POUND_LAND,           { every_frame = act_spin_pound_land })