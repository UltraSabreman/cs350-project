require "BruteForce"
require "QuickHull"
require "socket"
require "Vector"

function sleep(sec)
    socket.select(nil, nil, sec)
end

args = {...}
points = {}
height = love.window.getHeight()
width  = love.window.getWidth()

local numOfPoints = tonumber(args[0]) or 100
local BruteCoroutine, QuickCoroutine


function love.load() 
	Brute.onLoad()
	Quick.onLoad()

	circlePoints(190)
	--randPoints()

	BruteCoroutine = coroutine.create(Brute.findHull)
	QuickCoroutine = coroutine.create(Quick.findHull)
end

function love.update()
	if coroutine.status(BruteCoroutine) ~= "dead" then coroutine.resume(BruteCoroutine)	end
	if coroutine.status(QuickCoroutine) ~= "dead" then coroutine.resume(QuickCoroutine)	end
end

function love.draw()
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
	math.randomseed(os.time())
	for i = 1, numOfPoints do
		temp = Vector.new(math.random(0, (width / 2) - 10), math.random(0, height - 10))

		points[#points + 1] = temp
	end
end

--Checks wich side of the line our point is on.
function relativeToLine(LineStart, LineEnd, Point) 
	local check = ((LineEnd.x - LineStart.x) * (Point.y - LineStart.y) - (LineEnd.y - LineStart.y) * (Point.x - LineStart.x))
	if check > 0 then return 1 end
	if check == 0 then return 0 end
	if check < 0 then return -1 end
end