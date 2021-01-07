--Axis angle version
local function fromToRotation(u,v,axis)
    local dot = u:Dot(v)
    if (dot > 0.99999) then
        -- situation 1
        return CFrame.new()
    elseif (dot < -0.99999) then
        -- situation 2
        return CFrame.fromAxisAngle(axis, math.pi)
    end
	-- situation 3
		return CFrame.fromAxisAngle(u:Cross(v), math.acos(dot)*0.8)
end

--Quaternion rotation version from Egomoose
--The cooler version
local function getRotationBetween(u, v, axis)
    local dot, uxv = u:Dot(v), u:Cross(v)
    if (dot < -0.99999) then return CFrame.fromAxisAngle(axis, math.pi) end
    return CFrame.new(0, 0, 0, uxv.x, uxv.y, uxv.z, 1 + dot)
end

local UPVECTOR = Vector3.new(0,1,0)
local RIGHTVECTOR = Vector3.new(1,0,0)
local WORLDLOOKVECTOR = Vector3.new(0,0,-1)

--Method 1, using axis angle, 0.0055 seconds, 0.008
--Method 2 using quaternion, 0.009 seconds, 0.007
--Eh it's kinda the same shouldn't matter.
local startTime = os.clock()

for i=1,10000 do
    fromToRotation(UPVECTOR,RIGHTVECTOR,WORLDLOOKVECTOR)
    --getRotationBetween(UPVECTOR,RIGHTVECTOR,WORLDLOOKVECTOR)
end

local deltaTime = os.clock() - startTime
print("Elapsed time method 1: " .. deltaTime)


return nothing