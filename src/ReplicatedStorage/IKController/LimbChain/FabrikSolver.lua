-- Initialize Object Class
local Package = script.Parent
local Object = require(Package.BaseRedirect)

local FabrikSolver = Object.new("FabrikSolver")

--[[
    Initializes the Fabrik Solver Variable which will iterate a vector table from the initial joint to the end joint
]]
function FabrikSolver.new(LimbVectorTable, LimbLengthTable,LimbChain)
    local obj = FabrikSolver:make()

    obj.LimbChain = LimbChain
    obj.LimbVectorTable = LimbVectorTable
    obj.LimbLengthTable = LimbLengthTable
    obj.LimbConstraintTable = nil
    obj.DebugMode = false
    obj.FreezeLimbs = false

    -- Initialize number for summing
    local MaxLength = 0
    -- adds all the magnitudes of the limb vector
    for i = 1, #LimbLengthTable, 1 do
        MaxLength = MaxLength + LimbLengthTable[i]
    end

    obj.MaxLength = MaxLength

    return obj
end

--[[---------------------------------------------------------
    Executes one iteration of the Fabrik algo or not depending on the tolerance level
]]
function FabrikSolver:IterateOnce(originCF, targetPosition, tolerance)

    -- initialize measure feet to where it should be in the world position
    local vectorSum = Vector3.new(0, 0, 0)
    for i = 1, #self.LimbVectorTable, 1 do
        vectorSum = vectorSum + self.LimbVectorTable[i]
    end
    local feetJoint = originCF.Position + vectorSum
    local feetToTarget = targetPosition - feetJoint
    local distanceToGoal = feetToTarget.Magnitude

    if distanceToGoal >= tolerance then
        self:Backwards(originCF, targetPosition)
        self:Forwards(originCF, targetPosition)

        return self.LimbVectorTable

    else
        if self.DebugMode then
            self:Backwards(originCF, targetPosition)
            self:Forwards(originCF, targetPosition)    
        end
        return self.LimbVectorTable
    end

end

--[[

    Performs iteration until goal is reached, maximum break count can be set default is 10 iterations

]]
function FabrikSolver:IterateUntilGoal(originCF, targetPosition, tolerance, InputtedMaxBreakCount)

    -- initialize measure feet to where it should be in the world position
    local vectorSum = Vector3.new(0, 0, 0)
    for i = 1, #self.LimbVectorTable, 1 do
        vectorSum = vectorSum + self.LimbVectorTable[i]
    end
    local feetJoint = originCF.Position + vectorSum
    local feetToTarget = targetPosition - feetJoint
    local distanceToGoal = feetToTarget.Magnitude

    local maxBreakCount
    if InputtedMaxBreakCount and type(InputtedMaxBreakCount) == "number" then
        maxBreakCount = InputtedMaxBreakCount
    else
        maxBreakCount = 10
    end

    local bcount = 0

    while distanceToGoal >= tolerance do

        -- Do backwards on itself first then forwards until it reaches goal
        self:Backwards(originCF, targetPosition)
        self:Forwards(originCF, targetPosition)
        
        --Issue constraints don't update unless motors are updated
        --Solution update the motors lol
        self.LimbChain:UpdateMotors()

        --measure distance again
        -- initialize measure feet to where it should be in the world position
        local newVectorSum = Vector3.new(0, 0, 0)
        for i = 1, #self.LimbVectorTable, 1 do
            newVectorSum = newVectorSum + self.LimbVectorTable[i]
        end
        local footJoint = originCF.Position + newVectorSum
        local footToTarget = targetPosition - footJoint
        distanceToGoal = footToTarget.Magnitude
        
        --Counts the amount of iterations, if impossible to solve stops after max default at 10 iterations
        bcount += 1
        if bcount > maxBreakCount then 
            --print("bcount:", bcount,"failed to reach goal: ", distanceToGoal)
            return self.LimbVectorTable 
        end

    end
    --Iterate once in case
    self:Backwards(originCF, targetPosition)
    self:Forwards(originCF, targetPosition)

    -- Limb is within tolerance/already reached goal so don't do anything
    --print("bcount:", bcount,"Reached goal: ", distanceToGoal)
    return self.LimbVectorTable

end

