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

if not pcall(require, 'imgui') then return false end

local dbg = {}

dbg.paused = true

local function mediaButtons(cpu)

	if imgui.Button('|>', (imgui.GetWindowWidth() * 0.3) - 2, 30) then
		dbg.paused = false
	end

	imgui.SameLine()

	if imgui.Button('||', (imgui.GetWindowWidth() * 0.3) - 2, 30) then
		dbg.paused = true
	end

	imgui.SameLine()

	if imgui.Button('->', (imgui.GetWindowWidth() * 0.3) - 2, 30) then
		cpu:cycle()
	end

	if dbg.paused then
		imgui.ShowTestWindow(true)
	end

end

local function registers(cpu)

	imgui.Separator()

	imgui.Columns(3, "registers")

	imgui.Text('Index'); imgui.NextColumn();
	imgui.Text('V'); imgui.NextColumn();
	imgui.Text('Stack'); imgui.NextColumn();

	for i=0, 15 do
		imgui.Text(i)
	end

	imgui.NextColumn()

	for i=0, 15 do
		imgui.Text(cpu.V[i])
	end

	imgui.NextColumn()

	for i=0, 15 do
		imgui.Text(cpu.stack[i] or '')
	end

end

function dbg.draw(cpu)

	imgui.NewFrame()

	mediaButtons(cpu)

	imgui.Text("Hello, world!")

	imgui.Text("Paused: " .. tostring(dbg.paused))

	imgui.InputText('PC', cpu.pc, 32)
	imgui.InputText('SP', cpu.sp, 32)
	imgui.InputText('I', cpu.I, 32)
	registers(cpu)

	imgui.Render()

end

dbg.shutdown = imgui.ShutDown
dbg.textinput = imgui.TextInput
dbg.keypressed = imgui.KeyPressed
dbg.keyreleased = imgui.KeyReleased
dbg.mousemoved = imgui.MouseMoved
dbg.mousepressed = imgui.MousePressed
dbg.mousereleased = imgui.MouseReleased
dbg.wheelmoved = imgui.WheelMoved

dbg.getWantCaptureKeyboard = imgui.GetWantCaptureKeyboard
dbg.getWantCaptureMouse = imgui.GetWantCaptureMouse

return dbg