gGlobalSyncTable.GPD = true

function mario_update(m)
    if gGlobalSyncTable.GPD then
        if m.action == ACT_GROUND_POUND and (m.input & INPUT_B_PRESSED) ~= 0 then
            mario_set_forward_vel(m, 10.0)
            m.vel.y = 42.0
            set_mario_action(m, ACT_DIVE, 0)
            m.particleFlags = m.particleFlags | PARTICLE_DUST
        end
    end
end

function on_GPD_command(msg)
    if msg == "on" then
      gGlobalSyncTable.GPD = true
      djui_chat_message_create("GPD On")
      else
          gGlobalSyncTable.GPD = false
          djui_chat_message_create("GPD Off")
      end
      return true
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

if network_is_server() then
    hook_chat_command("GPD", "[on|off] to turn ground pound dive on or off", on_GPD_command)
end