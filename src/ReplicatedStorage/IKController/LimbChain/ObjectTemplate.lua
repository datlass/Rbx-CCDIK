-- Initialize Object Class
local Package = script:FindFirstAncestorOfClass("Folder")
local Object = require(Package.BaseRedirect)

local NAME = Object.new("NAME")
--local NAME = Object.newExtends("NAME",?)

function NAME.new()
	local obj = NAME:make()
	--local obj = NAME:super()
	
	return obj
end

return NAME