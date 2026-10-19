local socket = require("socket")

local cliente = assert(socket.connect("127.0.0.1", 8080))

cliente:send("Ola, servidor!\n")

local resposta = cliente:receive("*l")

print("Resposta do servidor: " .. (resposta or ""))

cliente:close()