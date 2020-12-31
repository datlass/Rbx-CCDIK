-- IKController
-- Dthecoolest
-- December 27, 2020

local Debris = game:GetService("Debris")

local VectorUtil = require(script.VectorUtil)
local Quaternion = require(script.Quaternion)

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

--Quanternion rotation version from Egomoose
local function getRotationBetween(u, v, axis)
    local dot, uxv = u:Dot(v), u:Cross(v)
    if (dot < -0.99999) then return CFrame.fromAxisAngle(axis, math.pi) end
    return CFrame.new(0, 0, 0, uxv.x, uxv.y, uxv.z, 1 + dot)
end

local CFNEW = CFrame.new
local CFLOOKAT = CFrame.lookAt
local ZEROVEC = Vector3.new()

local IKController = {}
IKController.__index = IKController

function IKController.new(Motor6DTable,Constraints)
	local self = setmetatable({}, IKController)

	self.Motor6DTable = Motor6DTable
	self.Constraints = Constraints
	self:SetupJoints()
	self.EndEffector = Motor6DTable[#Motor6DTable].Part1:FindFirstChild("EndEffector")
	self.DebugMode = false
	return self
end

function IKController:SetupJoints()
	local joints ={}
	local jointAxisInfo = {}
	for _,motor in pairs(self.Motor6DTable) do
		local attachment = Instance.new("Attachment")
		attachment.CFrame = motor.C0
		attachment.Name = "JointPosition"
		attachment.Parent = motor.Part0
		joints[motor] = attachment
	end
	self.JointInfo = joints
	self.JointAxisInfo = jointAxisInfo
end


function IKController:CCDIKIterateOnce(goalPosition,tolerance)
	local distanceToGoal = self.EndEffector.WorldPosition-goalPosition
	local tolerance = tolerance or 1
	
	if distanceToGoal.Magnitude > tolerance then
		for i= #self.Motor6DTable-1, 1, -1 do
			local currentJoint = self.Motor6DTable[i]
			self:RotateFromEffectorToGoal(currentJoint,goalPosition)
			--self:RotateToHingeAxis(currentJoint)
			if self.DebugMode then
				wait(0.5)
			end
		end
	end
end

function IKController:CCDIKIterateUntil(goalPosition,tolerance)
	local distanceToGoal = self.EndEffector.WorldPosition-goalPosition
	local tolerance = tolerance or 1
	
	while distanceToGoal.Magnitude > tolerance do
		for i= #self.Motor6DTable-1, 1, -1 do
			local currentJoint = self.Motor6DTable[i]
			self:RotateFromTo(currentJoint,goalPosition)
		end
	end
end


function IKController:RotateFromEffectorToGoal(motor6d : Motor6D,goalPosition)

	local motor6dPart0 = motor6d.Part0
	local part0CF = motor6dPart0.CFrame

	local jointWorldPosition = self.JointInfo[motor6d].WorldPosition
	--local jointWorldPosition = (motor6d.Part0.CFrame*motor6d.C0).Position

	local endEffectorPosition = self.EndEffector.WorldPosition

	local directionToEffector = (endEffectorPosition - jointWorldPosition).Unit
	local directionToGoal = (goalPosition - jointWorldPosition).Unit
	if self.DebugMode then
		self.VisualizeVector(jointWorldPosition,endEffectorPosition - jointWorldPosition,BrickColor.Blue())
		self.VisualizeVector(jointWorldPosition,goalPosition - jointWorldPosition,BrickColor.Red())
	end
	local rotationCFrame = fromToRotation(directionToEffector,directionToGoal,part0CF.RightVector)

	rotationCFrame = rotationCFrame*motor6d.Part1.CFrame*part0CF:Inverse()
	rotationCFrame = rotationCFrame-rotationCFrame.Position
	motor6d.C0 = CFrame.new(motor6d.C0.Position)*rotationCFrame

	--motor6d.C0 = motor6d.C0*rotationCFrame

end

function IKController:RotateToHingeAxis(motor6d : Motor6D)
	local motor6dPart0 = motor6d.Part0
	local part0CF = motor6dPart0.CFrame

	local hingeAxis = motor6d.C0.RightVector
	local currentHingeAxis = motor6d.C1.RightVector

	local rotationCFrame = getRotationBetween(hingeAxis,currentHingeAxis,Vector3.new(0,1,0))
	motor6d.C0 = motor6d.C0*rotationCFrame

end


function IKController.VisualizeVector(position,direction,brickColor)
	local wedgePart = Instance.new("WedgePart")
	wedgePart.Size = Vector3.new(1,1,direction.Magnitude)
	wedgePart.CFrame = CFLOOKAT(position,position+direction)*CFrame.new(0,0,-direction.Magnitude/2)
	wedgePart.Anchored = true
	wedgePart.CanCollide = false
	wedgePart.BrickColor = brickColor or BrickColor.random()
	wedgePart.Parent = workspace
	Debris:AddItem(wedgePart,1)
end

return IKController

