local socket = require("socket")

local servidor = assert(socket.bind("*", 8082))

servidor:settimeout(0)

local clientes = {}

print("Servidor de chat iniciado!")

while true do
    local novo_cliente = servidor:accept()

    if novo_cliente then
        novo_cliente:settimeout(0)

        table.insert(clientes, novo_cliente)

        print("Novo cliente conectado!")
    end

    for i = #clientes, 1, -1 do
        local cliente = clientes[i]

        local mensagem, erro = cliente:receive("*l")

        if mensagem then
            print("Mensagem: " .. mensagem)

            for _, outro in ipairs(clientes) do
                if outro ~= cliente then
                    outro:send(mensagem .. "\n")
                end
            end

        elseif erro == "closed" then
            print("Cliente desconectado!")

            cliente:close()
            table.remove(clientes, i)
        end
    end

    socket.sleep(0.05)
end