gGlobalSyncTable.BWC = true

local rotation = {0, 0, 0}
local stop = false
local minvel = 0
vec3f_set(rotation, 0, 0, 0)
---@param m MarioState
function mario_update(m)
    if gGlobalSyncTable.BWC then
        if m.playerIndex ~= 0 then return end
        if ((m.flags & MARIO_WING_CAP) ~= 0) and m.action == ACT_FLYING and m.marioBodyState.capState ~= MARIO_HAS_DEFAULT_CAP_ON then
            vec3f_set(rotation, m.faceAngle.x, 0, m.faceAngle.z)
            if (m.controller.buttonDown & B_BUTTON) ~= 0 then
                stop = true
                minvel = 4
                m.forwardVel = m.forwardVel * .95
                m.particleFlags = m.particleFlags & PARTICLE_DUST
            else
                stop = false
                if m.forwardVel < minvel then
                    m.forwardVel = minvel
                else
                    minvel = m.forwardVel
                end
            end
            if (m.forwardVel > 16) then
                m.faceAngle.x = m.faceAngle.x - (m.forwardVel - 32) * 6
            elseif (m.forwardVel > 4) then
                m.faceAngle.x = m.faceAngle.x - (m.forwardVel - 32) * 10
            else
                m.faceAngle.x = m.faceAngle.x + 0x400
            end
        else
            minvel = 4
        end
    end
end

function on_BWC_command(msg)
    if msg == "on" then
      gGlobalSyncTable.BWC = true
      djui_chat_message_create("BWC On")
      else
          gGlobalSyncTable.BWC = false
          djui_chat_message_create("BWC Off")
      end
      return true
  end

hook_event(HOOK_MARIO_UPDATE, mario_update)

if network_is_server() then
    hook_chat_command("BWC", "[on|off] to turn better wing cap on or off", on_BWC_command)
  end