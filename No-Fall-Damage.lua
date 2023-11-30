gPlayerSyncTable[0].fallDamage = false

function mario_update(m)
	if not gpt(m, FD) then
		m.peakHeight = m.pos.y
	end
end

-- function on_fall_damage_command(msg)
-- 	gGlobalSyncTable.fallDamage = not gGlobalSyncTable.fallDamage
-- 	if gGlobalSyncTable.fallDamage then
-- 		djui_chat_message_create("Fall Damage On")
-- 	else
-- 		djui_chat_message_create("Fall Damage Off")
-- 	end
-- 	return true
-- end

hook_event(HOOK_MARIO_UPDATE, mario_update)

-- if network_is_server() then
-- 	hook_chat_command("falldamage", "to turn fall damage on or off", on_fall_damage_command)
-- end