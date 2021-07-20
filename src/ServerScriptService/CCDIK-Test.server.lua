--Testing with my mech model
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CCDIKController = require(ReplicatedStorage.Source.CCDIKController)

local RunService = game:GetService("RunService")

local mech = workspace.LowerBody
local leftTarget = workspace.MechLTarget

local mechMotor6Ds = {}

local mechDescendants = mech:GetDescendants()
for _,descendant in pairs (mechDescendants) do
    if descendant:IsA("Motor6D") then
        mechMotor6Ds[descendant.Name] = descendant
    end
end

local upperLeg = mechMotor6Ds["LUpperLeg"]
local knee = mechMotor6Ds["LKnee"]
local lowerLeg = mechMotor6Ds["LLowerLeg"]
local foot = mechMotor6Ds["LFeet"]

--[[
    Not necessary you can use the new functions to setup the table for you given that the model is setup
]]
local constraints = {
    [upperLeg] = {
        ["ConstraintType"] = "BallSocketConstraint";
        ["UpperAngle"] = 25;
        ["AxisAttachment"] = "LeftHip";--Searches for "LeftHipAxisAttachment" in the part0 of the motor
	};
	[lowerLeg] = {
        ["ConstraintType"] = "Hinge";
        ["UpperAngle"] = 45;
		["LowerAngle"] = -45;
    };
    [knee] = {
        ["ConstraintType"] = "Hinge";
        ["UpperAngle"] = 45;
		["LowerAngle"] = -45;
    };
}

local fullLeg = {upperLeg,knee,lowerLeg,foot}

local leftLegController = CCDIKController.new(fullLeg)
leftLegController:GetConstraints()

--Setting up the foot
local footParams = RaycastParams.new()
footParams.FilterDescendantsInstances = {mech}
local attachmentNames = {"A1","A2","A3"}
leftLegController:SetupFoot(attachmentNames,footParams)
-- leftLegController:InitTweenDragDebug()
RunService.Heartbeat:Connect(function(step)
    local goal = leftTarget.Position
    leftLegController:CCDIKIterateOnce(goal,nil,step)
end)
