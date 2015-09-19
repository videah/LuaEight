require 'bit'

math.randomseed(os.time())

local eight = require('luaeight'):new()

eight:loadROM("roms/glitchghost")

function love.draw()

	eight:cycle()

	for i = 1, 64 * 32 do
		local x = ((i - 1) % 64)
		local y = (math.floor((i - 1) / 64))
		local b = eight.displayBuffer[i - 1]

		local color = b == 1 and { 255, 255, 255 } or { 0, 0, 0 }
		love.graphics.setColor(unpack(color))
		love.graphics.rectangle("fill", x * 16, y * 16, 16, 16)
	end

end