--[[
    Constraining the forwards operation only makes it weird I dont think it simply does enough
    So constraints are also applied to backwards now
    Now is generalized with less parameters thanks to meta table objects storing the properties
]]
function FabrikSolver:Backwards(originCF, targetPos)

    -- Transporting from module scrip to class so gotta do this
    local limbVectorTable = self.LimbVectorTable
    local limbLengthTable = self.LimbLengthTable
    local limbConstraintTable = self.LimbConstraintTable

    local vectorSumFromOrigin = Vector3.new()
    -- Iterate through all the limb vectors and performs the backwards operation
    for i = #limbVectorTable, 1, -1 do
        local vectorSum = Vector3.new(0, 0, 0)

        for v = 1, i - 1, 1 do 
            vectorSum = vectorSum + limbVectorTable[v] 
        end

        local pointTowards = originCF.Position + vectorSum
        local pointFrom = targetPos + vectorSumFromOrigin

        -- Gets the new direction of the new vector along the chain
        -- direction is Target Pos to the next point on the chain
        local pointTo = pointTowards - pointFrom

        -- Gotta reverse the direction first
        -- The constraint only works if the direction is opposite
        local newLimbVector = -pointTo.Unit * limbLengthTable[i]

        -- Checks if there is a limb constraint for the current limb in the iteration
        if limbConstraintTable and limbConstraintTable[i] and limbConstraintTable[i] ~= nil then
            local limbLength = limbLengthTable[i]
            local currentVectorInformation = {
                ["JointPosition"] = pointTowards;
                ["LimbVector"] = newLimbVector;
                ["LimbLength"] = limbLength;
                ["Index"] = i
            }
            newLimbVector = limbConstraintTable[i]:ConstrainLimbVector(currentVectorInformation)
        end

        -- Gotta make it negative though to counteract the initial negative
        if not self.FreezeLimbs then
            limbVectorTable[i] = -newLimbVector
        end
        vectorSumFromOrigin = vectorSumFromOrigin + limbVectorTable[i]
    end

    -- Change the objects self vector table
    if not self.FreezeLimbs then
        self.LimbVectorTable = limbVectorTable
    end
end

--[[
	Does the forward chain of the FABRIK Algorithm
	Function should be called after the Backwards function in order to prevent the vector direction from changing
	Assumes vector chain is from endpoint to startpoint
	Returns parameters with new vector chain direction from Startpoint to EndPoint
]]
function FabrikSolver:Forwards(originCF, targetPos)

    local limbVectorTable = self.LimbVectorTable
    local limbLengthTable = self.LimbLengthTable
    local limbConstraintTable = self.LimbConstraintTable

    local vectorSumFromOrigin = Vector3.new()
    for i = 1, #limbVectorTable, 1 do
        
        local vectorSum = Vector3.new(0, 0, 0)

        for v = i + 1, #limbVectorTable, 1 do
            vectorSum = vectorSum + limbVectorTable[v]
        end

        local nextJointPosition = vectorSum + targetPos
        local jointPosition = originCF.Position + vectorSumFromOrigin
        -- Gets the new direction of the new vector along the chain
        -- direction of the new vector is from origin to target
        local pointTo = nextJointPosition - jointPosition

        local newLimbVector = pointTo.Unit * limbLengthTable[i]

        -- Checks if there is a limb constraint for the current limb in the iteration
        --Also if even the table exist in the first place to avoid indexing nil value
        if limbConstraintTable and limbConstraintTable[i] and limbConstraintTable[i] ~= nil then

            local limbLength = limbLengthTable[i]
            -- Start the constraint according to the method
            local currentVectorInformation = {
                ["JointPosition"] = jointPosition;
                ["LimbVector"] = newLimbVector;
                ["LimbLength"] = limbLength;
                ["Index"] = i
            }
            newLimbVector = limbConstraintTable[i]:ConstrainLimbVector(currentVectorInformation)

        end
        -- constructs the new vectable
        if not self.FreezeLimbs then
            limbVectorTable[i] = newLimbVector
        end
        if self.DebugMode then
            self:DebugLimbVector(i,jointPosition,jointPosition+newLimbVector)
        end
        vectorSumFromOrigin = vectorSumFromOrigin + limbVectorTable[i]
    end

    -- Change the objects self vector table
    if not self.FreezeLimbs then
        self.LimbVectorTable = limbVectorTable
    end

end

function FabrikSolver:DebugLimbVector(index,initialJointPosition,endJointPosition)
    --initizalize first
    if not self.LimbVectorInitialized then
        self.LimbVectorInitialized = true
        local VectorLimbPartTable = {}
        for i, v in pairs(self.LimbVectorTable) do
            local VectorLimbPart = Instance.new("WedgePart")
            VectorLimbPart.BrickColor = BrickColor.random()
            VectorLimbPart.Name = "VectorLimbPart"..i
            VectorLimbPart.Anchored = true
            VectorLimbPart.CanCollide = false
            VectorLimbPart.Size = Vector3.new(0.5,1,self.LimbLengthTable[i])
            VectorLimbPartTable[i] = VectorLimbPart
            VectorLimbPart.Parent = workspace
        end
        self.VectorLimbPartTable=VectorLimbPartTable
    else
        local positionCF = CFrame.new(initialJointPosition)
        local pointAt = CFrame.lookAt(initialJointPosition,endJointPosition)
        local rotOnly = pointAt-pointAt.Position
        self.VectorLimbPartTable[index].CFrame = positionCF*rotOnly*CFrame.new(0,0,-self.LimbLengthTable[index]/2)

    end
end

return FabrikSolver
