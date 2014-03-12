Quick = {}

Quick.finalHull = {} 			--stores the final hull lines
Quick.visitedPoints = {}		--stores all visited points
Quick.checkLines = {}			--stores all lines that make up the check triangles
Quick.excludedPoints = {}		--stores all points that are excluded, so we don't check them again
Quick.excludedCheckLines = {}	--this is used to make sure the triangle lines aren't drawn more then once.
Quick.startSplit = nil 			--stores the line that's used to make the first split.
Quick.canvas = nil 				--framebufer
Quick.points = {}
Quick.num = -1
Quick.__index = Quick


function Quick.new(ps, num)
	local self = setmetatable({}, Quick)
	self.canvas = love.graphics.newCanvas(width/2, height)  
	self.finalHull = {}
	self.visitedPoints = {}
	self.checkLines = {}
	self.excludedPoints = {}
	self.excludedCheckLines = {}
	self.startSplit = nil
	self.num = num
	self.points = ps	
	return self
end

function Quick:Reset()
	self.canvas = love.graphics.newCanvas(width/2, height)  
	self.finalHull = {}
	self.visitedPoints = {}
	self.checkLines = {}
	self.excludedPoints = {}
	self.excludedCheckLines = {}
	self.startSplit = nil
end

function Quick:ClearAll()
	self.canvas = nil
	self.finalHull = nil
	self.visitedPoints = nil
	self.checkLines = nil
	self.excludedPoints = nil
	self.excludedCheckLines = nil
	self.startSplit = nil
	self.num = nil
	self.points = nil
end


function Quick:Draw()
	if self.canvas == nil then return end
	love.graphics.setCanvas(self.canvas)
        self.canvas:clear()
        --love.graphics.setBlendMode('alpha')

		for _,p in pairs(points) do
			love.graphics.setColor(255,0,0,255)
			love.graphics.rectangle("fill", p.x-1, p.y-1, 3, 3)	
			if self.excludedPoints ~= nil and self.excludedPoints[tostring(p)] ~= nil then
				love.graphics.setColor(0,0,255,255)
				love.graphics.rectangle("fill", p.x-1, p.y-1, 3, 3)	
			end
		end

		--highlights visited points in green
		love.graphics.setColor(0,255,0,255)
		for _,p in pairs(self.visitedPoints) do
			love.graphics.rectangle("fill", p.x-1, p.y-1, 3, 3)	
		end

		--draws the final hull lines, highlights the points as they get computed
		for _,p in pairs(self.finalHull) do
			love.graphics.setColor(0,150,150,255)
			love.graphics.line(p[1].x, p[1].y, p[2].x, p[2].y)
			love.graphics.setColor(255,255,0,255)
			love.graphics.rectangle("fill", p[1].x-1, p[1].y-1, 3, 3)	
			love.graphics.rectangle("fill", p[2].x-1, p[2].y-1, 3, 3)	
		end

		--draw the trinagles as they are computed
		love.graphics.setColor(0,255,0,50)
		for _,p in pairs(self.checkLines) do
			love.graphics.line(p[1].x, p[1].y, p[2].x, p[2].y)
		end


		--draws the starting split
		if self.startSplit ~= nil then
			love.graphics.setColor(255,0,0,255)
			love.graphics.line(self.startSplit[1].x, self.startSplit[1].y, self.startSplit[2].x, self.startSplit[2].y)
		end
	love.graphics.setCanvas()
end

--Finds two points, one with the largest x coordinate, and one with the smallest
--used to make the first split.
function Quick:biggestXPoints(pointList)
	local goodPoints = {}

	for _,p in pairs(pointList) do
		if goodPoints[1] == nil or p.x < goodPoints[1].x then
			goodPoints[1] = p
		end
		if goodPoints[2] == nil or p.x > goodPoints[2].x then
			goodPoints[2] = p
		end
	end

	return goodPoints
end

--Computes the distance between a point and a line
function Quick:distanceToLine(line, point)
	BA = line[2] - line[1]
	AC = point - line[1]

	AB = line[1] - line[2]

	return math.abs(BA:cross(AC) / AB:len())
end

--Gets the third point for our triangle split.
--this point will be the one that's farthest away from the line
function Quick:getTriPoint(pointList, line)
	local longestDist
	local point

	for _,p in pairs(pointList) do
		if self.excludedPoints[tostring(p)] == nil then
			local dist = self:distanceToLine(line, p)
			if longestDist == nill or dist > longestDist then
				longestDist = dist
				point = p
			end
		end
	end
	return point
end

