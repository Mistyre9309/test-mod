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

dive_list = {
	[ACT_JUMP] = true,
	[ACT_DOUBLE_JUMP] = true,
	[ACT_TRIPLE_JUMP] = true,
	[ACT_SIDE_FLIP] = true,
	[ACT_WALL_KICK_AIR] = true,
	[ACT_SPIN_JUMP] = true,
	[ACT_GROUND_POUND_JUMP] = true,
}

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, remove_air_dive)