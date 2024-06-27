local dive_list = {
	[ACT_JUMP] = 1,
	[ACT_DOUBLE_JUMP] = 1,
	[ACT_TRIPLE_JUMP] = 1,
	[ACT_SIDE_FLIP] = 1,
	[ACT_WALL_KICK_AIR] = 1,
	[ACT_SPIN_JUMP] = 1,
	[ACT_GROUND_POUND_JUMP] = 1,
}

function remove_air_dive(m, action)
	if gpt(m, RAD) then
		if dive_list[m.action] and action == ACT_DIVE then
			m.forwardVel = 20
			return ACT_JUMP_KICK
		end
		if m.action == ACT_WALKING and action == ACT_DIVE then
			m.forwardVel = 5
			return 1
--          set_mario_action(m, ACT_WALKING, 0)
		end
	end
end

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, remove_air_dive)