--[[Finds all the points inside a triangle. Used to determine which points
	need to be ignored.

	The idea behind the math is simple, you take a corssproduct of a trinagle side, and
	the vector form one point on that side to the point. If the resulting vector points
	into the screen, the point is in the triangle, otherwise it's outside.

	Since I didn't want to adapt my vector class to work in 3d (since this is the only place
	that would be needed) I pulled this "simplified" function from stackoverflow, that does 
	the same thing but uses barycentric coordinates instead. The math is messy, and so are the names
	but it works.

	Source: http://stackoverflow.com/questions/2049582/how-to-determine-a-point-in-a-triangle ]]
function Quick:pointsInTri(pointList, p0, p1, p2)
	local GoodPoints = {}
	local BadPoints = {}
	for _,p in pairs(pointList) do
		if self.excludedPoints[tostring(p)] == nil then
			A = 1/2 * (-p1.y * p2.x + p0.y * (-p1.x + p2.x) + p0.x * (p1.y - p2.y) + p1.x * p2.y)
			sign = -1
			if A >= 0 then
				sign = 1
			end
			s = (p0.y * p2.x - p0.x * p2.y + (p2.y - p0.y) * p.x + (p0.x - p2.x) * p.y) * sign
			t = (p0.x * p1.y - p0.y * p1.x + (p0.y - p1.y) * p.x + (p1.x - p0.x) * p.y) * sign

			if (s > 0 and t > 0 and (s + t) < 2 * A * sign) or self:pointOnTriSide(p0, p1, p2, p) then
				BadPoints[#BadPoints + 1] = p --in triangle
				--this excludes any points found inside the triangle form further searches
				self.excludedPoints[tostring(p)] = 1
			else
				GoodPoints[#GoodPoints + 1] = p
			end
		end
	end
	return GoodPoints, BadPoints
end

--Checks is the point is directly ON the one of the sides of the triangle.
--Since we have already determined this point to not be the farthest from the line, that means it's safe
--to discard it, if it lies on the same line.
function Quick:pointOnTriSide(p0, p1, p2, point)
	if relativeToLine(p0, p1, point) == 0 or relativeToLine(p0, p2, point) == 0 or relativeToLine(p1, p2, point) == 0 then
		return true
	else return false end
end

--Used to find all the points that we will be sending to the next iteration of 
--the algorithim.
function Quick:getNewPoints(pointList, line, side)
	local newPoints = {}
	local badPoints = {}

	for _,p in pairs(pointList) do
		if self.excludedPoints[tostring(p)] == nil then
			local check = relativeToLine(line[1], line[2], p)
			if  (side == 1  and check < 0) or (side == 2 and check > 0) then
				newPoints[#newPoints + 1] = p
			else
				badPoints[#badPoints + 1] = p
			end
		end
	end

	return newPoints, badPoints
end

function Quick:doTiming()
	local starttimes = {}
	local endtimes = {}

	--do 4 timing runs
	for l = 1, 4 do
		self:Reset()
		starttimes[#starttimes + 1] = socket.gettime()

		self:findHull()
		endtimes[#endtimes + 1] = socket.gettime() - starttimes[#starttimes]
	end

	--avarage times
	local avgQuickTime = 0
	for _,l in pairs(endtimes) do
		avgQuickTime = avgQuickTime + l
	end
	avgQuickTime = avgQuickTime / #endtimes

	print("Quick@"..tostring(self.num)..": "..tostring(avgQuickTime))
	self:ClearAll()
end

function Quick:findHull() 
	--do the first split and exclude it's points from further search
	local startLine = self:biggestXPoints(self.points)

	self.excludedPoints[tostring(startLine[1])] = 1
	self.excludedPoints[tostring(startLine[2])] = 1

	--figure out which points need to be sent to which recursive call
	local above, below = self:getNewPoints(self.points, startLine, 1)

	self:recCompute(above, startLine, 1)
	self:recCompute(below, startLine, 2)
end


function Quick:recCompute(pointList, line, side)
	--Exclude the points on the line form future searches.
	self.excludedPoints[tostring(line[1])] = 1
	self.excludedPoints[tostring(line[2])] = 1

	--find the "peak" of the triangle
	local point = self:getTriPoint(pointList, line)

	--if there isn't one, we're on the hull right now.
	if point == nil then 
		self.finalHull[#self.finalHull + 1] = line
		return
	end

	--this next block just ensures that the lines representing the triangles
	--aren't drawn more than once.
	if self.excludedCheckLines[tostring(line[1]).."|"..tostring(line[2])] == nil then
		self.excludedCheckLines[tostring(line[1]).."|"..tostring(line[2])] = 1
	end
	if self.excludedCheckLines[tostring(line[1]).."|"..tostring(point)] == nil then
		self.excludedCheckLines[tostring(line[1]).."|"..tostring(point)] = 1
	end
	if self.excludedCheckLines[tostring(point).."|"..tostring(line[2])] == nil then
		self.excludedCheckLines[tostring(point).."|"..tostring(line[2])] = 1
	end

	--otherwise exlcude it as well
	self.excludedPoints[tostring(point)] = 1
	--find all the points NOT inside the triangle  we just made
	local good = self:pointsInTri(pointList, line[1], line[2], point)

	--if there are any,
	if #good ~= 0 then
		--figure out which points of need to be sent to which recursive call
		local above, below = self:getNewPoints(good, {line[1], point}, side)

		self:recCompute(above, {line[1], point}, index)
		self:recCompute(below, {point, line[2]}, index)
	else
		--if there aren't any points outside fo teh triangle, that means the
		--two sides of it make up the hull.
		self.finalHull[#self.finalHull + 1] = {line[1], point}
		self.finalHull[#self.finalHull + 1] = {point, line[2]}
	end
end