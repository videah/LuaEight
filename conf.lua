io.stdout:setvbuf("no") -- Prints to SublimeText's console

function love.conf(c)

	c.title = "LuaEight Virtual Machine"
	c.author = "Ruairidh 'VideahGams' Carmichael"
	c.identity = "LuaEight"

	c.window.width = 1024
	c.window.height = 512
	c.window.resizable = true
	c.gammacorrect = true

end