--[[
    Testing with R15 Dummy, works too :O
]]
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IKController = require(ReplicatedStorage.Source.IKController)

local mech = workspace.Dummy
local leftTarget = workspace.newTarget

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

local upperLeg = mechMotor6Ds["LeftHip"]
local knee = mechMotor6Ds["LeftKnee"]
local foot = mechMotor6Ds["LeftAnkle"]

local fullLeg = {upperLeg,knee,foot}

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