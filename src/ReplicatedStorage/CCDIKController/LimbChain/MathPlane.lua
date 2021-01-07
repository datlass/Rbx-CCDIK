-- Initialize Object Class
local Package = script:FindFirstAncestor("LimbChain")
local Object = require(Package.BaseRedirect)

local MathPlane = Object.new("MathPlane")

--Squared Distance
local function SquaredDistance(Vector)

    return Vector.X^2 + Vector.Y^2 + Vector.Z^2

end


function MathPlane.new(NormalVector,PlanePoint)
	local obj = MathPlane:make()

    --Stores the inputted NormalVector
    obj.NormalVector = NormalVector

    --Stores the point on the plane
    obj.PlanePoint = PlanePoint

    --Obtains the scalar dot product of the plane
    obj.PlaneScalar = PlanePoint:Dot(NormalVector)

	return obj
end

--[[
    Finds the closest point from a point to plane
    Returns a vector 3 point in world space
]]
function MathPlane:FindClosestPointOnPlane(PointOnLine)

    --Create a new line with direction of the plane normal and located at the InputPoint 
    --lamda is the scalar of the line direction vector
    local lambda = (self.PlanePoint - PointOnLine):Dot(self.NormalVector) /  SquaredDistance(self.NormalVector)

    return PointOnLine + lambda*self.NormalVector

end

--[[
    Checks if a vector3 point is on the plane object
    Currently working fine
]]
function MathPlane:IsPointOnPlane(PositionVector)

    local PositionScalar = PositionVector:Dot(self.NormalVector)

    if PositionScalar == self.PlaneScalar then
        return true
    else
        return false
    end

end

return MathPlane