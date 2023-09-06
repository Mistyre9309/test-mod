ACT_GROUND_POUND_JUMP =         allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_WATER_GROUND_POUND =        allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT | ACT_FLAG_ATTACKING)
ACT_WATER_GROUND_POUND_LAND =   allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_STATIONARY | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT)
ACT_WATER_GROUND_POUND_STROKE = allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT)
ACT_WATER_GROUND_POUND_JUMP =   allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_MOVING | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT)

function act_ground_pound_jump(m)
    local e = gMarioStateExtras[m.playerIndex]
    if check_kick_or_dive_in_air(m) ~= 0 then
        m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y + e.rotAngle
        return 1
    end

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y + e.rotAngle
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    --if e.spinInput ~= 0 then
    --    return set_mario_action(m, ACT_SPIN_JUMP, 1)
    --end

    if m.actionTimer == 0 then
        e.rotAngle = 0
    elseif m.actionTimer == 1 then
        play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
    end

    play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, CHAR_SOUND_YAHOO)

    common_air_action_step(m, ACT_JUMP_LAND, MARIO_ANIM_SINGLE_JUMP,
                           AIR_STEP_CHECK_LEDGE_GRAB | AIR_STEP_CHECK_HANG)

    e.rotAngle = e.rotAngle + (0x10000*1.0 - e.rotAngle) / 5.0
    m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y - e.rotAngle

    m.actionTimer = m.actionTimer + 1

    return 0
end

function act_water_ground_pound(m)
  local GROUND_POUND_STROKE_SPEED = 27
  local GROUND_POUND_TIMER = 30

  local stepResult = 0

  if m.actionTimer == 0 then
      -- coming into action from normal ground pound
      if m.actionArg == 1 then
          -- copied from water plunge code
          play_sound(SOUND_ACTION_UNKNOWN430, m.marioObj.header.gfx.cameraToObject)
          if m.peakHeight - m.pos.y > 1150.0 then
              play_sound(CHAR_SOUND_HAHA_2, m.marioObj.header.gfx.cameraToObject)
          end

          m.particleFlags = m.particleFlags | PARTICLE_WATER_SPLASH

          if (m.prevAction & ACT_FLAG_AIR) ~= 0 then
              queue_rumble_data_mario(m, 5, 80)
          end
      end

      m.actionState = m.actionArg
  elseif m.actionTimer == 1 then
      play_sound(SOUND_ACTION_SWIM, m.marioObj.header.gfx.cameraToObject)
  end

  if m.actionState == 0 then
      if m.actionTimer == 0 then
          m.vel.y = 0.0
          mario_set_forward_vel(m, 0.0)
      end

      m.faceAngle.x = 0
      m.faceAngle.z = 0

      set_mario_animation(m, MARIO_ANIM_START_GROUND_POUND)
      if m.actionTimer == 0 then
          play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
      end

      m.actionTimer = m.actionTimer + 1
      if (m.actionTimer >= m.marioObj.header.gfx.animInfo.curAnim.loopEnd + 4) then
          -- play_sound(CHAR_SOUND_GROUND_POUND_WAH, m.marioObj.header.gfx.cameraToObject)
          play_sound(SOUND_ACTION_SWIM_FAST, m.marioObj.header.gfx.cameraToObject)
          m.vel.y = -45.0
          m.actionState = 1
      end

      if (m.input & INPUT_A_PRESSED) ~= 0 then
          mario_set_forward_vel(m, GROUND_POUND_STROKE_SPEED)
          m.vel.y = 0
          return set_mario_action(m, ACT_WATER_GROUND_POUND_STROKE, 0)
      end

      -- make current apply
      stepResult = perform_water_step(m)
  else

      set_mario_animation(m, MARIO_ANIM_GROUND_POUND)

      m.particleFlags = m.particleFlags | PARTICLE_PLUNGE_BUBBLE

      local nextPos = {}
      nextPos.x = m.pos.x + m.vel.x
      nextPos.y = m.pos.y + m.vel.y
      nextPos.z = m.pos.z + m.vel.z

      -- call this one to make current NOT apply
      stepResult = perform_water_full_step(m, nextPos)

      vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
      vec3s_set(m.marioObj.header.gfx.angle, -m.faceAngle.x, m.faceAngle.y, m.faceAngle.z)

      if stepResult == WATER_STEP_HIT_FLOOR then
          play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_HEAVY_LANDING)
          m.particleFlags = m.particleFlags | PARTICLE_MIST_CIRCLE | PARTICLE_HORIZONTAL_STAR
          set_mario_action(m, ACT_WATER_GROUND_POUND_LAND, 0)
          set_camera_shake_from_hit(SHAKE_GROUND_POUND)
      else
          if (m.input & INPUT_A_PRESSED) ~= 0 then
              mario_set_forward_vel(m, GROUND_POUND_STROKE_SPEED)
              m.vel.y = 0
              return set_mario_action(m, ACT_WATER_GROUND_POUND_STROKE, 0)
          end

          m.vel.y = approach_f32(m.vel.y, 0, 2.0, 2.0)

          mario_set_forward_vel(m, 0.0)

          if m.actionTimer >= GROUND_POUND_TIMER or m.vel.y >= 0.0 then
              set_mario_action(m, ACT_WATER_ACTION_END, 0)
          end
      end

      m.actionTimer = m.actionTimer + 1
  end

  return 0
end

