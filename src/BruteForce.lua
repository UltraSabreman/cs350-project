Brute = {}
--[[Somewhat optimized brute-force algorithim for finding convex hull
	Optimizations:	
		+ Storing hull lines and checking for their exhistance prior to computing
		+ Skipping identical points]]

Brute.checkTable = {} 		--Used to check if the current set of points has already been calcualted.
Brute.finalHull = {}		--Stores the lines that make up the final hull
Brute.visitedPoints = {}	--stores all the points as we search from them so we can see how much we've done already
Brute.curLine = {}			--stores the current check line
Brute.canvas = nil 			--The framebuffer\
Brute.points = {}
Brute.num = -1
Brute.__index = Brute

function Brute.new(points, num)
	local self = setmetatable({}, Brute)
	self.canvas = love.graphics.newCanvas(width/2, height)  
	self.checkTable = {}
	self.finalHull = {}
	self.visitedPoints = {}
	self.curLine = {}	
	self.num = num
	self.points = points
	return self
end

function Brute:Reset()
	self.canvas = love.graphics.newCanvas(width/2, height)  
	self.checkTable = {}
	self.finalHull = {}
	self.visitedPoints = {}
	self.curLine = {}
end

function Brute:Draw() 
	if self.canvas == nil then return end
	love.graphics.setCanvas(self.canvas)
        self.canvas:clear()
        love.graphics.setBlendMode('alpha')

        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.rectangle('fill', 0, 0, width/2, height)
        

        --draws all of the points
		love.graphics.setColor(255,0,0,255)
		for _,p in pairs(self.points) do
			love.graphics.rectangle("fill", p.x-1, p.y-1, 3, 3)	
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

		--draws the current comparrison line
		if self.curLine ~= nil then
			love.graphics.setColor(50,255,0,255)
			love.graphics.line(self.curLine[1].x, self.curLine[1].y, self.curLine[2].x, self.curLine[2].y)
		end
	love.graphics.setCanvas()
end

--Runs through the entire set of points using the given line
-- and checks to see if they are all on one side of it.
function Brute:isBoundry(LineStart, LineEnd)
	local prevSide = 0
	local isInitilized = false

	for _,p in pairs(self.points) do
		local curSide = relativeToLine(LineStart, LineEnd, p)

		if not isInitilized then
			prevSide = curSide
			isInitilized = true
		else
			if prevSide ~= 0 and curSide ~= 0 and curSide ~= prevSide then
				return false
			elseif prevSide == 0 then
				prevSide = curSide
			end
		end 
	end
	return true
end

function Brute:doTiming()
	local starttimes = {}
	local endtimes = {}

	for l = 1, 2 do
		self:Reset()
		starttimes[#starttimes + 1] = socket.gettime()
		self:findHull()
		endtimes[#endtimes + 1] = socket.gettime() - starttimes[#starttimes]
		--coroutine.yield()
	end

	local avgBruteTime = 0
	for _,l in pairs(endtimes) do
		avgBruteTime = avgBruteTime + l
	end
	avgBruteTime = avgBruteTime / #endtimes

	print ("Burte@"..tostring(self.num)..": "..tostring(avgBruteTime))
	self:ClearAll()
	coroutine.yield()
end

function Brute:ClearAll()
	self.canvas = nil 
	self.checkTable = nil
	self.finalHull = nil
	self.visitedPoints = nil
	self.curLine = nil
	self.num = nil
	self.points = nil
end

--runs through all points for each point, checking to see if the line that they make
--has all the rest of the points on one side of it
function Brute:findHull()
	local i = 1


	for _,p1 in pairs(self.points) do
		self.visitedPoints[_] = p1
		for l,p2 in pairs(self.points) do
			if p1 ~= p2 and not self:hasLine(p1, p2) then
				self:setLine(p1, p2)
				self.curLine = {p1, p2}

				if self:isBoundry(p1, p2) then
					self.finalHull[i] = {p1, p2} 
					i = i + 1
				end
				--coroutine.yield()
			end
		end
	end

	self.curLine = nil
end

--checks to see if line exhists
function Brute:hasLine(p1, p2) 
	if self.checkTable[tostring(p1).."|"..tostring(p2)] == nil then return false end
	return true
end

--sets the values to make it exhist
function Brute:setLine(p1, p2)
	self.checkTable[tostring(p1).."|"..tostring(p2)] = 1
	self.checkTable[tostring(p2).."|"..tostring(p1)] = 1
end
