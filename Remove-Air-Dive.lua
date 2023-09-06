gGlobalSyncTable.RAD = true

function mario_update(m)
    if gGlobalSyncTable.RAD then
        if dive_list[m.prevAction] and m.action == ACT_DIVE then
            set_mario_action(m, ACT_JUMP_KICK, 0) m.forwardVel = 20
        end
        if m.prevAction == ACT_WALKING and m.action == ACT_DIVE then
            set_mario_action(m, ACT_WALKING, 0) m.forwardVel = 5
        end
    end
end

dive_list = {
    [ACT_JUMP] = true,
    [ACT_DOUBLE_JUMP] = true,
    [ACT_TRIPLE_JUMP] = true,
    [ACT_SIDE_FLIP] = true,
    [ACT_WALL_KICK_AIR] = true,
}

function on_RAD_command(msg)
    if msg == "on" then
      gGlobalSyncTable.RAD = true
      djui_chat_message_create("RAD On")
      else
          gGlobalSyncTable.RAD = false
          djui_chat_message_create("RAD Off")
      end
      return true
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

if network_is_server() then
    hook_chat_command("RAD", "[on|off] to turn Remove Air Dive on or off", on_RAD_command)
end