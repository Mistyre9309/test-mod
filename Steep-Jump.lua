gGlobalSyncTable.SJ = true

function mario_update(m)
if gGlobalSyncTable.SJ then
	if m.action == ACT_STEEP_JUMP then set_mario_action(m, ACT_JUMP, 0)
		end
	end
end

function on_SJ_command(msg)
    if msg == "on" then
      gGlobalSyncTable.SJ = true
      djui_chat_message_create("Steep Jump Remover On")
      else
          gGlobalSyncTable.SJ = false
          djui_chat_message_create("Steep Jump Remover Off")
      end
      return true
  end

hook_event(HOOK_MARIO_UPDATE, mario_update)

if network_is_server() then
    hook_chat_command("SJ", "[on|off] to turn Steep Jump Remover on or off", on_SJ_command)
end