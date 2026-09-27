local lanes = require("lanes").configure()

local linda = lanes.linda()

local function produzir_dados(linda)
    math.randomseed(os.time())

    local dados = {}

    print("# produzir - iniciado")

    for i = 1, 100 do
        dados[i] = math.random(0, 110)
    end

    print("# produzir " .. table.concat(dados, ", "))
    print("# produzir - terminado")

    linda:set("dados", dados)
end

local function consumir_dados(linda)
    print("### consumir - iniciado")

    local dados = linda:get("dados")

    print("### dados -> " .. table.concat(dados, ", "))

    local resultado = 0

    for i = 1, #dados do
        resultado = resultado + dados[i]
    end

    print("### resultado -> " .. resultado)
    print("### consumir - terminado")
end

local produtor = lanes.gen("*", produzir_dados)
local consumidor = lanes.gen("*", consumir_dados)

print("iniciou")

local thread_produtor = produtor(linda)
local thread_consumidor = consumidor(linda)

print("finalizou")

thread_produtor:join()
thread_consumidor:join()