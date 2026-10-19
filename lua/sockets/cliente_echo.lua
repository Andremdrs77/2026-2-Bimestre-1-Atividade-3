local socket = require("socket")

local cliente = assert(socket.connect("127.0.0.1", 8081))

while true do
    io.write("Digite uma mensagem (sair para encerrar): ")

    local mensagem = io.read()

    if not mensagem or mensagem == "sair" then
        break
    end

    cliente:send(mensagem .. "\n")

    local resposta = cliente:receive("*l")

    print("Resposta do servidor: " .. (resposta or ""))
end

cliente:close()