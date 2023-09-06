gGlobalSyncTable.CapThrow = true

local WING_CAP = (1 << 3)
local METAL_CAP = (1 << 4)
local VANISH_CAP = (1 << 5)

---@param o Object
function caploop(o)
  local obj = o.parentObj
  if obj.activeFlags == ACTIVE_FLAG_DEACTIVATED then
    local m = nearest_mario_state_to_object(obj)
    if (o.oBehParams & WING_CAP) ~= 0 then
      m.flags = m.flags + MARIO_WING_CAP
    end
    if (o.oBehParams & METAL_CAP) ~= 0 then
      m.flags = m.flags + MARIO_METAL_CAP
    end
    if (o.oBehParams & VANISH_CAP) ~= 0 then
      m.flags = m.flags + MARIO_VANISH_CAP
    end
    m.capTimer = -o.oTimer
    obj_mark_for_deletion(o)
  end

  if (o.oBehParams & VANISH_CAP) ~= 0 then
    obj.oOpacity = 150
  else
    obj.oOpacity = 255
  end
  if obj.oTimer >= 0 then
    o.oBehParams = o.oBehParams & ~(WING_CAP|METAL_CAP|VANISH_CAP)
    obj.header.gfx.node.flags = obj.header.gfx.node.flags & ~GRAPH_RENDER_INVISIBLE
    if o.oBehParams == 0 then
      obj_set_model_extended(obj,E_MODEL_MARIOS_CAP)
    else
      obj_set_model_extended(obj,E_MODEL_LUIGIS_CAP + (o.oBehParams-1)*5)
      print(E_MODEL_LUIGIS_CAP + (o.oBehParams-1)*5)
    end
  elseif (obj.oTimer > -40) then
    obj_flicker_and_disappear(obj,-40)
  end
end
id_bhvCapManager = hook_behavior(nil,OBJ_LIST_LEVEL,true,nil,caploop)

---@param m MarioState
function capthrow(m)
  if gGlobalSyncTable.CapThrow then
    if m.playerIndex ~= 0 then return end
  if (m.controller.buttonPressed & X_BUTTON) ~= 0 and (m.flags & MARIO_CAP_ON_HEAD) ~= 0 and (not disallow[m.action] or (m.action & ACT_GROUP_MASK) == ACT_GROUP_CUTSCENE) then
    if (m.action & ACT_FLAG_AIR) ~= 0 then
      set_mario_action(m,ACT_AIR_THROW,0)
    else
      set_mario_action(m,ACT_THROWING,0)
    end

    local c = m.character
    local capmodel = E_MODEL_MARIOS_CAP
    local capflags = c.type
    if c.type ~= CT_MARIO then
      capmodel = E_MODEL_LUIGIS_CAP + (c.type-1)*5
    end
    m.flags = m.flags - MARIO_CAP_ON_HEAD
    if (m.flags & MARIO_WING_CAP) ~= 0 then
      if c.type == CT_MARIO then
        capmodel = E_MODEL_MARIOS_WING_CAP
      else
        capmodel = capmodel + 2
      end
      capflags = capflags + WING_CAP
      print(capflags)
      m.flags = m.flags - MARIO_WING_CAP
    end
    if (m.flags & MARIO_VANISH_CAP) ~= 0 then
      capflags = capflags + VANISH_CAP
      print(capflags)
      m.flags = m.flags - MARIO_VANISH_CAP
    end
    if (m.flags & MARIO_METAL_CAP) ~= 0 then
      if c.type == CT_MARIO and capmodel == E_MODEL_MARIOS_WING_CAP then
        capmodel = E_MODEL_MARIOS_WINGED_METAL_CAP
      else
        capmodel = capmodel + 1
      end
      capflags = capflags + METAL_CAP
      print(capflags)
      m.flags = m.flags - MARIO_METAL_CAP
    end
    m.flags = m.flags - ((m.flags & MARIO_NORMAL_CAP) ~= 0 and MARIO_NORMAL_CAP or 0)
    local cap = spawn_sync_object(id_bhvNormalCap, capmodel, m.pos.x, m.pos.y+120, m.pos.z, function (o)
      o.oForwardVel = 20 + m.forwardVel
      o.oVelY = 10 + m.vel.y
      o.oTimer = -m.capTimer
    end)
    spawn_sync_object(id_bhvCapManager,E_MODEL_NONE,cap.oPosX,cap.oPosY,cap.oPosZ,function (o)
      o.parentObj = cap
      o.oBehParams = capflags
    end)
  end
  end
end

function on_CapThrow_command(msg)
  if msg == "on" then
    gGlobalSyncTable.CapThrow = true
    djui_chat_message_create("CapThrow On")
    else
        gGlobalSyncTable.CapThrow = false
        djui_chat_message_create("CapThrow Off")
    end
    return true
end

hook_event(HOOK_MARIO_UPDATE, capthrow)
hook_event(HOOK_ALLOW_INTERACT,function (m,o,type)

  if (m.action & ACT_FLAG_THROWING) ~= 0 and obj_has_behavior_id(o, id_bhvNormalCap) then
    return false
  end
  return true
end)

if network_is_server() then
  hook_chat_command("CapThrow", "[on|off] to turn CapThrow on or off", on_CapThrow_command)
end