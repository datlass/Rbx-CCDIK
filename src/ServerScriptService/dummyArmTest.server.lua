--[[
    Testing with R15 Dummy
]]
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CCDIKController = require(ReplicatedStorage.Source.CCDIKController)

local dummy = workspace.DummyR6
local leftTarget = workspace.armTarget

local dummyMotor6Ds = {}

local dummyDescendants = dummy:GetDescendants()
for _,descendant in pairs (dummyDescendants) do
    if descendant:IsA("Motor6D") then
        dummyMotor6Ds[descendant.Name] = descendant
    end
end
local root = dummyMotor6Ds["Root Hip"]

local upperArm = dummyMotor6Ds["Right Shoulder"]
local part = Instance.new("Part")
part.CFrame = upperArm.C0
part.Name = "VisualizeC0"
part.Parent =workspace

local function cframeToOrientationInDegrees(cframeInput)
    local x,y,z = cframeInput:ToOrientation()
    return math.deg(x),math.deg(y),math.deg(z)
end
print("Motor6D for R6 is wack check it out:")
print("C0: ",cframeToOrientationInDegrees(upperArm.C0))
print("C1: ",cframeToOrientationInDegrees(upperArm.C1))
--upperArm.C0 = CFrame.new()+upperArm.C0.Position -- issue Motor6D C0 is rotated 90 degrees
--upperArm.C1 = CFrame.new()+upperArm.C1.Position -- and Motor6D C1 is rotated 90 degrees

local arm = {upperArm}
local armController = CCDIKController.new(arm)
armController.UseLastMotor = true --only if one motor6D in the table
--armController.DebugMode = true -- turns on laser visualization, change wait() to wait(1) if you turn this on or else lasers don't get cleaned up
print("After reset by CCDIK Constructor")
print("C0: ",cframeToOrientationInDegrees(upperArm.C0))
print("C1: ",cframeToOrientationInDegrees(upperArm.C1))

while true do
    wait()
    local goal = leftTarget.Position
    armController:CCDIKIterateOnce(goal)
end
