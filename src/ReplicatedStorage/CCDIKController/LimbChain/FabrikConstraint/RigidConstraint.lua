

-- Initialize Object Class
local Package = script:FindFirstAncestor("LimbChain")
local Object = require(Package.BaseRedirect)

--Require the FabrikConstraint for Inheritance
local FabrikConstraintPointer = script:FindFirstAncestor("FabrikConstraint")
local FabrikConstraint = require(FabrikConstraintPointer)

--Initialize the Self Class
local RigidConstraint = Object.newExtends("RigidConstraint",FabrikConstraint)

--[[--------------------------------------------------------
    Create the constraint
    Parameters:
]]
function RigidConstraint.new(PartOrLimbChain)
    local obj

    --[[
        Detects if parameter 1 is a limb chain object, if it is then it constraints to the original limb position
        
    ]]
    if  not PartOrLimbChain:isA("LimbChain") then
    
    obj = RigidConstraint:super(PartOrLimbChain)

    else
        
    obj = RigidConstraint:super()
   
    obj.LimbChain = PartOrLimbChain

    end
    
	return obj
end

--[[
    Constraints the limbVector like a rigid joint
    It doesn't move and the joint points in the part's current direction
    or it points in the motor6ds original direction
    returns a new limbvector vector 3 at full length
]]
function RigidConstraint:ConstrainLimbVector(currentVectorInformation)
    
    local jointPosition = currentVectorInformation.JointPosition
    local limbVector = currentVectorInformation.LimbVector
    local limbLength = currentVectorInformation.LimbLength
    local index = currentVectorInformation.Index

    --Checks if there is a part to set the constraint axis to
    if self.Part ~=nil then

        --Get the constraining part current axis
        self:UpdateAxis()

        --Make it point in the part's center axis
        return self.CenterAxis.Unit*limbLength

    else
        --offset to prevent nan or 0,0,0
        local minorOffset = Vector3.new(0.01,0.01,0.01)
        --Else get the original limbvector
        return (self.LimbChain:GetOriginalLimbDirection(index).Unit+minorOffset)*limbLength

    end
end


return RigidConstraint