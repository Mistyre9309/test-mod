function replace_action(m, action)
if not gpt(m, SJ) then
	if action == ACT_STEEP_JUMP then
		if m.prevAction == ACT_JUMP then
			return ACT_DOUBLE_JUMP
		else
			return ACT_JUMP
		end
	end
end
end

-- function on_SJ_command(msg)
-- 	gGlobalSyncTable.SJ = not gGlobalSyncTable.SJ
-- 	if gGlobalSyncTable.SJ then
-- 		djui_chat_message_create("Steep Jumps On")
-- 	else
-- 		djui_chat_message_create("Steep Jumps Off")
-- 	end
-- 	return true
-- end

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, replace_action)

-- if network_is_server() then
-- 	hook_chat_command("SJ", "to turn Steep Jumps on or off", on_SJ_command)
-- end