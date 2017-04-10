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

----- CHIP8 Variables
-- n   == opcode & 0x000F
-- nn  == opcode & 0x00FF
-- nnn == opcode & 0x0FFF

-- x == (opcode & 0x0F00) >> 8
-- y == (opcode & 0x00F0) >> 4


----- Code Examples
-- local n = bit.band(op, 0x000F)
-- local nn = bit.band(op, 0x00FF)
-- local nnn = bit.band(op, 0x0FFF)

-- local x = bit.rshift(bit.band(op, 0x0F00), 8)
-- local y = bit.rshift(bit.band(op, 0x00F0), 4)


-- Opcode Identification
-- [code] -- [assembler] -- [description]

local ops = {

	[0x0000] = function(self, op, n, nn, nnn, x, y)

		-- 00E0 - CLS - Clear the screen.
		if op == 0x00E0 then
			for i=1, 64 * 32 do
				self.display_buffer[i] = 0
			end
		end

		-- 00EE - RTS - Return from subroutine call.
		-- Sets the program counter to the address at the top of the stack,
		-- then subtracts 1 from the stack pointer.
		if op == 0x00EE then
			self.pc = self.stack[#self.stack]
			self.sp = self.sp - 1
		end

	end,

	-- 1NNN - jmp nnn - Jump to address nnn.
	-- Sets the program counter to nnn.
	[0x1000] = function(self, op, n, nn, nnn, x, y)

		self.pc = nnn

	end,

	-- 2NNN - jsr nnn - Jump to subroutine at address nnn.
	-- The interpreter increments the stack pointer,
	-- then puts the current program counter value on the top of the stack.
	-- The program counter is then set to nnn.
	[0x2000] = function(self, op, n, nn, nnn, x, y)

		self.stack[self.sp] = self.pc
		self.sp = self.sp + 1
		self.pc = nnn

	end,

	[0x3000] = function(self, op, n, nn, nnn, x, y)

		if self.V[x] == nn then
			self.pc = self.pc + 2
		end

	end,

	[0x4000] = function(self, op, n, nn, nnn, x, y)

		if self.V[x] ~= nn then
			self.pc = self.pc + 2
		end


	end,

	[0x5000] = function(self, op, n, nn, nnn, x, y)

		if self.V[x] == self.V[y] then
			self.pc = self.pc + 2
		end

	end,

	[0x6000] = function(self, op, n, nn, nnn, x, y)

		self.V[x] = nn

	end,

	[0x7000] = function(self, op, n, nn, nnn, x, y)

		self.V[x] = self.V[x] + bit.band(op, nn)

	end,

	[0x8000] = function(self, op, n, nn, nnn, x, y)

		if n == 0x0000 then
			self.V[x] = self.V[y]
		end

		if n == 0x0001 then
			self.V[x] = bit.bor(self.V[x], self.V[y])
		end

		if n == 0x0002 then
			self.V[x] = bit.band(self.V[x], self.V[y])
		end

		if n == 0x0003 then
			self.V[x] = bit.xor(self.V[x], self.V[y])
		end

		if n == 0x0004 then

			if self.V[y] > (0xFF - self.V[x]) then
				self.V[0xF] = 1
			else
				self.V[0xF] = 0
			end

			self.V[x] = self.V[x] + self.V[y]

		end

		if n == 0x0005 then

			if self.V[x] > self.V[y] then
				self.V[0xF] = 0x1
			else
				self.V[0xF] = 0x0
			end

			self.V[x] = self.V[x] - self.V[y]

		end

		if n == 0x0006 then

			self.V[0xF] = bit.band(self.V[y], 0x0001)

			self.V[x] = bit.rshift(self.V[y], 1)

		end

		if n == 0x0007 then

			if self.V[y] > self.V[x] then
				self.V[0xF] = 0x1
			else
				self.V[0xF] = 0x0
			end

			self.V[x] = self.V[y] - self.V[x]

		end

		if n == 0x000E then

			self.V[0xF] = bit.band(self.V[y], 0x1000)

			self.V[x] = bit.lshift(self.V[y], 1)

		end

	end,

	[0x9000] = function(self, op, n, nn, nnn, x, y)

		if self.V[x] ~= self.V[y] then
			self.pc = self.pc + 2
		end

	end,

	[0xA000] = function(self, op, n, nn, nnn, x, y)

		self.I = nnn

	end,

	[0xB000] = function(self, op, n, nn, nnn, x, y)

		self.pc = nnn + self.V[0]

	end,

	[0xC000] = function(self, op, n, nn, nnn, x, y)

		self.V[x] = bit.band(math.floor(math.random() * 0xFF), nn)

	end,

	[0xD000] = function(self, op, n, nn, nnn, x, y)

		-- TODO: Clean this up, right now it's an unreadable mess.

		local height = bit.band(op, 0x000F)
		local rX = self.V[x]
		local rY = self.V[y]

		self.V[0xF] = 0

		for yline=0, height - 1 do

			local spr = self.memory[self.I + yline]

			for xline=0, 7 do

				if bit.band(spr, 0x80) > 0 then

					if self.display_buffer[rX + xline + ((rY + yline) * 64)] ~= 0 then
						self.V[0xF] = 1
					end

					self.display_buffer[rX + xline + ((rY + yline) * 64)] = bit.bxor(self.display_buffer[rX + xline + ((rY + yline) * 64)], 1)

				end

				spr = bit.lshift(spr, 1)

			end

		end

	end,

	[0xE000] = function(self, op, n, nn, nnn, x, y)

		if nn == 0x009E then

			if self.keys[self.V[x]] == 1 then
				self.pc = self.pc + 2
			end

		end

		if nn == 0x00A1 then

			if self.keys[self.V[x]] ~= 1 then
				self.pc = self.pc + 2
			end

		end

	end,

	[0xF000] = function(self, op, n, nn, nnn, x, y)

		if nn == 0x0007 then
			self.V[x] = self.delayTimer
		end

		if nn == 0x0015 then
			self.delayTimer = self.V[x]
		end

		if nn == 0x0018 then
			self.soundTimer = self.V[x]
		end

		if nn == 0x001E then

			if self.I + self.V[x] > 0xFFF then
				self.V[0xF] = 1
			else
				self.V[0xF] = 0
			end

			self.I = self.I + self.V[x]

		end

		if nn == 0x0029 then
			self.I = self.V[x] * 0.5
		end

	end,

}

return ops