--Get service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--Modules required
local IKControllerPointer = ReplicatedStorage.Source.LimbChain
local LimbChain = require(IKControllerPointer)

--Left leg chain motors
local tripod = workspace.Tripod

local modelMotor6Ds = {}

local modelDescendants = tripod:GetDescendants()
for _,descendant in pairs (modelDescendants) do
    if descendant:IsA("Motor6D") then
        modelMotor6Ds[descendant.Name] = descendant
    end
end
--now you can index the Motor 6d's by name through the dictionary obtained
--Get the motors of the left leg chain
local lUpperLegMotor = modelMotor6Ds["LUpperLeg"]
local lLowerLegMotor = modelMotor6Ds["LLowerLeg"]
local lfoot = modelMotor6Ds["LFeet"]

--Get the motors of the right leg chain
local rUpperLegMotor = modelMotor6Ds["RUpperLeg"]
local rLowerLegMotor = modelMotor6Ds["RLowerLeg"]
local rfoot = modelMotor6Ds["RFeet"]

--Get the motors of the back leg chain
local bUpperLegMotor = modelMotor6Ds["BUpperLeg"]
local bLowerLegMotor = modelMotor6Ds["BLowerLeg"]
local bfoot = modelMotor6Ds["BFeet"]

--Create the left leg chain
local leftLegMotorTable = {lUpperLegMotor,lLowerLegMotor,lfoot}
local leftLegChain = LimbChain.new(leftLegMotorTable)

--create the right leg chain
local rightLegMotorTable = {rUpperLegMotor,rLowerLegMotor,rfoot}
local rightLegChain = LimbChain.new(rightLegMotorTable)

--Create the back leg chain
local backLegMotorTable = {bUpperLegMotor,bLowerLegMotor,bfoot}
local backLegChain = LimbChain.new(backLegMotorTable)


RunService.Heartbeat:Connect(function()
   
    local leftTarget = workspace.BigLTarget.Position
    local rightTarget = workspace.BigRTarget.Position
    local backTarget = workspace.BigBTarget.Postition

    leftLegChain:IterateOnce(leftTarget,0.1)
    leftLegChain:UpdateMotors()
	
	backLegChain:IterateOnce(backTarget,0.1)
	backLegChain:UpdateMotors()

    rightLegChain:IterateOnce(rightTarget,0.1)
    rightLegChain:UpdateMotors()

end)


return no
