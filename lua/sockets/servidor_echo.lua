local socket = require("socket")

local servidor = assert(socket.bind("*", 8081))

print("Servidor Echo aguardando conexao...")

local cliente = servidor:accept()

print("Cliente conectado!")

while true do
    local mensagem, erro = cliente:receive("*l")

    if not mensagem then
        break
    end

    print("Recebido: " .. mensagem)

    cliente:send(mensagem .. "\n")
end

cliente:close()
servidor:close()