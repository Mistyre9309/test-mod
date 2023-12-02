gPlayerSyncTable[0].fallDamage = false

function mario_update(m)
	if gpt(m, FD) then
		m.peakHeight = m.pos.y
	end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)