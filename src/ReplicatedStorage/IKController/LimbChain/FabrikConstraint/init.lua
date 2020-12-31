--[[
    Base class for the constraint type objects which assigns the constraints axis to a BasePart
    Also responsible for creating the cone to visualize the constraints
]]

--Get services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

-- Initialize Object Class
local Package = script:FindFirstAncestor("LimbChain")
local Object = require(Package.BaseRedirect)

local FabrikConstraint = Object.new("FabrikConstraint")

-- Creates a constraint with axis that depend on the part
function FabrikConstraint.new(Part)
    local obj = FabrikConstraint:make()

    --If there is a part, relative constraint axis is set accordingly
    if Part then
    obj.Part = Part
    obj.CenterAxis = Part.CFrame.LookVector
    obj.XAxis = Part.CFrame.RightVector
    obj.YAxis = Part.CFrame.UpVector
    end

    obj.DebugMode = false

    return obj
end

--[[
    The method all constraints should inherit
    empty as each constraint has it's own special constraint method
]]
function FabrikConstraint:ConstrainLimbVector()

end


--[[
    Method for the constraints to inherit if you want to the axis to change
    Currently broken because of the weld constraint changing the model's CFrame also
]]
function FabrikConstraint:RotateCFrameOrientation(goalCFrameRotation) 

    --disable the weld constraint first to prevent it moving
    self.Part:FindFirstChild("WeldConstraint").Enabled = false

    --Change the constraint
    self.Part.CFrame = CFrame.new(self.Part.CFrame.Position)*goalCFrameRotation 

    --Disable the weld Constraint
    self.Part:FindFirstChild("WeldConstraint").Enabled = true

end

--[[
    Methods to set and get the current axis of the part
    fairly activity intensive goes from 1-2% to 4-6% max
    Also problem as it requires the part motor to update 
]]
function FabrikConstraint:UpdateAxis(JointPosition)

    self.CenterAxis = self.Part.CFrame.LookVector
    self.XAxis = self.Part.CFrame.RightVector
    self.YAxis = self.Part.CFrame.UpVector

    if self.DebugMode then
        self:DebugAxis(JointPosition)
    end

end

--function to visualize direction of the axis
--Only creates the clone
function FabrikConstraint:DebugAxis(JointPosition)

    if not self.DebugInitialized then
        self.DebugInitialized = true
        
        --[[
        --for debugging the joint axis without the cone stuff
        local LimbAxis = Instance.new("WedgePart")
        LimbAxis.BrickColor = BrickColor.random()
        LimbAxis.Name = "LimbAxis"
        LimbAxis.Anchored = true
        LimbAxis.CanCollide = false
        LimbAxis.Size = Vector3.new(2,2,4)
        self.LimbAxis = LimbAxis
        LimbAxis.Parent = workspace:WaitForChild("RayFilterFolder")
        ]]

        --create the cone to debug the axis
        local cone = ReplicatedStorage:FindFirstChild("EnhancedCone")

        if not cone then
            local assetId = 5883549047
            cone = InsertService:LoadAsset(assetId):WaitForChild("EnhancedCone")
        end

        self.Cone = cone:Clone()
        self.Cone.Transparency = 0.5
        self.Cone.Anchored = true
        self.Cone.CanCollide = false
        self.Cone.BrickColor = BrickColor.random()
        self.Cone.Parent = workspace:WaitForChild("RayFilterFolder")

    else
        
        --for debugging the joint axis
       -- self.LimbAxis.CFrame = CFrame.fromMatrix(JointPosition,self.XAxis,self.YAxis)

    end

end

return FabrikConstraint
