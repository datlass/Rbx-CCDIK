--Testing with my mech model
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CCDIKController = require(ReplicatedStorage.Source.CCDIKController)

local mech = workspace.LowerBody
local leftTarget = workspace.MechLTarget

--[[
    --Motor6D Object value method, eh works but I'm lazy to setup :P
local Motor6DValues = mech.Motor6DValues:GetChildren()
for i,v in pairs (Motor6DValues) do
    mechMotor6Ds[v.Name] = v.Value
end
]]

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

local leftLegController = CCDIKController.new(fullLeg,constraints)

RunService.Heartbeat:Connect(function()
    local goal = leftTarget.Position
    leftLegController:CCDIKIterateOnce(goal)
end)
