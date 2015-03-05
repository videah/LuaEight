local eight = {}

eight.memory = {}
eight.stack = {}
eight.display_buffer = {}
eight.pc = 512
eight.index = 0
eight.timer_delay = 0
eight.sound_delay = 0
eight.ipf = 1

eight.fontset = {
0xF0, 0x90, 0x90, 0x90, 0xF0,
0x20, 0x60, 0x20, 0x20, 0x70,
0xF0, 0x10, 0xF0, 0x80, 0xF0,
0xF0, 0x10, 0xF0, 0x10, 0xF0,
0x90, 0x90, 0xF0, 0x10, 0x10,
0xF0, 0x80, 0xF0, 0x10, 0xF0,
0xF0, 0x80, 0xF0, 0x90, 0xF0,
0xF0, 0x10, 0x20, 0x40, 0x40,
0xF0, 0x90, 0xF0, 0x90, 0xF0,
0xF0, 0x90, 0xF0, 0x10, 0xF0,
0xF0, 0x90, 0xF0, 0x90, 0x90,
0xE0, 0x90, 0xE0, 0x90, 0xE0,
0xF0, 0x80, 0x80, 0x80, 0xF0,
0xE0, 0x90, 0x90, 0x90, 0xE0,
0xF0, 0x80, 0xF0, 0x80, 0xF0,
0xF0, 0x80, 0xF0, 0x80, 0x80}

eight.funcmap = {

}

-- Memory --
for i=1, 4096 do
	eight.memory[i] = 0
end

-- Fonts --
for i=1, 80 do
	eight.memory[i] = eight.fontset[i]
end

-- Display --
for x = 0, 64 do
	eight.display_buffer[x] = {}
	for y = 0, 32 do
		eight.display_buffer[x][y] = math.random(0,1)
	end
end

function eight.loadROM(rom)

	local index = 512

	local file = io.open(rom)
	if file == nil then
		error("Can't find ROM")
	end

	while true do

		local data = file:read(1)
		if data == nil then break end
		eight.memory[index] = data:byte()
		index = index + 1

	end


end

function eight.cycle()

	for i=1, eight.ipf do

		local opcode = eight.memory[eight.pc] * 256 + eight.memory[eight.pc + 1]

		eight.pc = (eight.pc + 2) % 4096

		local base = math.floor(opcode/4096)
		local address = opcode % 4096

		if pcall(function() eight.funcmap[base]() end) == false then
			print("Unknown instruction: " .. base)
		else
			print("YEY")
		end

	end

end

return eight