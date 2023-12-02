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
	if not gpt(m, AT) or not gNetworkPlayers[m.playerIndex].connected then return end
	if (m.action & ACT_FLAG_AIR) ~= 0 and (m.action & ACT_FLAG_SWIMMING_OR_FLYING) == 0 then
		if (m.input & INPUT_NONZERO_ANALOG) ~= 0 and not (disallow[m.action] or (m.action & ACT_GROUP_MASK) == ACT_GROUP_CUTSCENE) then
			intendedDYaw = limit_angle(m.intendedYaw - m.faceAngle.y)
			intendedMag = m.intendedMag / 32.0;

			m.faceAngle.y = m.faceAngle.y + math.floor(512.0 * sins(intendedDYaw) * intendedMag*3)
		end
	end
end

hook_event(HOOK_MARIO_UPDATE, airturn)