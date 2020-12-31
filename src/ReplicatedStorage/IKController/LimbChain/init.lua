--[[

This is the LimbChain class which manages the Motor6Ds within a rig using the FabrikSolver class to do inverse kinematics with.

API:

Constructors:
	LimbChain.new(Table Motor6DTable, Bool includeFoot, Bool spineMotor)
        > Creates the inverse kinematics handler for a set of Motor6D's inserted in the table
        >Motor6ds are conected sequentially in increasing order from the origin towards the endpoint 
        >Motor1, Motor2, Motor3
        >UpperLeg, LowerLeg, Foot for R15, makesure these motors are like a tree branch
        
Methods:
	LimbChain:IterateOnce(Vector3 targetPosition, Number tolerance)
        > Performs one forwards or backwards iteration of the fabrik iteration on the IteratedLimbVectorTable
        > Tolerance indicates the distance when the iterations stop if the goal is already reached
    LimbChain:IterateUntilGoal(Vector3 targetPosition, Number tolerance, Number breakcount)
        > Performs forwards or backwards iteration of the fabrik iteration on the IteratedLimbVectorTable
        > Until goal is reached (including tolerance) or maximum iterations in breakcount is reached
	LimbChain:UpdateMotors()
        > Rotates the Motor6D's until the they match the directions of the curent IteratedLimbVectorTable vectors
	LimbChain:DebugModeOn(Bool freezeLimbs, Bool primaryDebug,Bool secondaryDebug)
        > Turns on the debug mode for the FabrikSolver, primary and secondary constraints depending on the bool.
        > the freeze limbs will tell the fabriksolver to not perform iteration and instead update the constraints debug
        > Essentially freezing them in place so you can change the orientation of the constraints

Properties:
	LimbChain.LerpMotors
        > Bool that enables or disables the lerp methods for the IK
    LimbChain.LerpAlpha
        > Number that represents the alpha in CFrame:Lerp() from the motors current C0 towards the IK target goal CFrame
    LimbChain.IncludeFoot
        > Bool that enables or disables the foot placement method which rotated the foot independently
    LimbChain.FootBottomAttachment
        > Attachment required for the foot placement system
    LimbChain.FootBottomRightAttachment
        > Attachment required for the foot placement system place to the right of the initial footbottom
    LimbChain.FootPlacementRaycastParams
        > The raycast params object for the foot to detect the floor
    LimbChain.DebugMode
        > Bool to turn on debug mode which visualizes the limb vectors and the constraints
        > Currently does nothing as this object has debugging properties turned off
    LimbChain.FootBottomAttachment
        > Attachment required for the foot placement system
    LimbChain.PrimaryLimbConstraintTable
        > Table of FabrikConstraint objects which do the constraining for each limb
    LimbChain.SecondaryLimbConstraintTable
        > Table of FabrikConstraint objects which do the constraining for each limb if the target position is
        > out of the primary constraint region
    LimbChain.PrimaryConstraintRegionFromParts
        > Table of BaseParts that the primary constraint region will activate in accordance to the TargetPosition

Enjoy!
- dthecoolest

Thanks EgoMoose for the FABRIK explanation and the explanation on how to do constraints.

--]]
local RunService = game:GetService("RunService")

-- Import the Fabrik Solver Object
local FabrikSolverPointer = script:WaitForChild("FabrikSolver")
local FabrikSolver = require(FabrikSolverPointer)

-- Import Rotated Region 3
local RotatedRegion3Pointer = script:WaitForChild("RotatedRegion3")
local RotatedRegion3 = require(RotatedRegion3Pointer)

-- Initialize Object Class
local Package = script:WaitForChild("BaseRedirect")
local Object = require(Package)
local LimbChain = Object.new("LimbChain")

