--[[

This is the FabrikConstraint object which you insert into the table to do the math

API:

Constructors:
	BallSocketConstraint.new(BasePart part, Number AngleOfWidth, Number AngleOfHeight)
        > Creates the inverse kinematics constraint based on the parts axis
        > also the numbers are in degrees
        
Methods:

	BallSocketConstraint:ConstrainLimbVector(currentVectorInformation)
        > Gets a limb vector and return a new constrainted limb vector
        > Primarily used by the fabrik solver to constrain

Properties:
    >Not meant to be manipulated
	BallSocketConstraint.AngleOfWidth
        > Number in radians
        > angleOfElevation is between the parts look vector and the parts Rightvector vector
        > 

    BallSocketConstraint.AngleOfHeight
        > Number in radians
        > angleOfDepression is between the parts look vector the parts up vector

Enjoy!
- dthecoolest

--]]

-- Initialize Object Class
local Package = script:FindFirstAncestor("LimbChain")
local Object = require(Package.BaseRedirect)

--Require the FabrikConstraint for Inheritance
local FabrikConstraintPointer = script:FindFirstAncestor("FabrikConstraint")
local FabrikConstraint = require(FabrikConstraintPointer)

--Initialize the Self Class
local BallSocketConstraint = Object.newExtends("BallSocketConstraint",FabrikConstraint)

--[[--------------------------------------------------------
    Create the constraint
    Parameters:
]]
function BallSocketConstraint.new(Part,AngleOfWidth,AngleOfHeight)
        
    local obj = BallSocketConstraint:super(Part)
   
    obj.AngleOfHeight = math.rad(AngleOfHeight)
    
    obj.AngleOfWidth = math.rad(AngleOfWidth)
    
	return obj
end

--[[
    Constraints the limbVector like a ball socket joint

]]
function BallSocketConstraint:ConstrainLimbVector(currentVectorInformation)
    
    local jointPosition = currentVectorInformation.JointPosition
    local limbVector = currentVectorInformation.LimbVector
    local limbLength = currentVectorInformation.LimbLength

        --Get the parts current CFrame
        --Big problem as its relative to the part attached to the motor
        self:UpdateAxis(jointPosition)

        --debug visualize the ball socket constraint rang
        if self.Cone then
            local yHeight = 2*limbLength*math.sin(self.AngleOfHeight)
            local xHeight = 2*limbLength*math.sin(self.AngleOfWidth)
            local length = limbLength * math.cos(self.AngleOfWidth)
            self.Cone.Size = Vector3.new(xHeight,length,yHeight)
            self.Cone.CFrame = CFrame.fromMatrix(jointPosition,self.XAxis,-self.CenterAxis,self.YAxis)*CFrame.new(0,-length/2,0)
        end


        --Get the Axis
        local centerAxis = self.CenterAxis.Unit
        local yAxis = self.YAxis.Unit
        local xAxis = self.XAxis.Unit

        -- ellipse width and height of the constraint
        local heightCenterAngle = self.AngleOfHeight
        local widthCenterAngle = self.AngleOfWidth
    
        -- Convert Angles into height and width
        -- Height and width are in terms of radius height from origin
        local height = limbLength * math.sin(heightCenterAngle)
        local width = limbLength * math.sin(widthCenterAngle)
    
        -- Perform vector resolution on limbvector
        -- Represents the center of the 2d plane that will be constructed
        -- Also gets the projection scalar which needs to be clamped or else the conicalConstraint fails
        local projScalar = limbVector:Dot(centerAxis) * (1 / centerAxis.Magnitude)
    
        local isOppositeDirection = false

        --Detects the direction of the projection and adjust bool accordingly
        if projScalar < 0 then 
            isOppositeDirection = true
        end
    
        projScalar = math.abs(projScalar)
    
        local minScalar = limbLength * math.cos(widthCenterAngle)
        projScalar = math.clamp(projScalar, minScalar, limbLength)
    
        -- Always make projection scalar positive so that the projCenter faces the center Axis
        local projCenter = projScalar * centerAxis.Unit
    
        -- position the current limbvector within the 2d plane as another vector
        local posVector = limbVector - projCenter
    
        -- translate into 2d plane
    
        -- Construct the oval
        -- Get the X and Y Coordinates
        local yPoint = yAxis:Dot(posVector) / (yAxis.Magnitude)
        local xPoint = xAxis:Dot(posVector) / (xAxis.Magnitude)
    
        -- Construct the oval constrain formula
        local ovalFormula = (xPoint ^ 2) / (width ^ 2) + (yPoint ^ 2) / (height ^ 2)
    
        -- check if the limbvector point is outside the formula constraint
        -- Also checks for directionality if its in the isOppositeDirection then constraint
        if ovalFormula >= 1 or isOppositeDirection then
            -- Obtain the angle from the xaxis
            local angleToXAxis = math.atan2(yPoint, xPoint)
    
            -- Place it on the edge of the oval within the contraints placed
            local newXPoint = width * math.cos(angleToXAxis)
            local newYPoint = height * math.sin(angleToXAxis)
    
            -- now reconstruct the limbVector
            -- Now we convert it back to a 3d vector
            local newMagnitude = math.sqrt(newXPoint ^ 2 + newYPoint ^ 2)
    
            -- Gets the new direction of the v2 limb
            local newPosVector = posVector.Unit * newMagnitude
    
            local newDir = projCenter + newPosVector
            -- Constructs the new limbvector in a different direction but same length
            limbVector = newDir.Unit * limbVector.Magnitude
        end
    
        return limbVector

end


return BallSocketConstraint