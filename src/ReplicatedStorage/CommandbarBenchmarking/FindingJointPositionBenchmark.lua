-- more benchmarking in the command bar


--Method 1 = 0.021 seconds CFrame math method
local part = Instance.new("Part")
part.CFrame = CFrame.new(1,5,100)*CFrame.fromOrientation(2,5,50)

local testMotor = Instance.new("Motor6D")
testMotor.C0 = CFrame.new(1,5,2)*CFrame.fromOrientation(1,5,3)
testMotor.Part0 = part

local startTime = os.clock()

local position

for i=1,10000 do
    position = (testMotor.Part0.CFrame*testMotor.C0).Position
end

local deltaTime = os.clock() - startTime
print("Elapsed time method 1: " .. deltaTime)

--Method2, = 0.00239 seconds attachment method, yep much faster to use attachments to find the joint worldPosition
local attachment = Instance.new("Attachment")
attachment.CFrame = CFrame.new(1,5,100)*CFrame.fromOrientation(2,5,50)
attachment.Parent = part

local startTime = os.clock()

local attachPosition

for i=1,10000 do
    attachPosition = attachment.WorldPosition
end

local deltaTime = os.clock() - startTime
print("Elapsed time method 2: " .. deltaTime)

return nothing