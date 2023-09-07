gGlobalSyncTable.CDA = true

local acts = {
  ACT_BACKWARD_AIR_KB,
  ACT_HARD_BACKWARD_AIR_KB,
  ACT_FORWARD_AIR_KB,
  ACT_HARD_FORWARD_AIR_KB,
  ACT_GROUND_POUND,
  ACT_WALL_SLIDE,
  ACT_ROLL_AIR,
  ACT_DEATH_EXIT,
  ACT_SPECIAL_EXIT_AIRBORNE,
  ACT_FALLING_EXIT_AIRBORNE,
  ACT_SPECIAL_DEATH_EXIT,
  ACT_FALLING_DEATH_EXIT,
  ACT_STEEP_JUMP,
  ACT_EXIT_AIRBORNE
}

disallow = {}
for _, value in ipairs(acts) do
  disallow[value] = true
end

function airturn(m)
  if not gGlobalSyncTable.CDA then return end
  if (m.action & ACT_FLAG_AIR) ~= 0 and (m.action & ACT_FLAG_SWIMMING_OR_FLYING) == 0 and not (disallow[m.action] or (m.action & ACT_GROUP_MASK) == ACT_GROUP_CUTSCENE) then
    if (m.input & INPUT_NONZERO_ANALOG) then
        intendedDYaw = m.intendedYaw - m.faceAngle.y
        if (intendedDYaw > 32767) then intendedDYaw = intendedDYaw-65536 end
        if (intendedDYaw < -32768) then intendedDYaw = intendedDYaw+65536 end
        intendedMag = m.intendedMag / 32.0;

        m.faceAngle.y = m.faceAngle.y + math.floor(512.0 * sins(intendedDYaw) * intendedMag*3)
    end
  end
end

function on_CDA_command(msg)
  gGlobalSyncTable.CDA = not gGlobalSyncTable.CDA
  if gGlobalSyncTable.CDA then
    djui_chat_message_create("CDA On")
  else
    djui_chat_message_create("CDA Off")
  end
  return true
end

hook_event(HOOK_MARIO_UPDATE, airturn)

if network_is_server() then
  hook_chat_command("CDA", "to make mario change direction airborne", on_CDA_command)
end