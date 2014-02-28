Quick = {}

Quick.finalHull = {}
Quick.visitedPoints = {}
Quick.checkLines = {}
Quick.excludedPoints = {}
Quick.curLine = nil
Quick.test = false

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
		--if p[1] ~= nil and p[2] ~= nil then
			love.graphics.line(p[1].x, p[1].y, p[2].x, p[2].y)
		--end
		love.graphics.setColor(255,255,0,255)
		love.graphics.rectangle("fill", p[1].x-1, p[1].y-1, 3, 3)	
		--if p[2] ~= nill then
			love.graphics.rectangle("fill", p[2].x-1, p[2].y-1, 3, 3)	
		--end
	end

	love.graphics.setColor(0,255,0,50)
	for _,p in pairs(Quick.checkLines) do
		love.graphics.line(p[1].x, p[1].y, p[2].x, p[2].y)
	end


	--draws the current comparrison line
	if Quick.curLine ~= nil then
		love.graphics.setColor(255,0,0,255)
		love.graphics.line(Quick.curLine[1].x, Quick.curLine[1].y, Quick.curLine[2].x, Quick.curLine[2].y)
	end

	if Quick.test then
		love.graphics.setColor(255,150,0,255)
		love.graphics.circle("fill", 0, 0, 50, 30)
	end
end

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

function Quick.distanceToLine(line, point)
	BA = line[2] - line[1]
	AC = point - line[1]

	AB = line[1] - line[2]

	return math.abs(BA:cross(AC) / AB:len())
end

function Quick.getTriPoint(pointList, line)
	local longestDist
	local point

	for _,p in pairs(pointList) do
		if Quick.excludedPoints[tostring(p)] == nil then
			local check = relativeToLine(line[1], line[2], p)
			local dist = Quick.distanceToLine(line, p)
			if longestDist == nill or dist > longestDist then
				longestDist = dist
				point = p
			end
		end
	end
	return point
end

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
				Quick.excludedPoints[tostring(p)] = 1
			else
				GoodPoints[#GoodPoints + 1] = p
			end
		end
	end
	return GoodPoints, BadPoints
end

function Quick.getNewPoints(pointList, line, side)
	local newPoints = {}
	local badPoints = {}

	local i = 0
	local l = 0
	for _,p in pairs(pointList) do
		if Quick.excludedPoints[tostring(p)] == nil then
			local check = relativeToLine(line[1], line[2], p)
			if  (side == 1  and check < 0) or (side == 2 and check > 0) then
				newPoints[i] = p
				i = i + 1
			else
				--Quick.excludedPoints[tostring(p)] = 1
				badPoints[l] = p
				l = l + 1
			end
		end
	end

	return newPoints, badPoints
end

function Quick.findHull() 
	local index = {}
	index[1] = 0

	local startLine = Quick.biggestXPoints(points)
	Quick.curLine = startLine
	Quick.excludedPoints[tostring(startLine[1])] = 1
	Quick.excludedPoints[tostring(startLine[2])] = 1

	local above, below = Quick.getNewPoints(points, startLine, 1)

	index["side"] = 1
	Quick.recCompute(above, startLine, index)
	index["side"] = 2
	Quick.recCompute(below, {startLine[2], startLine[1]}, index)

	coroutine.yield()
	Quick.test = true
end


--index needs to be a table, otherwise it's not passed by reference.
function Quick.recCompute(pointList, line, index)
	Quick.excludedPoints[tostring(line[1])] = 1
	Quick.excludedPoints[tostring(line[2])] = 1

	local point = Quick.getTriPoint(pointList, line)
	if point == nil then 
		Quick.finalHull[index[1]] = line
		index[1] = index[1] + 1
		coroutine.yield()
		return
	end
	Quick.excludedPoints[tostring(point)] = 1

	local good = Quick.pointsInTri(pointList, line[1], line[2], point)
			sleep(0.5)
		coroutine.yield()
	if #good ~= 0 then
		local above, below
		if point.y < line[1].y then
			above, below = Quick.getNewPoints(good, {line[1], point}, 1)
		else
			above, below = Quick.getNewPoints(good, {line[1], point}, 2)
		end
		sleep(0.5)
		coroutine.yield()
		--Quick.visitedPoints[#Quick.visitedPoints + 1] = point
		Quick.checkLines[#Quick.checkLines + 1] = line
		Quick.checkLines[#Quick.checkLines + 1] = {line[1], point}
		Quick.checkLines[#Quick.checkLines + 1] = {point, line[2]}

		sleep(0.5)
		coroutine.yield()
		
		if index["side"] == 1 then
			Quick.recCompute(above, {line[1], point}, index)
			Quick.recCompute(below, {point, line[2]}, index)
		else
			Quick.recCompute(below, {line[1], point}, index)
			Quick.recCompute(above, {point, line[2]}, index)
		end
	else
		--sleep(1.5)
		Quick.finalHull[index[1]] = {line[1], point}
		Quick.finalHull[index[1] + 1] = {point, line[2]}
		index[1] = index[1] + 2
				sleep(0.5)
		coroutine.yield()
	end

end