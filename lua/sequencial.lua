math.randomseed(os.time())

local function produzir_dados()
    local dados = {}

    for i = 1, 100 do
        dados[i] = math.random(0, 110)
    end

    return dados
end

local function consumir_dados(dados)
    local resultado = 0

    for i = 1, #dados do
        resultado = resultado + dados[i]
    end

    print("recebeu -> " .. resultado)
end

local function principal()
    print("iniciou")

    local dados = produzir_dados()

    consumir_dados(dados)

    print("finalizou")
end

if ... == nil then
    principal()
end

return {
    produzir_dados = produzir_dados,
    consumir_dados = consumir_dados,
    principal = principal
}