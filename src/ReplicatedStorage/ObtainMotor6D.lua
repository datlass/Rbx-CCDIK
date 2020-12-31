-- spare code used to benchmark obtaining a dictionary of named Motor6D values
--Yeah using predefined instance values with less to loop through is much faster

for i =1,1000 do
    local test = Instance.new("ObjectValue")
    test.Parent = mech
end
--[[--------------------------------------------------------
    Method 2 : 0.137 seconds
    method 1: 0.06 seconds
    makes sense loop through less
    with 1000+ more instances it becomes
    Method 2: 1.8 seconds
    Method 1: 0.07 seconds
]]

local startTime = os.clock()

for i=1,10000 do
    local Motor6DValues = mech.Motor6DValues:GetChildren()
    local ModelMotor6Ds = {}
    for i,v in pairs (Motor6DValues) do
        ModelMotor6Ds[v.Name] = v.Value
    end
end

local deltaTime = os.clock() - startTime
print("Elapsed time method 1: " .. deltaTime)


local startTime = os.clock()

for i=1,10000 do
    local descendants = mech:GetDescendants()
    local ModelMotor6Ds = {}
    for i,v in pairs (descendants) do
        if v:IsA("Motor6D") then
            ModelMotor6Ds[v.Name] = v
        end
    end
end


local deltaTime = os.clock() - startTime
print("Elapsed time method 2: " .. deltaTime)

return nothing