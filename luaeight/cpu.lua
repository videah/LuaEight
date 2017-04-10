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

local CPU = {}

--- Resources
-- http://mattmik.com/files/chip8/mastering/chip8.html
-- http://devernay.free.fr/hacks/chip8/C8TECH10.HTM (Note: Some of this is incorrect, double check with other resources)
-- https://en.wikipedia.org/wiki/CHIP-8

local bit = require 'bit'

-- Very basic and dumb OOP
CPU.__index = CPU
function CPU:new()
	return setmetatable({}, self)
end

function CPU:initialize()

	-- Setup opcode to store current instructions.
	self.opcode = 0

	-- The CHIP8 interpreters fontset
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
		0xF0, 0x80, 0xF0, 0x80, 0x80
	}

	-- +---------------+ = 0x1000 (4096) End of Chip-8 RAM
	-- |               |
	-- |               |
	-- |               |
	-- |               |
	-- |               |
	-- |0x200 to 0x1000|
	-- |     Chip-8    |
	-- | Program / Data|
	-- |     Space     |
	-- |               |
	-- |               |
	-- |               |
	-- +- - - - - - - -+ = 0x600 (1536) Start of ETI 660 Chip-8 programs
	-- |               |
	-- |               |
	-- |               |
	-- +---------------+ = 0x200 (512) Start of most Chip-8 programs
	-- | 0x000 to 0x1FF|
	-- | Reserved for  |
	-- |  interpreter  |
	-- +---------------+ = 0x000 (0) Start of Chip-8 RAM

	-- Initialize 4KB of memory space.
	self.memory = {}
	for i=1, 0x1000 do
		self.memory[i] = 0
	end

	-- Load the fontset into the first 80 bytes of memory.
	for i=1, 80 do
		self.memory[i] = self.fontset[i]
	end

	-- Setup registers with 0 as the starting index
	-- to avoid messing stuff up.
	self.V = {}
	for i=0, 15 do
		self.V[i] = 0
	end

	-- Setup index and program counter.
	-- The program counter starts at 0x200 in memory,
	-- as everything before that is reserved for the interpreter.
	self.I = 0
	self.pc = 0x200

	-- Setup a monochromic display buffer with a resolution of 64 x 32 pixels.

	-- +------------------+
	-- |(1, 1)     (64, 1)|
	-- |                  |
	-- |                  |
	-- |(1, 31)   (64, 32)|
	-- +------------------+

	self.display_buffer = {}
	for i=1, 64 * 32 do
		self.display_buffer[i] = 0
	end

	-- Setup timers.
	self.delay_timer = 0
	self.sound_timer = 0

	-- Setup a stack along with a stack pointer.
	self.stack = {}
	self.sp = 0

	-- Setup key table for input.
	self.keys = {}

	self.instructions = require 'luaeight.opcodes'

end

function CPU:loadROM(rom)

	local i = 0x200

	-- Load bytes from the ROM file into memory.
	-- CHIP8 only has 4KB of memory so if we run out
	-- we raise an error.

	for file in io.open(rom):read('*a'):gmatch('.') do

		if i <= 0x1000 then
			self.memory[i] = string.byte(file)
			i = i + 1
		else
			error('Not enough memory to load ROM file.')
		end

	end

end

function CPU:cycle()

	-- Fetch the opcode from memory using the program counter.
	self.opcode = self:fetch_opcode(self.pc)

	-- Increment the program counter after successfully fetching opcode.
	self.pc = self.pc + 2

	self:execute_opcode(self.opcode)

end

function CPU:fetch_opcode(location)

	-- Grab two bytes from memory.
	local b1 = self.memory[location]
	local b2 = self.memory[location + 1]

	-- Merge bytes together to construct the opcode.
	local opcode = bit.lshift(b1, 8)
	opcode = bit.bor(opcode, b2)

	return opcode

end

function CPU:execute_opcode(op)

	local dcode = bit.band(op, 0xF000)

	local n = bit.band(op, 0x000F)
	local nn = bit.band(op, 0x00FF)
	local nnn = bit.band(op, 0x0FFF)

	local x = bit.rshift(bit.band(op, 0x0F00), 8)
	local y = bit.rshift(bit.band(op, 0x00F0), 4)

	if pcall(function() self.instructions[dcode](self, op, n, nn, nnn, x, y) end) then
		print(self.pc)
	else
		print('Unimplemented/broken opcode: ' .. op .. ' pc: ' .. self.pc)
	end

end

return CPU:new()