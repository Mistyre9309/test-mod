function replace_action(m, action)
if gpt(m, SJ) then
	if action == ACT_STEEP_JUMP then
		if m.prevAction == ACT_JUMP then
			return ACT_DOUBLE_JUMP
		else
			return ACT_JUMP
		end
	end
end
end

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, replace_action)