-- CCDIKController
-- Dthecoolest
-- December 27, 2020

local Debris = game:GetService("Debris")-- for debugging

local VectorUtil = require(script.VectorUtil)
local Maid = require(script.Maid)

--Axis angle version still here for testing purposes
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
--The cooler version (⌐□_□)
local function getRotationBetween(u, v, axis)
    local dot, uxv = u:Dot(v), u:Cross(v)
    if (dot < -0.99999) then return CFrame.fromAxisAngle(axis, math.pi) end
    return CFrame.new(0, 0, 0, uxv.x, uxv.y, uxv.z, 1 + dot)
end
--[[
	Amount is in radians
]]
local function rotateVectorAround( v, amount, axis )
	return CFrame.fromAxisAngle(axis, amount):VectorToWorldSpace(v)
end

local CFNEW = CFrame.new
local CFLOOKAT = CFrame.lookAt
local ZEROVEC = Vector3.new()

--local motor6d = Instance.new("Motor6D")
--Dictionary of how to setup the axis constraints
local hipJoint = Instance.new("Motor6D")
local kneeJoint = Instance.new("Motor6D")
local constraintsTemplate = {
	[kneeJoint] = {
		["ConstraintType"] = "Hinge";
		["UpperAngle"] = 45; -- same as HingeConstraint [-180,180] degrees
		["LowerAngle"] = -45;
		["AxisAttachment"] = nil; --Automatically tries to find first child an attachment with the part0Motor6dName..AxisAttachment
		["JointAttachment"] = nil;
	};
	[hipJoint] = {
		["ConstraintType"] = "BallSocketConstraint";
		["UpperAngle"] = 45; -- same as BallSocketConstraint [-180,180] degrees
		["TwistLimitsEnabled"] = false ; -- still have no idea how to do
		["TwistUpperAngle"] = -45; -- so yeah no twist limits for now
		["TwistLowerAngle"] = -45;
		["AxisAttachment"] = nil; --Automatically tries to find first child during .new() setup but you can manually input it
		["JointAttachment"] = nil;
	};
}

local CCDIKController = {}
CCDIKController.__index = CCDIKController

