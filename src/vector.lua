Vector = {}
Vector.x = 0
Vector.y = 0
Vector.__index = Vector

function Vector:len()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector:normalized()
	local len = self:len()
	return Vector.new(self.x / len, self.y / len)
end

function Vector:normalize()
	local len = self:len()
	self.x = self.x / len
	self.y = self.y / len
end

function Vector:dot(vec)
	return self.x * vec.x + self.y * vec.y
end

function Vector:cross(vec)
	return self.x * vec.y - self.y * vec.x
end

function Vector:getAngle(vec)
	return math.cos(self:dot(vec) / (self:len() * vec:len()))
end

function Vector:inverted()
	return Vector.new(self.y, self.x)
end

function Vector:print()
	print(tostring(self))
end




function Vector.new(x, y)
  local self = setmetatable({}, Vector)
  self.x = x
  self.y = y
  return self
end

function Vector.__tostring(vec)
	return "("..tostring(vec.x)..", "..tostring(vec.y)..")"
end

function Vector.__add(vec1, vec2)
	return Vector.new(vec1.x + vec2.x, vec1.y + vec2.y)
end

function Vector.__sub(vec1, vec2)
	return Vector.new(vec1.x - vec2.x, vec1.y - vec2.y)
end

function Vector.__mul(vec1, vec2)
	if type(vec1) == "vector" and type(vec2) == "vector" then
		return Vector.new(vec1.x * vec2.x, vec1.y * vec2.y)
	elseif type(vec1) == "vector" and type(vec2) == "number" then
		return Vector.new(vec1.x * vec2, vec1.y * vec2)
	elseif type(vec1) == "number" and type(vec2) == "vector" then
		return Vector.new(vec1 * vec2.x, vec1 * vec2.y)
	end
end

function Vector.__len(vec1)
	return vec1:len()
end

function Vector.__eq(vec1, vec2)
	return (vec1.x == vec2.x and vec1.y == vec2.y)
end



--this is stupid, but it's the only way to get types to work
--we need to redefine the actual type function.
local original_type = type 

type = function( obj )
    local otype = original_type( obj )
    if  otype == "table" and getmetatable( obj ) == Vector then
        return "vector"
    end
    return otype
end