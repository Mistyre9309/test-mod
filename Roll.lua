gPlayerSyncTable[0].roll = true
function update_roll_sliding_angle(m, accel, lossFactor)
	local floor = m.floor
	local slopeAngle = atan2s(floor.normal.z, floor.normal.x)
	local steepness = math.sqrt(floor.normal.x * floor.normal.x + floor.normal.z * floor.normal.z)

	m.slideVelX = m.slideVelX + accel * steepness * sins(slopeAngle)
	m.slideVelZ = m.slideVelZ + accel * steepness * coss(slopeAngle)

	m.slideVelX = m.slideVelX * lossFactor
	m.slideVelZ = m.slideVelZ * lossFactor

	m.slideYaw = atan2s(m.slideVelZ, m.slideVelX)

	local facingDYaw = limit_angle(m.faceAngle.y - m.slideYaw)
	local newFacingDYaw = facingDYaw

	if newFacingDYaw > 0 and newFacingDYaw <= 0x8000 then
		newFacingDYaw = newFacingDYaw - 0x800
		if newFacingDYaw < 0 then newFacingDYaw = 0 end

	elseif newFacingDYaw >= -0x8000 and newFacingDYaw < 0 then
		newFacingDYaw = newFacingDYaw + 0x800
		if newFacingDYaw > 0 then newFacingDYaw = 0 end
	end

	m.faceAngle.y = limit_angle(m.slideYaw + newFacingDYaw)

	m.vel.x = m.slideVelX
	m.vel.y = 0.0
	m.vel.z = m.slideVelZ

	mario_update_moving_sand(m)
	mario_update_windy_ground(m)

	m.forwardVel = math.sqrt(m.slideVelX * m.slideVelX + m.slideVelZ * m.slideVelZ)
	if m.forwardVel > 100.0 then
		m.slideVelX = m.slideVelX * 100.0 / m.forwardVel
		m.slideVelZ = m.slideVelZ * 100.0 / m.forwardVel
	end
end

function update_roll_sliding(m, stopSpeed)
	local stopped = 0

	local intendedDYaw = m.intendedYaw - m.slideYaw
	local forward = coss(intendedDYaw)
	local sideward = sins(intendedDYaw)

	if forward < 0.0 and m.forwardVel >= 0.0 then
		forward = forward * (0.5 + 0.5 * m.forwardVel / 100.0)
	end

	local accel = 4.0
	local lossFactor = 0.994

	local oldSpeed = math.sqrt(m.slideVelX * m.slideVelX + m.slideVelZ * m.slideVelZ)

	local angleChange  = (m.intendedMag / 32.0) * 0.6
	local modSlideVelX = m.slideVelZ * angleChange * sideward * 0.05
	local modSlideVelZ = m.slideVelX * angleChange * sideward * 0.05

	m.slideVelX = m.slideVelX + modSlideVelX
	m.slideVelZ = m.slideVelZ - modSlideVelZ

	local newSpeed = math.sqrt(m.slideVelX * m.slideVelX + m.slideVelZ * m.slideVelZ)

	if oldSpeed > 0.0 and newSpeed > 0.0 then
		m.slideVelX = m.slideVelX * oldSpeed / newSpeed
		m.slideVelZ = m.slideVelZ * oldSpeed / newSpeed
	end

	update_roll_sliding_angle(m, accel, lossFactor)

	if m.playerIndex == 0 and mario_floor_is_slope(m) == 0 and m.forwardVel * m.forwardVel < stopSpeed * stopSpeed then
		mario_set_forward_vel(m, 0.0)
		stopped = 1
	end

	return stopped
end

function act_roll(m)
	local e = gMarioStateExtras[m.playerIndex]

	local MAX_NORMAL_ROLL_SPEED = 100.0
	local ROLL_BOOST_GAIN = 10.0
	local ROLL_CANCEL_LOCKOUT_TIME = 10
	local BOOST_LOCKOUT_TIME = 20


	if m.actionTimer == 0 then
		if m.prevAction ~= ACT_ROLL_AIR then
			e.rotAngle = 0
			e.boostTimer = 0
		end
	elseif m.actionTimer >= ROLL_CANCEL_LOCKOUT_TIME or m.actionArg == 1 then
		if (m.input & INPUT_Z_DOWN) == 0 then
			return set_mario_action(m, ACT_WALKING, 0)
		end
	end

	if (m.input & INPUT_A_PRESSED) ~= 0 then
		return set_jumping_action(m, ACT_LONG_JUMP, 0)
	end

	if (m.controller.buttonPressed & B_BUTTON) ~= 0 and m.actionTimer > 0 then
		m.vel.y = 19.0
		play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, 0)

		if e.boostTimer >= BOOST_LOCKOUT_TIME then
			e.boostTimer = 0

			if m.forwardVel < MAX_NORMAL_ROLL_SPEED then
				mario_set_forward_vel(m, math.min(m.forwardVel + ROLL_BOOST_GAIN, MAX_NORMAL_ROLL_SPEED))
			end

			m.particleFlags = m.particleFlags | PARTICLE_HORIZONTAL_STAR

			play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
		end

		return set_mario_action(m, ACT_ROLL_AIR, m.actionArg)
	end

	set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)

	if update_roll_sliding(m, 10.0) ~= 0 then
		return set_mario_action(m, ACT_CROUCH_SLIDE, 0)
	end

	common_slide_action(m, ACT_CROUCH_SLIDE, ACT_ROLL_AIR, MARIO_ANIM_FORWARD_SPINNING)

	e.rotAngle = e.rotAngle + (0x80 * m.forwardVel)
	if e.rotAngle > 0x10000 then
		e.rotAngle = e.rotAngle - 0x10000
	end
	set_anim_to_frame(m, 10 * e.rotAngle / 0x10000)

	e.boostTimer = e.boostTimer + 1

	m.actionTimer = m.actionTimer + 1

	return 0