--[[
    Initializes the limb chain object
    Calculates the limbs from joint to joint as a vector
    And also measures the limb's length
]]
function LimbChain.new(Motor6DTable,IncludeFoot,SpineMotor)
    local obj = LimbChain:make()

    obj.LimbConstraintTable = nil

    obj.LerpMotors = true
    obj.LerpAlpha = 1/4

    obj.IncludeFoot = IncludeFoot
    obj.FootBottomAttachment = nil
    obj.FootBottomRightAttachment = nil
    obj.FootPlacementRaycastParams = nil

    --adds a bool setting for debug mode
    obj.DebugMode = false

    --Adds a setting for enabling constraint regions
    --By default it is nill
    obj.PrimaryConstraintRegionFromParts = nil
    
    --Store the primary and secondary LimbConstraint settings in a table
    obj.PrimaryLimbConstraintTable = {}
    obj.SecondaryLimbConstraintTable = {}

    --[[--------------------------------------------------------------------------------
        This is the beginning of the construction of all the limb vectors from motor6d
    ]]----------------------------------------------------------------------------------
    --Stores the motor6ds used and also the original C0 of the first joint
    obj.Motor6DTable = Motor6DTable
    obj.FirstJointC0 = Motor6DTable[1].C0

    --Store the initial C0
    local Motor6DC0Table = {}
    for i = 1, #Motor6DTable, 1 do
        Motor6DC0Table[#Motor6DC0Table+1] = Motor6DTable[i].C0
    end
    obj.Motor6DC0Table = Motor6DC0Table

    -----initialize LimbVectorTable to store the limb vectors and stores it into the object self variable
    local LimbVectorTable = {}
    local IteratedLimbVectorTable = {}

    for i = 1, #Motor6DTable - 1, 1 do

        local currentVectorStore = LimbChain.JointOneToTwoVector(Motor6DTable[i], Motor6DTable[i + 1])

        --Planning to rework this spine motor system
        if SpineMotor then
            obj.SpineMotor = SpineMotor
            if i==1 then
                obj.SpineMotorC0 = SpineMotor.C0
                local test1 = Motor6DTable[i].C0.Position
                local test2 = -Motor6DTable[i+1].C0.Position
                currentVectorStore = (test1+test2)
            end
        end

        LimbVectorTable[#LimbVectorTable + 1] = currentVectorStore
        IteratedLimbVectorTable[#IteratedLimbVectorTable + 1] = currentVectorStore
    end

    obj.LimbVectorTable = LimbVectorTable
    -- Stores the limb vector table in the iterated version
    obj.IteratedLimbVectorTable = IteratedLimbVectorTable

    -- Finds the length of the limb vectors and puts them in a table for the FABRIK algorithm
    -- Important as it reduces .Magnitude calls therefore reduces Activity
    local LimbLengthTable = {}
    for i = 1, #LimbVectorTable, 1 do
        LimbLengthTable[#LimbLengthTable+1] = LimbVectorTable[i].Magnitude
    end
    
    obj.LimbLengthTable = LimbLengthTable

    --Once the limb vectors are initialized store them in a FabrikSolver object which does the Fabrik iteration
   local LimbFabrikSolver = FabrikSolver.new(IteratedLimbVectorTable,LimbLengthTable,obj)
    
    obj.LimbFabrikSolver = LimbFabrikSolver
    
    --[[--------------------------------------------------------------------------------
        End of the limb vector constructions
    ]]----------------------------------------------------------------------------------

    --finaly return a metatable object thing to construct it
    return obj
end

--[[
    Function that limb chain has to calculate vector limbs
    Input 2 Motor6d joints
    Returns a vector from motorOne to motorTwo joint
    Always constant based on the c0 and c1 Position of the motors
]]
function LimbChain.JointOneToTwoVector(motorOne, motorTwo)
    -- Check if its a motor6d
    if motorOne:IsA("Motor6D") and motorTwo:IsA("Motor6D") then
        local vecOne = motorOne.C1.Position
        local vecTwo = motorTwo.C0.Position
        local combinedVector = vecTwo - vecOne
        return combinedVector
    else
        return "Error: motor 6ds are not inserted in the function"
    end
end

--[[
    Newer iteration method that uses the Fabrik Object instead of a module
    The object stores its own

    CheckAndChangeConstraintRegions:
    Does the constraint region check and change constraints if in region
    If not then default to use the primary constraints
]]
function LimbChain:IterateOnce(targetPosition,tolerance)

    local offsetVector = Vector3.new()

    if self.IncludeFoot then

        local footMotor = self.Motor6DTable[#self.Motor6DTable]
        local currentLimbPart = footMotor.Part1

        local footBottomToAnkleVector

        if self.FootBottomAttachment and self.FootBottomAttachment.Position then
            footBottomToAnkleVector = footMotor.C1.Position-self.FootBottomAttachment.Position
        else
            footBottomToAnkleVector = footMotor.C1.Position
        end

        if currentLimbPart then
            offsetVector = currentLimbPart.CFrame:VectorToWorldSpace(footBottomToAnkleVector)
        end
    end
    
    local newTargetPosition = targetPosition+offsetVector

    self:CheckAndChangeConstraintRegions(targetPosition)

    if self.Motor6DTable[1].Part0 then
        
        local originJointCF = self.Motor6DTable[1].Part0.CFrame * self.FirstJointC0

        self.LimbFabrikSolver:IterateOnce(originJointCF,newTargetPosition, tolerance)
        
    end

end

function LimbChain:IterateUntilGoal(targetPosition,tolerance,InputtedMaxBreakCount)

    local offsetVector = Vector3.new()

    if self.IncludeFoot then
        local footMotor = self.Motor6DTable[#self.Motor6DTable]
        local currentLimbPart = footMotor.Part1

        local footBottomToAnkleVector

        if self.FootBottomAttachment and self.FootBottomAttachment.Position then
            footBottomToAnkleVector = footMotor.C1.Position-self.FootBottomAttachment.Position
        else
            footBottomToAnkleVector = footMotor.C1.Position
        end

        if currentLimbPart then
            offsetVector = currentLimbPart.CFrame:VectorToWorldSpace(footBottomToAnkleVector)
        end
    end

    local newTargetPosition = targetPosition+offsetVector

    --Does the constraint region check and change constraints
    --If not then default to use the primary constraints
    self:CheckAndChangeConstraintRegions(newTargetPosition)

    if self.Motor6DTable[1].Part0 then
        -- Gets the CFrame of the first joint at world space
        local originJointCF = self.Motor6DTable[1].Part0.CFrame * self.FirstJointC0

        --Does the fabrik iteration until goal
        self.LimbFabrikSolver:IterateUntilGoal(originJointCF,newTargetPosition, tolerance,InputtedMaxBreakCount)
    end                             

end
--[[
    Function that rotates the motors to match the algorithm
    Operates by changing the motor's C0 Position to the goal CFrame
    New parameter dt to control lerp
]]
function LimbChain:UpdateMotors()

    -- Gets the CFrame of the Initial joint at world space
    if self.Motor6DTable[1].Part0 then
        local initialJointCFrame = self.Motor6DTable[1].Part0.CFrame * self.FirstJointC0
        
        --Vector sum for the for loop to get the series of position of the next joint based on the algorithm
        local vectorSumFromFirstJoint = Vector3.new()

        local iterateUntil = #self.LimbVectorTable

        --[[
            if there is a spine chain skip the first motor
            First motor will usually control the hip (taken by another chain)
            But what we really want to control is the one connected to the RootPart
            motor w/ part 0 = HumanoidRootPart / RootPart,part 1 = LowerTorso
            ]]
        local skip = self:UpdateSpineMotor(initialJointCFrame) or 0

        --Iterates and start rotating the limbs starting from the first joint
        for i = 1+skip, iterateUntil, 1 do

            --Obtains the current limb that is being worked on
            local originalVectorLimb = self.LimbVectorTable[i]
            local currentVectorLimb = self.IteratedLimbVectorTable[i]

            --Obtains the CFrame of the part0 limb of the motor6d
            local previousLimbPart = self.Motor6DTable[i].Part0
            if previousLimbPart then
                local previousLimbCF = previousLimbPart.CFrame

                -- Obtains the CFrame rotation calculation for CFrame.fromAxis
                local limbVectorRelativeToOriginal = previousLimbCF:VectorToWorldSpace(originalVectorLimb)
                local dotProductAngle = limbVectorRelativeToOriginal.Unit:Dot(currentVectorLimb.Unit)
                local safetyClamp = math.clamp(dotProductAngle, -1, 1)
                local limbRotationAngle = math.acos(safetyClamp)
                local limbRotationAxis = limbVectorRelativeToOriginal:Cross(currentVectorLimb) -- obtain the rotation axis

                --Checks if the axis exists if cross product returns zero somehow
                if limbRotationAxis~=Vector3.new(0,0,0) then
                
                    --Gets the world space of the joint from the iterated limb vectors
                    if i ~= 1 then
                    vectorSumFromFirstJoint = vectorSumFromFirstJoint + self.IteratedLimbVectorTable[i-1]
                    end

                    --Gets the position of the current limb joint
                    local motorPosition = initialJointCFrame.Position + vectorSumFromFirstJoint

                    --Now adding a debug mode----------------------------------------------------------------
                    --Puts the created parts according to the motor position
                    --[[
                    if self.DebugMode then
                        workspace["LimbVector:"..i].Position = motorPosition
                    end
                    ]]
                    ----------------------------------------------------------------
                    --Obtain the CFrame operations needed to rotate the limb to the goal
                    local undoPreviousLimbCF = previousLimbCF:Inverse()*CFrame.new(motorPosition)
                    local rotateLimbCF =CFrame.fromAxisAngle(limbRotationAxis,limbRotationAngle)*CFrame.fromMatrix(Vector3.new(),previousLimbCF.RightVector,previousLimbCF.UpVector)
                    
                    local goalCF = undoPreviousLimbCF*rotateLimbCF

                    local rotationOnly = goalCF-goalCF.Position

                    local currentRotation = self.Motor6DTable[i].C0-self.Motor6DTable[i].C0.Position

                    --if the bool is true then use lerp
                    if self.LerpMotors then
                        
                        local newRotationCF = currentRotation:lerp(rotationOnly,self.LerpAlpha)

                        --Changes the current motor6d through c0 and lerp
                        self.Motor6DTable[i].C0 = CFrame.new(self.Motor6DTable[i].C0.Position)*newRotationCF
                    else
                        self.Motor6DTable[i].C0 = CFrame.new(self.Motor6DTable[i].C0.Position)*rotationOnly
                    end

                end
            end
        end

        --Special for the foot motor system which controls the last motor
        if self.IncludeFoot then

            --the last motor index
            local footMotorIndex = #self.IteratedLimbVectorTable

            --Sums up the limb vectors to get the last motor position
            vectorSumFromFirstJoint = vectorSumFromFirstJoint + self.IteratedLimbVectorTable[footMotorIndex]
        

            --Gets the position of the current limb joint
            local motorPosition = initialJointCFrame.Position + vectorSumFromFirstJoint

            --Now does controls the motor
            --ony if the attachments are set
            if self.FootBottomAttachment and self.FootBottomRightAttachment then
                self:UpdateFootMotor(motorPosition)
            end
        
        end
    end
end

function LimbChain:UpdateFootMotor(footMotorPosition)

    --get the foot motor which is the last motor of the limb
    local footMotor = self.Motor6DTable[#self.Motor6DTable]
        
    --Obtains the CFrame of the part0 limb of the motor6d
    local previousLimbPart = self.Motor6DTable[#self.Motor6DTable].Part0
    
    if previousLimbPart then
        local previousLimbCF = previousLimbPart.CFrame

        --Obtain variables from self object
        local lengthToFloor = self.LengthToFloor
        if not self.LengthToFloor then
            --Default is 10 units down
            lengthToFloor = 10

        end
        local downDirection = lengthToFloor*Vector3.new(0,-1,0)

        local FootPlacementRaycastParams = self.FootPlacementRaycastParams

        --move it up a bit to give raycast space from floor
        local up = Vector3.new(0,1,0)
        local footBottomPosition = self.FootBottomAttachment.WorldPosition+up
        local footBottomRaycastResult = workspace:Raycast(footBottomPosition,downDirection,FootPlacementRaycastParams)

        local footBottomRightPosition = self.FootBottomRightAttachment.WorldPosition+up
        local footBottomRightRaycastResult = workspace:Raycast(footBottomRightPosition,downDirection,FootPlacementRaycastParams)

        --nill check for if its empty
        if footBottomRaycastResult and footBottomRightRaycastResult then

            --Get the average normal vector from both attachments
            local footNormal = (footBottomRaycastResult.Normal+footBottomRightRaycastResult.Normal)/2
            local footRightVector = footBottomRightRaycastResult.Position - footBottomRaycastResult.Position

            if self.Motor6DTable[1].Part0 then

                local hipRightVector = self.Motor6DTable[1].Part0.CFrame.RightVector

                --average it with how the hip is facing to keep the foot facing forwards
                local newFootRightVector = (0.8*footRightVector+0.2*hipRightVector)/2
                
                local undoPreviousLimbCF = previousLimbCF:Inverse()

                --Foot Motor position is the c0 joint in world terms
                local placeAtFootMotor = CFrame.new(footMotorPosition)
                local rotateToFloor = CFrame.fromMatrix(Vector3.new(),newFootRightVector,footNormal)

                --The goal rotation and Position of the foot C0 motor
                local goalCF = undoPreviousLimbCF*placeAtFootMotor*rotateToFloor

                local rotationOnly = goalCF-goalCF.Position

                --finds the current rotation of the foot currently without position
                local currentRotation = footMotor.C0-footMotor.C0.Position

                if self.LerpMotors then
                    --does the lerp for the rotation from current to the new goal
                    local newRotationCF = currentRotation:lerp(rotationOnly,self.LerpAlpha)

                    --then updates the foot motor
                    footMotor.C0 = CFrame.new(footMotor.C0.Position)*newRotationCF
                else
                    --goes straight to the goal position
                    footMotor.C0 = CFrame.new(footMotor.C0.Position)*rotationOnly
                end
            end
        else
            --default to facing "Up" towards sky
            local footNormal = Vector3.new(0,1,0)

            local footRightVector = previousLimbCF.RightVector

            local undoPreviousLimbCF = previousLimbCF:Inverse()
            --local empty = 
            local orientToFloor = CFrame.fromMatrix(footMotorPosition,footRightVector,footNormal)

            local goalCF = undoPreviousLimbCF*orientToFloor

            local rotationOnly = goalCF-goalCF.Position

            --finds the current rotation of the foot currently without position
            local currentRotation = footMotor.C0-footMotor.C0.Position

            if self.LerpMotors then

                local newRotationCF = currentRotation:lerp(rotationOnly,self.LerpAlpha)

                --then updates the foot motor
                footMotor.C0 = CFrame.new(footMotor.C0.Position)*newRotationCF

            else
                footMotor.C0 = CFrame.new(footMotor.C0.Position)*rotationOnly
            end

        end
    end
end

function LimbChain:UpdateSpineMotor(initialJointCFrame)

    if self.SpineMotor then
        local skip = 1
        --Then does the rotation for the spine chain
        local firstMotorWorldPosition = initialJointCFrame.Position
        local secondMotorWorldPosition = initialJointCFrame.Position+self.IteratedLimbVectorTable[1]
        local newUpVector = secondMotorWorldPosition - firstMotorWorldPosition

        --Obtains the CFrame of the part0 limb of the motor6d
        local previousLimbPart = self.SpineMotor.Part0
        local previousLimbCF = previousLimbPart.CFrame 

        local SpineMotorWorldPosition = previousLimbCF*self.SpineMotorC0.Position

        local newRight = previousLimbCF.LookVector:Cross(newUpVector)

        local undoPreviousLimbCF = previousLimbCF:Inverse()
        local rotateSpine = CFrame.fromMatrix(SpineMotorWorldPosition,newRight,newUpVector)

        --Obtain the goal world space CFrame
        local goalCF = undoPreviousLimbCF*rotateSpine

        local rotationOnly = goalCF-goalCF.Position

        --Current rotation of motors
        local currentRotation = self.SpineMotor.C0-self.SpineMotor.C0.Position

        --if the bool is true then use lerp
        if self.LerpMotors then
            
            local newRotationCF = currentRotation:lerp(rotationOnly,self.LerpAlpha)

            --Changes the current motor6d through c0 and lerp
            self.SpineMotor.C0 = CFrame.new(self.SpineMotor.C0.Position)*newRotationCF
        else
            self.SpineMotor.C0 = CFrame.new(self.SpineMotor.C0.Position)*rotationOnly
        end
        return skip
    end
end

--Prints  the limb vector and iterated limb vector
--For debugging not needed now
function LimbChain:PrintLimbVectors()

    for i=1,#self.LimbVectorTable,1 do
        print("Limbvector table i:",i," Vector:",self.LimbVectorTable[i])
    end
    for i=1,#self.IteratedLimbVectorTable,1 do
        print("Iterated self table i:",i," Vector:",self.IteratedLimbVectorTable[i])
    end

end

--Gets the original vector limb direction relative to the part
--Required for the rigid constraint
function LimbChain:GetOriginalLimbDirection(limbVectorNumber)

    local i = limbVectorNumber

    --Obtains the current limb that is being worked on
    local originalVectorLimb = self.LimbVectorTable[i]

    --print(self.Motor6DTable[i].Part0)
    --Obtains the CFrame of the part0 limb of the motor6d
    local previousLimbPart = self.Motor6DTable[i].Part0
    local previousLimbCF = previousLimbPart.CFrame

    -- Obtains the vector relative to the previous part0
    local limbVectorRelativeToOriginal = previousLimbCF:VectorToWorldSpace(originalVectorLimb)
    
    return limbVectorRelativeToOriginal

end

--Testing for feet
--unused now
function LimbChain:GetOriginalFeetLimb()

    --Obtains the current limb that is being worked on
    local originalVectorLimb = self.extraLimbVector

    --Obtains the CFrame of the part0 limb of the motor6d
    local previousLimbPart = self.Motor6DTable[#self.Motor6DTable].Part0
    local previousLimbCF = previousLimbPart.CFrame

    -- Obtains the vector relative to the previous part0
    local limbVectorRelativeToOriginal = previousLimbCF:VectorToWorldSpace(originalVectorLimb)

    return limbVectorRelativeToOriginal

end

--[[--------------------------------------------------------
    Sets the current constraints that the FABRIK algorithm will take note of

]]
function LimbChain:SetCurrentConstraints(LimbConstraintTable)

    --Changes the constraint table and the fabrik solvers as well
    self.LimbConstraintTable = LimbConstraintTable
    self.LimbFabrikSolver.LimbConstraintTable = LimbConstraintTable

end

--[[--------------------------------------------------------
    Defines the parts that the primary constraints is only allowed to be
    activated in using a region 3 check at the target position.

    If outside primary region then switches to secondary region
]]
function LimbChain:CheckAndChangeConstraintRegions(targetPosition)

    local PrimaryConstraintRegionFromParts = self.PrimaryConstraintRegionFromParts

    --[[
        Checks if the region is set in the first place
        ]]
    if PrimaryConstraintRegionFromParts then

        local isTargetInsideConstraintRegion = false

        for i=1,#PrimaryConstraintRegionFromParts,1 do

            local PartConstraintRegion = RotatedRegion3.FromPart(PrimaryConstraintRegionFromParts[i])

            local check = PartConstraintRegion:CastPoint(targetPosition)

            if check == true then
             isTargetInsideConstraintRegion = true
            end

        end

        if isTargetInsideConstraintRegion then
            self:SetCurrentConstraints(self.PrimaryLimbConstraintTable)
        else
            self:SetCurrentConstraints(self.SecondaryLimbConstraintTable)
        end

    else
        self:SetCurrentConstraints(self.PrimaryLimbConstraintTable)
    end

end--end of function

local function findIndexInTables(name,nameTables)

    local index --Index of where the name is locatd in the table
    local nameTableIndex --which table is it
    for i,nameTable in pairs(nameTables) do
        
        local findings = table.find(nameTable,name)
        if findings then
            index = findings
            nameTableIndex = i
        end
    end

    return index,nameTableIndex
    
end

function LimbChain.convertNamesToMotor6DInstancesInModel(model,...) 
    local nameTables = {...} 
    local modelDescendants = model:GetDescendants()
    for i,v in pairs(modelDescendants) do
        if v:IsA("Motor6D") then 
            local index, nameTableIndex = findIndexInTables(v.Name,nameTables)
            if index then
                nameTables[nameTableIndex][index] = v
            end
        end
    end
end

function LimbChain:DebugModeOn(FreezeLimbs, PrimaryDebug, SecondaryDebug)
    --turns constraints debug mode to true
    if PrimaryDebug then
        for _, v in pairs(self.PrimaryLimbConstraintTable) do
            if not v.DebugMode then
                v.DebugMode = true
            end
        end
    end

    if SecondaryDebug then
        for _, v in pairs(self.SecondaryLimbConstraintTable) do
            if not v.DebugMode then
                v.DebugMode = true
            end
        end
    end

    --forces iterate once to keep iterating very laggy but updates the constraints
    self.LimbFabrikSolver.DebugMode = true
    self.LimbFabrikSolver.FreezeLimbs = FreezeLimbs
end

function LimbChain:InitDragDebug()

    local lastMotor = self.Motor6DTable[#self.Motor6DTable]
    local endOfChainPosition = lastMotor.Part1.Position
    local part = Instance.new("Part")
    part.Position = endOfChainPosition
    part.Size = Vector3.new(1,1,1)
    part.BrickColor = BrickColor.random()
    part.Name = "DragMeAround_"..lastMotor.Name
    part.CanCollide = false
    part.Anchored = true
    part.Parent = workspace

    RunService.Heartbeat:Connect(function()
    self:IterateOnce(part.Position,0.1)
    self:UpdateMotors()
    end)

end

return LimbChain
