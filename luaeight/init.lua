local path = ... .. '.'
require('bit')
require(path .. 'hex')
local class = require(path .. 'middleclass')
local Eight = class('Eight')

function Eight:initialize()

	self.opcode = 0

	self.fontset = {
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

	self.memory = {}
	for i=1, 0x1000 do
		self.memory[i] = 0
	end

	for i=1, 80 do
		self.memory[i] = self.fontset[i]
	end

	self.V = {}
	for i=0, 15 do
		self.V[i] = 0
	end

	self.I = 0
	self.pc = 0x200

	self.displayBuffer = {}
	for i=1, 64 * 32 do
		self.displayBuffer[i] = 0
	end

	self.delayTimer = 0
	self.soundTimer = 0

	self.stack = {}
	self.sp = 0

	self.keys = {}

end

-- function Eight:loadROM(rom)

-- 	self:initialize()

-- 	local index = 0x200

-- 	local file = io.open(rom)
-- 	if file == nil then
-- 		error("Can't find ROM")
-- 	end

-- 	while true do

-- 		local data = file:read(2)
-- 		if data == nil then
-- 			return false
-- 		end
-- 		print(data)
-- 		self.memory[index] = hex.to_dec('0x'  .. data)
-- 		index = index + 1

-- 	end

-- 	print("Loaded ROM: " .. rom)

-- end

function Eight:loadROM(rom)

	local index = 0x200

	for file in io.open(rom):read("*a"):gmatch(".") do
		self.memory[index] = string.byte(file)
		index = index + 1
	end

end

function Eight:cycle()

	print('PC = ' .. self.pc)

	self.opcode = self:fetchOP()

	self.pc = self.pc + 2

	self:executeOP(self.opcode)

end

function Eight:mergeByte(b1, b2, amount)

	amount = amount or 8

	local shiftcode = bit.lshift(b1, amount) -- Shift b1 by amount bits to the left
	local orcode = bit.bor(shiftcode, b2) -- Fill in those new 8 bits with b2
	
	return orcode

end

function Eight:fetchOP()

	-- Fetch opcode
	local byte1 = self.memory[self.pc]
	local byte2 = self.memory[self.pc + 1]

	return self:mergeByte(byte1, byte2, 8)


end

function Eight:executeOP(op)

	local dcode = bit.band(op, 0xF000) -- What's the first 4 bits?

	local x = bit.rshift(bit.band(op, 0x0F00), 8)
	local y = bit.rshift(bit.band(op, 0x00F0), 4)
	local kk = bit.band(op, 0x00FF)
	local nnn = bit.band(op, 0x0FFF)
	local n = bit.band(op, 0x000F)

	print('Attempting to execute opcode: ' .. hex.to_hex(op))

	if dcode == 0x0000 then

		if op == 0x00E0 then -- CLS: Clear the display.

			self:clearDisplay()

		elseif op == 0x00EE then -- RET: Return from subroutine.

			self.pc = self.stack[#self.stack]
			self.sp = self.sp - 1

		end

	end

	if dcode == 0x1000 then

		self.pc = nnn

	end

	if dcode == 0x2000 then

		self.stack[#self.stack] = self.pc
		self.pc = nnn

	end

	if dcode == 0x3000 then

		if self.V[x] == kk then
			self.pc = self.pc + 2
		end

	end

	if dcode == 0x4000 then

		if self.V[x] ~= kk then
			self.pc = self.pc + 2
		end

	end

	if dcode == 0x5000 then

		if self.V[x] == self.V[y] then
			self.pc = self.pc + 2
		end

	end

	if dcode == 0x6000 then

		self.V[x] = kk

	end

	if dcode == 0x7000 then

		self.V[x] = self.V[x] + bit.band(op, kk)

	end

	if dcode == 0x8000 then

		local optype = bit.band(op, 0x000F)

		if optype == 0x0000 then

			self.V[x] = self.V[y]

		end

		if optype == 0x0001 then

			self.V[x] = bit.bor(self.V[x], self.V[y])

		end

		if optype == 0x0002 then

			self.V[x] = bit.band(self.V[x], self.V[y])

		end

		if optype == 0x0003 then

			self.V[x] = bit.xor(self.V[x], self.V[y])

		end

		if optype == 0x0004 then

			if self.V[y] > (0xFF - self.V[x]) then
				self.V[0xF] = 1
			else
				self.V[0xF] = 0
			end

			self.V[x] = self.V[x] + self.V[y]

		end

		if optype == 0x0005 then

			if self.V[x] > self.V[y] then
				self.V[0xF] = 0x1
			else
				self.V[0xF] = 0x0
			end

			self.V[x] = self.V[x] - self.V[y]

		end

		if optype == 0x0006 then

			self.V[0xF] = bit.band(self.V[x], 0x1)
			self.V[x] = bit.rshift(self.V[x], 1)

		end

		if optype == 0x0007 then

			if self.V[y] > self.V[x] then
				self.V[0xF] = 0x1
			else
				self.V[0xF] = 0x0
			end

			self.V[x] = self.V[y] - self.V[x]

		end

		if optype == 0x0008 then

			print("8XYE is not implemented.")

		end

	end

	if dcode == 0x9000 then

		if self.V[x] ~= self.V[y] then
			self.pc = self.pc + 2
		end

	end

	if dcode == 0xA000 then

		self.I = nnn

	end

	if dcode == 0xB000 then

		self.pc = nnn + self.V[0]

	end

	if dcode == 0xC000 then

		self.V[x] = bit.band(math.floor(math.random() * 0xFF), kk)

	end

	if dcode == 0xD000 then

		self.V[0xF] = 0

		local height = bit.band(op, 0x000F)
		local rX = self.V[x]
		local rY = self.V[y]

		for yline=0, height - 1 do
			local spr = self.memory[self.I + yline]
			for xline=0, 7 do
				if bit.band(spr, 0x80) > 0 then
					if self.displayBuffer[rX + xline + ((rY + yline) * 64)] ~= 0 then
						self.V[0xF] = 1
					end

					self.displayBuffer[rX + xline + ((rY + yline) * 64)] = bit.bxor(self.displayBuffer[rX + xline + ((rY + yline) * 64)], 1)
				end
				spr = bit.lshift(spr, 1)
			end
		end

	end

	if dcode == 0xE000 then

		local optype = bit.band(op, 0x00FF)

		if optype == 0x009E then

			if self.keys[self.V[x]] == 1 then
				self.pc = self.pc + 2
			end

		end

		if optype == 0x00A1 then

			if self.keys[self.V[x]] ~= 1 then
				self.pc = self.pc + 2
			end

		end

	end

	if dcode == 0xF000 then

		local optype = bit.band(op, 0x00FF)

		if optype == 0x0007 then
			self.V[x] = self.delayTimer
		end

	end

end

function Eight:clearDisplay()

	for i=1, 64 * 32 do
		self.displayBuffer[i] = 0
	end

end

return Eight