function CCDIKController.new(Motor6DTable,Constraints)
	local self = setmetatable({}, CCDIKController)

	self.Maid = Maid.new()
	self.Motor6DTable = Motor6DTable
	self.Constraints = Constraints
	self:SetupJoints()
	self.EndEffector = Motor6DTable[#Motor6DTable].Part1:FindFirstChild("EndEffector")
	self.DebugMode = false
	self.LerpMode = true
	self.LerpAlpha = 0.25

	return self
end

--[[
	Sets up the attachments to find the Motor6D joints position in world space, also tries to find the constraint axis
]]
function CCDIKController:SetupJoints()
	local joints ={}
	local jointAxisInfo = {}
	for _,motor in pairs(self.Motor6DTable) do
		--In order to find the joint in world terms and index it fast, only thing that needs to be destroyed
		local attachment = Instance.new("Attachment")
		attachment.CFrame = motor.C0
		attachment.Name = "JointPosition"
		attachment.Parent = motor.Part0
		joints[motor] = attachment
		self.Maid:GiveTask(attachment)
		if self.Constraints then
			local motorConstraints = self.Constraints[motor]
			if motorConstraints then
				--If it doesn't already have an axis attachment, find one,
				if not motorConstraints.AxisAttachment then
					local AxisAttachment = motor.Part0:FindFirstChild(motor.Part0.Name.."AxisAttachment")
					motorConstraints["AxisAttachment"] = AxisAttachment
				elseif typeof(motorConstraints.AxisAttachment) == "string" then
					local AxisAttachment = motor.Part0:FindFirstChild(motorConstraints.AxisAttachment.."AxisAttachment")
					motorConstraints["AxisAttachment"] = AxisAttachment
				end
				--same here for joint attachment
				if not motorConstraints.JointAttachment then
					local JointAttachment = motor.Part1:FindFirstChild(motor.Part0.Name.."JointAttachment")
					motorConstraints["JointAttachment"] = JointAttachment
				elseif typeof(motorConstraints.JointAttachment) == "string" then
					local JointAttachment = motor.Part1:FindFirstChild(motorConstraints.JointAttachment.."JointAttachment")
					motorConstraints["JointAttachment"] = JointAttachment
				end

			end
		end
	end
	self.JointInfo = joints
	self.JointAxisInfo = jointAxisInfo
end

function CCDIKController:CCDIKIterateOnce(goalPosition,tolerance)
	local constraints = self.Constraints
	local endEffectorPosition
	if self.EndEffector then
		endEffectorPosition = self.EndEffector.WorldPosition
	else
		endEffectorPosition = self.Motor6DTable[#self.Motor6DTable].Part1.Position
	end

	local distanceToGoal = endEffectorPosition-goalPosition
	local tolerance = tolerance or 1
	
	if distanceToGoal.Magnitude > tolerance then
		for i= #self.Motor6DTable-1, 1, -1 do
			local currentJoint = self.Motor6DTable[i]
			self:RotateFromEffectorToGoal(currentJoint,goalPosition)
			if constraints then
				local jointConstraintInfo = constraints[currentJoint]
				if jointConstraintInfo then
					if jointConstraintInfo.ConstraintType == "Hinge" then
						self:RotateToHingeAxis(currentJoint,jointConstraintInfo)
					end
					if jointConstraintInfo.ConstraintType == "BallSocketConstraint" then
						self:RotateToBallSocketConstraintAxis(currentJoint,jointConstraintInfo)
					end
				end
			end
		end
	end
end

-- Same as Iterate once but in a while loop
function CCDIKController:CCDIKIterateUntil(goalPosition,tolerance,maxBreakCount)
	local maxBreakCount = maxBreakCount or 10
	local currentIterationCount = 0
	local constraints = self.Constraints
	local endEffectorPosition
	if self.EndEffector then
		endEffectorPosition = self.EndEffector.WorldPosition
	else
		endEffectorPosition = self.Motor6DTable[#self.Motor6DTable].Part1.Position
	end

	local distanceToGoal = endEffectorPosition-goalPosition
	local tolerance = tolerance or 1
	
	while distanceToGoal.Magnitude > tolerance and maxBreakCount >= currentIterationCount do
		currentIterationCount += 1
		for i= #self.Motor6DTable-1, 1, -1 do
			local currentJoint = self.Motor6DTable[i]
			self:RotateFromEffectorToGoal(currentJoint,goalPosition)
			if constraints then
				local jointConstraintInfo = constraints[currentJoint]
				if jointConstraintInfo then
					if jointConstraintInfo.ConstraintType == "Hinge" then
						self:RotateToHingeAxis(currentJoint,jointConstraintInfo)
					end
					if jointConstraintInfo.ConstraintType == "BallSocketConstraint" then
						self:RotateToBallSocketConstraintAxis(currentJoint,jointConstraintInfo)
					end
				end
			end
		end
	end
end


function CCDIKController.rotateJointFromTo(motor6DJoint,u,v,axis)
	local rotationCFrame = getRotationBetween(u,v,axis)
	rotationCFrame = motor6DJoint.Part0.CFrame:Inverse()*rotationCFrame*motor6DJoint.Part1.CFrame
	rotationCFrame = rotationCFrame-rotationCFrame.Position
	motor6DJoint.C0 = CFrame.new(motor6DJoint.C0.Position)*rotationCFrame
end

function CCDIKController:rotateJointFromToWithLerp(motor6DJoint,u,v,axis)
	local rotationCFrame = getRotationBetween(u,v,axis)
	rotationCFrame = motor6DJoint.Part0.CFrame:Inverse()*rotationCFrame*motor6DJoint.Part1.CFrame
	rotationCFrame = rotationCFrame-rotationCFrame.Position
	local goalC0CFrame = CFrame.new(motor6DJoint.C0.Position)*rotationCFrame
	local lerpAlpha = self.LerpAlpha
	motor6DJoint.C0 = motor6DJoint.C0:Lerp(goalC0CFrame,lerpAlpha)
end

function CCDIKController:RotateFromEffectorToGoal(motor6d : Motor6D,goalPosition)

	local motor6dPart0 = motor6d.Part0
	local part0CF = motor6dPart0.CFrame

	local jointWorldPosition = self.JointInfo[motor6d].WorldPosition
	--local jointWorldPosition = (motor6d.Part0.CFrame*motor6d.C0).Position
	--Faster to use attachments
	local endEffectorPosition
	if self.EndEffector then
		endEffectorPosition = self.EndEffector.WorldPosition
	else
		endEffectorPosition = self.Motor6DTable[#self.Motor6DTable].Part0.Position
	end

	local directionToEffector = (endEffectorPosition - jointWorldPosition).Unit
	local directionToGoal = (goalPosition - jointWorldPosition).Unit
	if self.DebugMode then
		self.VisualizeVector(jointWorldPosition,endEffectorPosition - jointWorldPosition,BrickColor.Blue())
		self.VisualizeVector(jointWorldPosition,goalPosition - jointWorldPosition,BrickColor.Red())
	end
	if self.LerpMode ~= true then
		self.rotateJointFromTo(motor6d,directionToEffector,directionToGoal,part0CF.RightVector)
	else
		self:rotateJointFromToWithLerp(motor6d,directionToEffector,directionToGoal,part0CF.RightVector)
	end
end

--[[---------------------------------------------------------
This function constraints the rotation of the part1 to the hinge axis of the part0, then also does local EulerAngle constraints

Dictionary to setup the constraint information:
	[motor6d] = {
		["ConstraintType"] = "Hinge";
		["UpperAngle"] = 45; -- same as HingeConstraint [-180,180] degrees
		["LowerAngle"] = -45;
		["AxisAttachment"] = nil; --Automatically tries to find first child during .new() setup but you can manually input it
		["JointAttachment"] = nil;
	};
]]
function CCDIKController:RotateToHingeAxis(motor6d : Motor6D,jointConstraintInfo)
	local motor6dPart0 = motor6d.Part0
	local part0CF = motor6dPart0.CFrame
	local axisAttachment = jointConstraintInfo.AxisAttachment
	local jointAttachment = jointConstraintInfo.JointAttachment

	local hingeAxis = axisAttachment.WorldAxis
	local currentHingeAxis = jointAttachment.WorldAxis 

	--Enforce hinge axis, has to be instantaneous
	self.rotateJointFromTo(motor6d,currentHingeAxis,hingeAxis,part0CF.RightVector)

	--Then enforce hinge constraints
	local axisCFrame = axisAttachment.WorldCFrame
	local jointCFrame = jointAttachment.WorldCFrame

	local upperAngle = jointConstraintInfo.UpperAngle or 180
	local lowerAngle = jointConstraintInfo.LowerAngle or -180

	local localCFrame : CFrame
	localCFrame = axisCFrame:ToObjectSpace(jointCFrame)
	local x,_,_ = localCFrame:ToEulerAnglesXYZ()
	--print(math.round(math.deg(x)),math.round(math.deg(y)),math.round(math.deg(z))) -- yep x is the rotation
	local constrainedX = math.clamp(math.deg(x),lowerAngle,upperAngle)
	constrainedX = math.rad(constrainedX)
	local constrainedJointCFrame = CFrame.fromEulerAnglesXYZ(constrainedX,0,0)
	local newWorldJointCFrame = axisCFrame:ToWorldSpace(constrainedJointCFrame)
	local newPart1CFrame = newWorldJointCFrame*jointAttachment.CFrame:Inverse() -- Uhh only works with attachments
	local goalCFRotation = motor6d.Part0.CFrame:Inverse()*newPart1CFrame
	goalCFRotation = goalCFRotation-goalCFRotation.Position
	motor6d.C0 = CFrame.new(motor6d.C0.Position)*goalCFRotation

end

--[[---------------------------------------------------------
This function constraints the rotation of the part1 to the hinge axis of the part0, then also does local EulerAngle constraints
	
Dictionary to setup the constraint information:
	[motor6d] = {
		["ConstraintType"] = "BallSocketConstraint";
		["UpperAngle"] = 45; -- same as BallSocketConstraint [-180,180] degrees
		["TwistLimitsEnabled"] = ; -- still have no idea how to do
		["TwistUpperAngle"] = -45;--
		["TwistLowerAngle"] = -45;
		["AxisAttachment"] = nil; --Automatically tries to find first child during .new() setup but you can manually input it
		["JointAttachment"] = nil;
	};
]]
function CCDIKController:RotateToBallSocketConstraintAxis(motor6d,jointConstraintInfo)
	local motor6dPart0 = motor6d.Part0
	local part0CF = motor6dPart0.CFrame
	local axisAttachment = jointConstraintInfo.AxisAttachment
	local jointAttachment = jointConstraintInfo.JointAttachment

	local centerAxis = axisAttachment.WorldAxis
	local currentCenterAxis = jointAttachment.WorldAxis 
	local angleDifference = VectorUtil.AngleBetween(currentCenterAxis,centerAxis)

	local constraintUpperAngle = math.rad(jointConstraintInfo.UpperAngle) or math.rad(45)

	--out of bounds constrain it to world axis of the socket
	if angleDifference > constraintUpperAngle then
		local axis = currentCenterAxis:Cross(centerAxis)
		local angleDifference = angleDifference-constraintUpperAngle
		local newCenterAxisWithinBounds = rotateVectorAround( currentCenterAxis, angleDifference, axis )
		self.rotateJointFromTo(motor6d,currentCenterAxis,newCenterAxisWithinBounds,part0CF.RightVector)
	end

end


--[[
	Utility function spawning a wedge part to visualize a vector in world space
]]
function CCDIKController.VisualizeVector(position,direction,brickColor)
	local wedgePart = Instance.new("WedgePart")
	wedgePart.Size = Vector3.new(1,1,direction.Magnitude)
	wedgePart.CFrame = CFLOOKAT(position,position+direction)*CFrame.new(0,0,-direction.Magnitude/2)
	wedgePart.Anchored = true
	wedgePart.CanCollide = false
	wedgePart.BrickColor = brickColor or BrickColor.random()
	wedgePart.Parent = workspace
	Debris:AddItem(wedgePart,1)
end

--[[---------------------------------------------------------
	Reverse Humanoid:BuildRigFromAttachments
	Finds Motor6D's and places where the joints are located as attachments
	Usefull for creating HingeConstraints and BallSocketConstraints to visualize and orientate the attachments
	Pretty necessary in fact to create the attachment axis and decide the upper angle or lower angle
]]
function CCDIKController.CommandBarSetupJoints(model)
	local modelDescendants = model:GetDescendants()
	for _,motor6D in pairs(modelDescendants) do
		if motor6D:IsA("Motor6D") then
			--In order to find the joint in world terms
			local Part0Name = motor6D.Part0.Name
			local AxisAttachment = Instance.new("Attachment")
			AxisAttachment.CFrame = motor6D.C0
			AxisAttachment.Name = Part0Name.."AxisAttachment"
			AxisAttachment.Parent = motor6D.Part0
	
			local JointAttachment = Instance.new("Attachment")
			JointAttachment.CFrame = motor6D.C1
			JointAttachment.Name = Part0Name.."JointAttachment"
			JointAttachment.Parent = motor6D.Part1
		end
	end
end
--[[
	Do cleaning destroys all the instances made by this object
]]
function CCDIKController:Destroy()
	self.Maid:DoCleaning()
	self = nil
end

return CCDIKController