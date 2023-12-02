function limit_angle(a)
    return (a + 0x8000) % 0x10000 - 0x8000
end

gMarioStateExtras = {}
ANGLE_QUEUE_SIZE = 9
for i=0,(MAX_PLAYERS-1) do
    gMarioStateExtras[i] = {}
    --local m = gMarioStates[i]
    local e = gMarioStateExtras[i]
    e.angleDeltaQueue = {}
    for j=0,(ANGLE_QUEUE_SIZE-1) do e.angleDeltaQueue[j] = 0 end
    e.rotAngle = 0
    e.boostTimer = 0

    e.stickLastAngle = 0
    e.spinDirection = 0
    e.spinBufferTimer = 0
    e.spinInput = 0
    e.lastIntendedMag = 0

    e.BWCMinVel = 0
end

local lp = gPlayerSyncTable[0]
lp.sillymoves = {}

function gpt(m, s)
    return gPlayerSyncTable[m.playerIndex].sillymoves ~= nil and gPlayerSyncTable[m.playerIndex].sillymoves[s] or false
end

function flick(s)
	lp.sillymoves[s] = not lp.sillymoves[s]
end

BWC = 1
CT = 2
AT = 3
GPD = 4
GPE = 5
FD = 6
ROLL = 7
SJ = 8
TWIRL = 9
WS = 10
RAD = 11

for i=1, RAD do
    gPlayerSyncTable[0].sillymoves[i] = true
end