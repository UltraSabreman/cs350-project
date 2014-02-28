require "BruteForce"
require "QuickHull"
require "socket"
require "Vector"

function sleep(sec)
    socket.select(nil, nil, sec)
end

args = {...}
points = {}

local height = love.window.getHeight()
local width  = love.window.getWidth()
local numOfPoints = tonumber(args[0]) or 30
local co

function love.load() 
	--circlePoints(200)
	randPoints()
	--co = coroutine.create(Brute.findHull)
	co = coroutine.create(Quick.findHull)
end

function love.update()
	if coroutine.status(co) ~= "dead" then
		local errorfree, value = coroutine.resume(co)
	end
end

function love.draw()
	--draws the points
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(1)
	--Brute.Draw()
	Quick.Draw()
end

--generates the points in a perfect circle
function circlePoints(radius)
	local angStep = (math.pi * 2) / numOfPoints
	local curAng = angStep
	for i = 1, numOfPoints do
		local x = (width / 2) + math.sin(curAng) * radius
		local y = (height / 2) + math.cos(curAng) * radius
		curAng = curAng + angStep

		points[i] = Vector.new(x, y)
	end
end

--generates the points in a random fasion
function randPoints() 
	math.randomseed(os.time())
	for i = 1, numOfPoints do
		temp = Vector.new(math.random(0, width - 10), math.random(0, height - 10))

		points[i] = temp
	end
end

--Checks wich side of the line our point is on.
function relativeToLine(LineStart, LineEnd, Point) 
	local check = ((LineEnd.x - LineStart.x) * (Point.y - LineStart.y) - (LineEnd.y - LineStart.y) * (Point.x - LineStart.x))
	if check > 0 then return 1 end
	if check == 0 then return 0 end
	if check < 0 then return -1 end
end