require 'bit'

math.randomseed(os.time())

eight = require 'lua8'

eight.loadROM("testrom")

function love.draw()

	eight.cycle()

	for x=1, 64 do
		for y=1, 32 do
			if eight.display_buffer[x][y] == 1 then
				love.graphics.rectangle("fill", (16 * (x - 1)), 16 * (y - 1), 16, 16)
			end
		end
	end
end
