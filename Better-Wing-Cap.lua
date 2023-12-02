---@param m MarioState
function mario_update(m)
    local e = gMarioStateExtras[m.playerIndex]
    if ((m.flags & MARIO_WING_CAP) ~= 0) and m.action == ACT_FLYING and m.marioBodyState.capState ~= MARIO_HAS_DEFAULT_CAP_ON and gpt(m, BWC) then
        if (m.controller.buttonDown & B_BUTTON) ~= 0 then
            e.BWCMinVel = 10
            m.forwardVel = m.forwardVel * .90
            if m.forwardVel < 7 then
                m.angleVel.y = m.controller.stickX*-4
                m.angleVel.x = m.controller.stickY*-10
                m.faceAngle.y = m.faceAngle.y + m.controller.stickX*-6
                m.faceAngle.z = m.faceAngle.z * .1
                m.forwardVel = 0
            else
                m.particleFlags = m.particleFlags | PARTICLE_DUST
            end
        else
            if (m.controller.buttonDown & A_BUTTON) ~= 0 then
                m.forwardVel = m.forwardVel + 1
            end
            if m.forwardVel < e.BWCMinVel then
                m.forwardVel = e.BWCMinVel
            else
                e.BWCMinVel = m.forwardVel
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
        e.BWCMinVel = 10
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)