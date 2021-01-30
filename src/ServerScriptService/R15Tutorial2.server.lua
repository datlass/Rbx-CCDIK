--[[
    R15 with constraints
]]
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CCDIKController = require(ReplicatedStorage.Source.CCDIKController)

local dummy = workspace.DummyWithConstraints
local leftTarget = workspace.newTargetConstraints

local dummyMotor6Ds = {}

local dummyDescendants = dummy:GetDescendants()
for _,descendant in pairs (dummyDescendants) do
    if descendant:IsA("Motor6D") then
        dummyMotor6Ds[descendant.Name] = descendant
    end
end

local upperLeg = dummyMotor6Ds["LeftHip"]
local knee = dummyMotor6Ds["LeftKnee"]
local foot = dummyMotor6Ds["LeftAnkle"]

local leftLeg = {upperLeg,knee,foot}

local leftLegController = CCDIKController.new(leftLeg)
leftLegController:GetConstraints()

RunService.Heartbeat:Connect(function()
    local goal = leftTarget.Position
    leftLegController:CCDIKIterateOnce(goal)
end)
