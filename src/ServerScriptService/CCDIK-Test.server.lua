--Testing with my mech model

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IKController = require(ReplicatedStorage.Source.IKController)

local mech = workspace.LowerBody
local leftTarget = workspace.MechLTarget

local modelMotor6Ds = {}

local modelDescendants = mech:GetDescendants()
for _,descendant in pairs (modelDescendants) do
    if descendant:IsA("Motor6D") then
        modelMotor6Ds[descendant.Name] = descendant
    end
end

--[[
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

local bottomLeg = {lowerLeg,foot}
local halfLeg = {knee,lowerLeg,foot}
local fullLeg = {upperLeg,knee,lowerLeg,foot}

local leftLegController = IKController.new(fullLeg)

local run = true
while run do
    local goal = leftTarget.Position
    leftLegController:CCDIKIterateOnce(goal)
    wait()
end

--[[
RunService.Heartbeat:Connect(function()
    local goal = leftTarget.Position
    leftLegController:CCDIKIterateOnce(goal)
end)
]]