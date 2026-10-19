local socket = require("socket")

local cliente = assert(socket.connect("127.0.0.1", 8082))

cliente:settimeout(0)

print("Conectado ao chat!")
print("Digite suas mensagens (sair para encerrar):")

while true do
    local mensagem = io.read()

    if not mensagem or mensagem == "sair" then
        break
    end

    cliente:send(mensagem .. "\n")

    local resposta, erro = cliente:receive("*l")

    if resposta then
        print("Mensagem recebida: " .. resposta)
    end
end

cliente:close()