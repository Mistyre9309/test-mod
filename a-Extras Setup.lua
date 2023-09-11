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