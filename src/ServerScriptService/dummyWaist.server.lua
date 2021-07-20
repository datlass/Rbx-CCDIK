--[[
    Testing with R15 Dummy for the waist
]]
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CCDIKController = require(ReplicatedStorage.Source.CCDIKController)

local dummy = workspace.DummyWaist
local leftTarget = workspace.SomeTarget

local dummyMotor6Ds = {}

local dummyDescendants = dummy:GetDescendants()
for _,descendant in pairs (dummyDescendants) do
    if descendant:IsA("Motor6D") then
        dummyMotor6Ds[descendant.Name] = descendant
    end
end

local root = dummyMotor6Ds["Root"]
local neck = dummyMotor6Ds["Neck"]
local waist = dummyMotor6Ds["Waist"]

local leftLeg = {waist,neck}

local leftLegController = CCDIKController.new(leftLeg)
leftLegController.UseLastMotor = true --only if one motor6D in the table

RunService.Heartbeat:Connect(function()
    local goal = leftTarget.Position
    leftLegController:CCDIKIterateOnce(goal)
end)
