local socket = require("socket")

local servidor = assert(socket.bind("*", 8080))

print("Servidor aguardando conexao...")

local cliente = servidor:accept()

print("Cliente conectado!")

local mensagem = cliente:receive("*l")

print("Mensagem recebida: " .. (mensagem or ""))

cliente:send("Mensagem recebida pelo servidor!\n")

cliente:close()
servidor:close()