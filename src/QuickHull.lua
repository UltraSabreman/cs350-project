Quick = {}

Quick.finalHull = {} 			--stores the final hull lines
Quick.visitedPoints = {}		--stores all visited points
Quick.checkLines = {}			--stores all lines that make up the check triangles
Quick.excludedPoints = {}		--stores all points that are excluded, so we don't check them again
Quick.excludedCheckLines = {}	--this is used to make sure the triangle lines aren't drawn more then once.
Quick.startSplit = nil 			--stores the line that's used to make the first split.

function Quick.Draw()
	for _,p in pairs(points) do
		love.graphics.setColor(255,0,0,255)
		love.graphics.rectangle("fill", p.x-1, p.y-1, 3, 3)	
		if Quick.excludedPoints ~= nil and Quick.excludedPoints[tostring(p)] ~= nil then
			love.graphics.setColor(0,0,255,255)
			love.graphics.rectangle("fill", p.x-1, p.y-1, 3, 3)	
		end
	end

	--highlights visited points in green
	love.graphics.setColor(0,255,0,255)
	for _,p in pairs(Quick.visitedPoints) do
		love.graphics.rectangle("fill", p.x-1, p.y-1, 3, 3)	
	end

	--draws the final hull lines, highlights the points as they get computed
	for _,p in pairs(Quick.finalHull) do
		love.graphics.setColor(0,150,150,255)
		love.graphics.line(p[1].x, p[1].y, p[2].x, p[2].y)
		love.graphics.setColor(255,255,0,255)
		love.graphics.rectangle("fill", p[1].x-1, p[1].y-1, 3, 3)	
		love.graphics.rectangle("fill", p[2].x-1, p[2].y-1, 3, 3)	
	end

	--draw the trinagles as they are computed
	love.graphics.setColor(0,255,0,50)
	for _,p in pairs(Quick.checkLines) do
		love.graphics.line(p[1].x, p[1].y, p[2].x, p[2].y)
	end


	--draws the starting split
	if Quick.startSplit ~= nil then
		love.graphics.setColor(255,0,0,255)
		love.graphics.line(Quick.startSplit[1].x, Quick.startSplit[1].y, Quick.startSplit[2].x, Quick.startSplit[2].y)
	end
end

--Finds two points, one with the largest x coordinate, and one with the smallest
--used to make the first split.
function Quick.biggestXPoints(pointList)
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
function Quick.distanceToLine(line, point)
	BA = line[2] - line[1]
	AC = point - line[1]

	AB = line[1] - line[2]

	return math.abs(BA:cross(AC) / AB:len())
end

--Gets the third point for our triangle split.
--this point will be the one that's farthest away from the line
function Quick.getTriPoint(pointList, line)
	local longestDist
	local point

	for _,p in pairs(pointList) do
		if Quick.excludedPoints[tostring(p)] == nil then
			local dist = Quick.distanceToLine(line, p)
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
function Quick.pointsInTri(pointList, p0, p1, p2)
	local GoodPoints = {}
	local BadPoints = {}
	for _,p in pairs(pointList) do
		if Quick.excludedPoints[tostring(p)] == nil then
			A = 1/2 * (-p1.y * p2.x + p0.y * (-p1.x + p2.x) + p0.x * (p1.y - p2.y) + p1.x * p2.y)
			sign = -1
			if A >= 0 then
				sign = 1
			end
			s = (p0.y * p2.x - p0.x * p2.y + (p2.y - p0.y) * p.x + (p0.x - p2.x) * p.y) * sign
			t = (p0.x * p1.y - p0.y * p1.x + (p0.y - p1.y) * p.x + (p1.x - p0.x) * p.y) * sign

			if s > 0 and t > 0 and (s + t) < 2 * A * sign then
				BadPoints[#BadPoints + 1] = p --in triangle
				--this excludes any points found inside the triangle form further searches
				Quick.excludedPoints[tostring(p)] = 1
			else
				GoodPoints[#GoodPoints + 1] = p
			end
		end
	end
	return GoodPoints, BadPoints
end

--Used to find all the points that we will be sending to the next iteration of 
--the algorithim.
function Quick.getNewPoints(pointList, line, side)
	local newPoints = {}
	local badPoints = {}

	for _,p in pairs(pointList) do
		if Quick.excludedPoints[tostring(p)] == nil then
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

--wrapper function for the recursive one, inits all the appropriate stuff
function Quick.findHull() 
	--this table is needed because we can't pass a number by reference in lua
	--plus it helps wrap the direction nicely as well.
	local index = {}
	index[1] = 0

	--do the first split and exclude it's points from further search
	local startLine = Quick.biggestXPoints(points)
	Quick.startSplit = startLine
	Quick.excludedPoints[tostring(startLine[1])] = 1
	Quick.excludedPoints[tostring(startLine[2])] = 1

	--figure out which points need to be sent to which recursive call
	local above, below = Quick.getNewPoints(points, startLine, 1)

	index["side"] = 1
	Quick.recCompute(above, startLine, index)
	index["side"] = 2
	Quick.recCompute(below, startLine, index)

	coroutine.yield()
end


function Quick.recCompute(pointList, line, index)
	--Exclude the points on the line form future searches.
	Quick.excludedPoints[tostring(line[1])] = 1
	Quick.excludedPoints[tostring(line[2])] = 1

	--find the "peak" of the triangle
	local point = Quick.getTriPoint(pointList, line)
	
	--if there isn't one, we're on the hull right now.
	if point == nil then 
		Quick.finalHull[index[1]] = line
		index[1] = index[1] + 1
		coroutine.yield()
		return
	end
	--otherwise exlcude it as well
	Quick.excludedPoints[tostring(point)] = 1

	--find all the points NOT inside the triangle  we just made
	local good = Quick.pointsInTri(pointList, line[1], line[2], point)
	coroutine.yield()

	--if there are any,
	if #good ~= 0 then
		--figure out which points of need to be sent to which recursive call
		local above, below
		if index["side"] == 1 then
			above, below = Quick.getNewPoints(good, {line[1], point}, 1)
		else
			above, below = Quick.getNewPoints(good, {line[1], point}, 2)
		end

		--this next block jsut ensures that the lines representing the triangles
		--aren't drawn more than once.
		coroutine.yield()
		Quick.visitedPoints[#Quick.visitedPoints + 1] = point
		if Quick.excludedCheckLines[tostring(line[1]).."|"..tostring(line[2])] == nil then
			Quick.checkLines[#Quick.checkLines + 1] = line
			Quick.excludedCheckLines[tostring(line[1]).."|"..tostring(line[2])] = 1
		end
		if Quick.excludedCheckLines[tostring(line[1]).."|"..tostring(point)] == nil then
			Quick.checkLines[#Quick.checkLines + 1] = {line[1], point}
			Quick.excludedCheckLines[tostring(line[1]).."|"..tostring(point)] = 1
		end
		if Quick.excludedCheckLines[tostring(point).."|"..tostring(line[2])] == nil then
			Quick.checkLines[#Quick.checkLines + 1] = {point, line[2]}
			Quick.excludedCheckLines[tostring(point).."|"..tostring(line[2])] = 1
		end

		--recurse to the two new sides of the triangle
		coroutine.yield()
		Quick.recCompute(above, {line[1], point}, index)
		Quick.recCompute(below, {point, line[2]}, index)
	else
		--if there aren't any points outside fo teh triangle, that means the
		--two sides of it make up the hull.
		Quick.finalHull[index[1]] = {line[1], point}
		Quick.finalHull[index[1] + 1] = {point, line[2]}
		index[1] = index[1] + 2
		coroutine.yield()
	end

end