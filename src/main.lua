require "BruteForce"
require "QuickHull"
require "socket"
require "Vector"

height = love.window.getHeight()
width  = love.window.getWidth()

local numOfPoints = 500
local numOfSteps = 20

function love.load() 
	print("Starting "..tostring(numOfSteps).." tests.")
	for i = 1, numOfSteps do
		collectgarbage()
		local ind = tostring(i)
		numOfPoints = i * 500
		local points = randPoints() --circlePoints(150)

		Brute.new(points, numOfPoints):doTiming()
		Quick.new(points, numOfPoints):doTiming()
	end
end

function love.update()

end

function love.draw()
	--[[
	--used during testing to help debug.
	--draws the points
	love.graphics.setBlendMode('alpha')
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(1)
	love.graphics.setColor(255,255,255,255)

	Brute.Draw()
	Quick.Draw()

	love.graphics.setColor(255,255,255,255)
	love.graphics.setBlendMode('premultiplied')
	if Brute.canvas ~= nil then	love.graphics.draw(Brute.canvas, 0, 0) end
	if Quick.canvas ~= nil then	love.graphics.draw(Quick.canvas, 400, 0) end

	love.graphics.setBlendMode('alpha')
	love.graphics.setColor(255,255,255,255)
	love.graphics.line(width/2, 0, width/2, height)]]
end

--generates the points in a perfect circle
function circlePoints(radius)
	local angStep = (math.pi * 2) / numOfPoints
	local curAng = angStep
	local points = {}
	for i = 1, numOfPoints do
		local x = ((width - 10) / 4) + math.sin(curAng) * radius
		local y = ((height - 10) / 2) + math.cos(curAng) * radius
		curAng = curAng + angStep

		points[#points + 1] = Vector.new(x, y)
	end
	return points
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