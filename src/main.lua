require "BruteForce"
require "QuickHull"
require "socket"
require "Vector"

function sleep(sec)
    socket.select(nil, nil, sec)
end

args = {...}

height = love.window.getHeight()
width  = love.window.getWidth()

local numOfPoints = tonumber(args[0]) or 500
local numOfSteps = 20
local BruteCos = {}
local QuickCos = {}


function love.load() 
	print("Starting "..tostring(numOfSteps).." tests.")
	for i = 1, numOfSteps do
		local ind = tostring(i)
		numOfPoints = i * 500
		local points = randPoints()

		BruteCos["obj"..ind] = Brute.new(points, numOfPoints)
		BruteCos["co"..ind] = coroutine.create(function() BruteCos["obj"..ind]:doTiming() end)


		QuickCos["obj"..ind] = Quick.new(points, numOfPoints)
		QuickCos["co"..ind] = coroutine.create(function() QuickCos["obj"..ind]:doTiming() end)
	end
end

function love.update()
	for i = 1, numOfSteps do
		local ind = tostring(i)
		if BruteCos["obj"..ind] ~= nil and coroutine.status(BruteCos["co"..ind]) ~= "dead" then
			coroutine.resume(BruteCos["co"..ind])
		end
		if QuickCos["obj"..ind] ~= nil and coroutine.status(QuickCos["co"..ind]) ~= "dead" then
			coroutine.resume(QuickCos["co"..ind])
		end
	end
end

function love.draw()
	--draws the points
	love.graphics.setBlendMode('alpha')
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(1)
	love.graphics.setColor(255,255,255,255)

	--Brute.Draw()
	--Quick.Draw()

	love.graphics.setColor(255,255,255,255)
	love.graphics.setBlendMode('premultiplied')
	if Brute.canvas ~= nil then	love.graphics.draw(Brute.canvas, 0, 0) end
	if Quick.canvas ~= nil then	love.graphics.draw(Quick.canvas, 400, 0) end

	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(255,255,255,255)
	love.graphics.line(width/2, 0, width/2, height)
end
--generates the points in a perfect circle
function circlePoints(radius)
	local angStep = (math.pi * 2) / numOfPoints
	local curAng = angStep
	for i = 1, numOfPoints do
		local x = ((width - 10) / 4) + math.sin(curAng) * radius
		local y = ((height - 10) / 2) + math.cos(curAng) * radius
		curAng = curAng + angStep

		points[#points + 1] = Vector.new(x, y)
	end
end

--generates the points in a random fasion
function randPoints() 
	local t = os.time()
	math.randomseed(t)
	local points = {}
	for i = 1, numOfPoints do
		temp = Vector.new(math.random(25, (width / 2) - 25), math.random(25, height - 25))

		points[#points + 1] = temp
	end
	return points
end

--Checks wich side of the line our point is on.
function relativeToLine(LineStart, LineEnd, Point) 
	local check = ((LineEnd.x - LineStart.x) * (Point.y - LineStart.y) - (LineEnd.y - LineStart.y) * (Point.x - LineStart.x))
	if check > 0 then return 1 end
	if check == 0 then return 0 end
	if check < 0 then return -1 end
end