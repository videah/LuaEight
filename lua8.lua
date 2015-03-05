local eight = {}

eight.memory = {}
eight.stack = {}
eight.display_buffer = {}
eight.REG = {}
eight.pc = 512 -- Start counter after reserved memory space
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

function instruction_1(opcode, base, address)

	if address == 0x0E0 then
		for x = 0, 64 do
			eight.display_buffer[x] = {}
			for y = 0, 32 do
				eight.display_buffer[x][y] = 0
			end
		end
	elseif address == 0x0EE then
		eight.pc = eight.stack[#eight.stack]
		eight.stack[#eight.stack] = nil
	else
		print("RCA not implemented.")
		print(eight.pc)
	end
end

function instruction_2(opcode, base, address, pX, pY, value, subbase)

	eight.pc = address

end

function instruction_3(opcode, base, address, pX, pY, value, subbase)

	eight.stack[#eight.stack + 1] = eight.pc
	eight.pc = address

end

function instruction_4(opcode, base, address, pX, pY, value, subbase)
	if eight.REG[pX] == value then
		eight.pc = eight.pc + 2
	end
end

function instruction_5(opcode, base, address, pX, pY, value, subbase)
	if eight.REG[pX] ~= value then
		eight.pc = eight.pc + 2
	end
end

function instruction_6(opcode, base, address, pX, pY, value, subbase)

	if eight.REG[pX] == eight.REG[pY] then
		eight.pc = eight.pc + 2
	end

end

function instruction_7(opcode, base, address, pX, pY, value, subbase)

	eight.REG[pX] = value

end

function instruction_8(opcode, base, address, pX, pY, value, subbase)

	eight.REG[pX] = (eight.REG[pX] + value) % 256

end

function instruction_9(opcode, base, address, pX, pY, value, subbase)

	if subbase == 14 or (subbase >= 0 and subbase <=7) then

		if subbase == 0 then
			eight.REG[pX] = eight.REG[pY]
		elseif subbase == 1 then 
			eight.REG[pX] = bit32.bor(eight.REG[pX],eight.REG[pY])
		elseif subbase == 2 then 
			eight.REG[pX] = bit32.band(eight.REG[pX],eight.REG[pY])
		elseif subbase == 3 then 
			eight.REG[pX] = bit32.bxor(eight.REG[pX],eight.REG[pY])
		elseif subbase == 4 then 
			local tmp = eight.REG[pX] + eight.REG[pY]
			eight.REG[15] = tmp > 255 and 1 or 0
			eight.REG[pX] = tmp % 256
		elseif subbase == 5 then 
			local tmp = eight.REG[pX] - eight.REG[pY]
			eight.REG[15] = tmp >= 0 and 1 or 0
			eight.REG[pX] = (tmp + 256) % 256
		elseif subbase == 6 then 
			eight.REG[15] = eight.REG[pY] % 2
			eight.REG[pX] = math.floor(eight.REG[pY] / 2)
		elseif subbase == 7 then 
			local tmp = eight.REG[pY] - eight.REG[pX]
			eight.REG[15] = tmp >= 0 and 1 or 0
			eight.REG[pX] = (tmp + 256) % 256
		elseif subbase == 14 then
			eight.REG[15] = math.floor(eight.REG[pY] / 128) % 2
			eight.REG[pX] = (eight.REG[pY] * 2) % 256
		end
	end

end

function instruction_9(opcode, base, address, pX, pY, value, subbase)

	if subbase == 0 then
		if eight.REG[pX] ~= eight.REG[pY] then
			eight.pc = eight.pc + 2
		end
	end

end

function instruction_10(opcode, base, address, pX, pY, value, subbase)

	eight.index = address

end

eight.funcmap = {
instruction_1,
instruction_2,
instruction_3,
instruction_4,
instruction_5,
instruction_6,
instruction_7,
instruction_8,
instruction_9,
instruction_10

}

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

		local base = math.floor(opcode/4096) + 1
		local address = opcode % 4096
		local pX = math.floor(opcode/256)%16
		local pY = math.floor(opcode/16)%16
		local subbase = opcode%16
		local value = opcode%256

		if pcall(function() eight.funcmap[base](opcode, base, address, pX, pY, value, subbase) end) == false then
			print("Unknown instruction: " .. base)
		else
			print("Successfuly ran instruction: " .. base)
		end

	end

end

return eight