end

function act_roll_air(m)
	local e = gMarioStateExtras[m.playerIndex]
	local MAX_NORMAL_ROLL_SPEED = 50.0
	local ROLL_AIR_CANCEL_LOCKOUT_TIME = 15

	if m.actionTimer == 0 then
		if m.prevAction ~= ACT_ROLL then
			e.rotAngle = 0
			e.boostTimer   = 0
		end
	end

	if (m.input & INPUT_Z_DOWN) == 0 and m.actionTimer >= ROLL_AIR_CANCEL_LOCKOUT_TIME then
		return set_mario_action(m, ACT_FREEFALL, 0)
	end

	set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING)

	local air_step = perform_air_step(m, 0)
	if air_step == AIR_STEP_LANDED then
		if check_fall_damage_or_get_stuck(m, ACT_HARD_BACKWARD_GROUND_KB) == 0 then
			play_sound_and_spawn_particles(m, SOUND_ACTION_TERRAIN_STEP, 0)
			return set_mario_action(m, ACT_ROLL, m.actionArg)
		end
	elseif air_step == AIR_STEP_HIT_WALL then
		queue_rumble_data_mario(m, 5, 40)
		mario_bonk_reflection(m, false)
		m.faceAngle.y = m.faceAngle.y + 0x8000

		if m.vel.y > 0.0 then
			m.vel.y = 0.0
		end

		m.particleFlags = m.particleFlags | PARTICLE_VERTICAL_STAR
		return set_mario_action(m, ACT_BACKWARD_AIR_KB, 0)
	end

	e.rotAngle = e.rotAngle + 0x80 * m.forwardVel
	if e.rotAngle > 0x10000 then
		e.rotAngle = e.rotAngle - 0x10000
	end

	set_anim_to_frame(m, 10 * e.rotAngle / 0x10000)

	e.boostTimer = e.boostTimer + 1
	m.actionTimer = m.actionTimer + 1

	return false
end

function update_roll(m)
if gpt(m, ROLL) then
	if m.action == ACT_DIVE_SLIDE then
		if (m.input & INPUT_ABOVE_SLIDE) == 0 then
			if (m.input & INPUT_Z_DOWN) ~= 0 and m.actionTimer < 2 then
				return set_mario_action(m, ACT_ROLL, 1)
			end
		end
		m.actionTimer = m.actionTimer + 1
	end

	if m.action == ACT_LONG_JUMP_LAND then
		if (m.input & INPUT_Z_DOWN) ~= 0 and m.forwardVel > 15.0 and m.actionTimer < 1 then
			play_mario_landing_sound_once(m, SOUND_ACTION_TERRAIN_LANDING)
			return set_mario_action(m, ACT_ROLL, 1)
		end
	end

	if m.action == ACT_CROUCHING then
		if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
			m.vel.y = 19.0
			mario_set_forward_vel(m, 60.0)
			play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, 0)

			play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)

			return set_mario_action(m, ACT_ROLL, 0)
		end
	end

	if m.action == ACT_CROUCH_SLIDE then
		if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
			m.vel.y = 19.0
			mario_set_forward_vel(m, math.max(60, m.forwardVel))
			play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, 0)

			play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)

			return set_mario_action(m, ACT_ROLL_AIR, 0)
		end
	end

	if m.action == ACT_GROUND_POUND_LAND then
		if (m.controller.buttonPressed & B_BUTTON) ~= 0 then
			mario_set_forward_vel(m, 100)

			play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)

			return set_mario_action(m, ACT_ROLL, 0)
		end
	end
end
end

hook_event(HOOK_BEFORE_MARIO_UPDATE,update_roll)
hook_mario_action(ACT_ROLL,     act_roll)
hook_mario_action(ACT_ROLL_AIR, act_roll_air)