require 'bit'

math.randomseed(os.time())

local eight = require('luaeight'):new()

eight:loadROM("roms/testrom")

function love.draw()

	eight:cycle()

	for i = 1, 64 * 32 do
		local x = i % 64
		local y = math.floor(i / 64)
		local b = eight.displayBuffer[i]

		local color = b == 1 and { 255, 255, 255 } or { 0, 0, 0 }
		love.graphics.setColor(unpack(color))
		love.graphics.rectangle("fill", x * 16, y * 16, 16, 16)
	end

end