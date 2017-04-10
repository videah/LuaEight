-- This code is licensed under the MIT Open Source License.

-- Copyright (c) 2017 Ruairidh Carmichael - ruairidhcarmichael@live.co.uk

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

math.randomseed(os.time())

local cpu = require('luaeight.cpu')
local dbg = require('debugger')

cpu:initialize()
cpu:loadROM('roms/IBM')

local paused = false

function love.update(dt)

	if dbg then paused = dbg.paused end

	for i=1, 1 do
		if not paused then cpu:cycle() end
	end

end

function love.draw()

	for i = 1, 64 * 32 do
		local x = ((i - 1) % 64)
		local y = (math.floor((i - 1) / 64))
		local b = cpu.display_buffer[i - 1]

		local color = b == 1 and { 255, 255, 255 } or { 0, 0, 0 }
		love.graphics.setColor(unpack(color))
		love.graphics.rectangle("fill", x * 16, y * 16, 16, 16)
	end

	love.graphics.setColor(255, 255, 255)

	if dbg then dbg.draw(cpu) end

end

if not dbg then return end

function love.textinput(t)
	dbg.textinput(t)
	if not dbg.getWantCaptureKeyboard() then
		-- Pass event to the game
	end
end

function love.keypressed(key)
	dbg.keypressed(key)
	if not dbg.getWantCaptureKeyboard() then
		-- Pass event to the game
	end
end

function love.keyreleased(key)
	dbg.keyreleased(key)
	if not dbg.getWantCaptureKeyboard() then
		-- Pass event to the game
	end
end

function love.mousemoved(x, y)
	dbg.mousemoved(x, y)
	if not dbg.getWantCaptureMouse() then
		-- Pass event to the game
	end
end

function love.mousepressed(x, y, button)
	dbg.mousepressed(button)
	if not dbg.getWantCaptureMouse() then
		-- Pass event to the game
	end
end

function love.mousereleased(x, y, button)
	dbg.mousereleased(button)
	if not dbg.getWantCaptureMouse() then
		-- Pass event to the game
	end
end

function love.wheelmoved(x, y)
	dbg.wheelmoved(y)
	if not dbg.getWantCaptureMouse() then
		-- Pass event to the game
	end
end