function act_water_ground_pound_land(m)
  local GROUND_POUND_JUMP_VEL = 40.0

  m.actionState = 1

  if (m.input & INPUT_OFF_FLOOR) ~= 0 then
      return set_mario_action(m, ACT_WATER_IDLE, 0)
  end

  if (m.input & INPUT_A_PRESSED) ~= 0 then
      m.vel.y = GROUND_POUND_JUMP_VEL
      play_sound(SOUND_ACTION_SWIM_FAST, m.marioObj.header.gfx.cameraToObject)
      return set_mario_action(m, ACT_WATER_GROUND_POUND_JUMP, 0)
  end

  m.vel.y = 0.0
  m.pos.y = m.floorHeight
  mario_set_forward_vel(m, 0.0)

  vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
  vec3s_set(m.marioObj.header.gfx.angle, 0, m.faceAngle.y, 0)

  set_mario_animation(m, MARIO_ANIM_GROUND_POUND_LANDING)
  if is_anim_at_end(m) ~= 0 then
      return set_mario_action(m, ACT_SWIMMING_END, 0)
  end

  perform_water_step(m)

  return 0
end

function act_water_ground_pound_stroke(m)
  local GROUND_POUND_STROKE_TIMER = 20
  local GROUND_POUND_STROKE_DECAY = 0.3
  local stepResult = 0

  set_mario_animation(m, MARIO_ANIM_SWIM_PART1)

  if m.actionTimer == 0 then
      play_sound(SOUND_ACTION_SWIM_FAST, m.marioObj.header.gfx.cameraToObject)
  end

  stepResult = perform_water_step(m)
  if stepResult == WATER_STEP_HIT_WALL then
      return set_mario_action(m, ACT_BACKWARD_WATER_KB, 0)
  end

  if m.actionTimer >= GROUND_POUND_STROKE_TIMER then
      if (m.input & INPUT_A_DOWN) ~= 0 then
          return set_mario_action(m, ACT_FLUTTER_KICK, 0)
      else
          return set_mario_action(m, ACT_SWIMMING_END, 0)
      end
  end
  m.actionTimer = m.actionTimer + 1

  mario_set_forward_vel(m, approach_f32(m.forwardVel, 0.0, GROUND_POUND_STROKE_DECAY, GROUND_POUND_STROKE_DECAY))

  float_surface_gfx(m)
  set_swimming_at_surface_particles(m, PARTICLE_WAVE_TRAIL)

  return 0
end

function act_water_ground_pound_jump(m)
  local e = gMarioStateExtras[m.playerIndex]
  local GROUND_POUND_JUMP_TIMER = 20
  local GROUND_POUND_JUMP_DECAY = 1.4

  -- set_mario_animation(m, MARIO_ANIM_SWIM_PART1)
  set_mario_animation(m, MARIO_ANIM_SINGLE_JUMP)
  m.particleFlags = m.particleFlags | PARTICLE_PLUNGE_BUBBLE

  if m.actionTimer == 0 then
      e.rotAngle = 0
  end

  local step = {}
  vec3f_copy(step, m.vel)
  apply_water_current(m, step)

  local nextPos = {}
  nextPos.x = m.pos.x + step.x
  nextPos.y = m.pos.y + step.y
  nextPos.z = m.pos.z + step.z

  local stepResult = perform_water_full_step(m, nextPos)

  vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
  vec3s_set(m.marioObj.header.gfx.angle, -m.faceAngle.x, m.faceAngle.y, m.faceAngle.z)

  if m.pos.y > m.waterLevel - 80 then
      return set_mario_action(m, ACT_WATER_JUMP, 0)
  end

  if m.actionTimer >= GROUND_POUND_JUMP_TIMER then
      mario_set_forward_vel(m, m.vel.y) -- normal swim routines will use forwardVel to calculate y speed
      m.faceAngle.x = 0x3EFF
      if (m.input & INPUT_A_DOWN) ~= 0 then
          return set_mario_action(m, ACT_FLUTTER_KICK, 0)
      else
          return set_mario_action(m, ACT_SWIMMING_END, 0)
      end
  end
  m.actionTimer = m.actionTimer + 1

  mario_set_forward_vel(m, 0.0)

  m.vel.y = approach_f32(m.vel.y, 0.0, GROUND_POUND_JUMP_DECAY, GROUND_POUND_JUMP_DECAY)
  -- m.faceAngle.x = 0x3EFF

  float_surface_gfx(m)
  set_swimming_at_surface_particles(m, PARTICLE_WAVE_TRAIL)

  e.rotAngle = e.rotAngle + (0x10000*1.0 - e.rotAngle) / 5.0
  m.marioObj.header.gfx.angle.y = limit_angle(m.marioObj.header.gfx.angle.y - e.rotAngle)

  return 0
end

hook_mario_action(ACT_GROUND_POUND_JUMP,         { every_frame = act_ground_pound_jump })
hook_mario_action(ACT_WATER_GROUND_POUND,        { every_frame = act_water_ground_pound })
hook_mario_action(ACT_WATER_GROUND_POUND_LAND,   { every_frame = act_water_ground_pound_land })
hook_mario_action(ACT_WATER_GROUND_POUND_STROKE, { every_frame = act_water_ground_pound_stroke })
hook_mario_action(ACT_WATER_GROUND_POUND_JUMP,   { every_frame = act_water_ground_pound_jump })

hook_event(HOOK_MARIO_UPDATE, function (m)
    if m.action == ACT_GROUND_POUND_LAND and (m.input & INPUT_A_PRESSED) ~= 0 then
        set_mario_action(m, ACT_GROUND_POUND_JUMP, 0)
        m.vel.y = 65.0
    end
    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        if m.action == ACT_WATER_IDLE or m.action == ACT_WATER_ACTION_END or m.action == ACT_BREASTSTROKE or m.action == ACT_SWIMMING_END or m.action == ACT_FLUTTER_KICK then
            set_mario_action(m, ACT_WATER_GROUND_POUND, 0)
        end
    end
end)