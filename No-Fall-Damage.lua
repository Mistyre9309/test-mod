gGlobalSyncTable.fallDamage = false

function mario_update(m)
  if not gGlobalSyncTable.fallDamage then
    m.peakHeight = m.pos.y
  end
end

function on_fall_damage_command(msg)
  if msg == "on" then
    gGlobalSyncTable.fallDamage = true
    djui_chat_message_create("Fall Damage On")
    else
        gGlobalSyncTable.fallDamage = false
        djui_chat_message_create("Fall Damage Off")
    end
    return true
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

if network_is_server() then
  hook_chat_command("falldamage", "[on|off] to turn falldamage on or off", on_fall_damage_command)
end