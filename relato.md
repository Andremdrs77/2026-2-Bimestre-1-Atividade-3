# Relatório sobre implementação de comunicação entre tarefas em Lua

## Introdução

Este relato faz parte do processo avaliativo da disciplina de Sistemas Operacionais, do curso superior em Análise e Desenvolvimento de Sistemas, ofertado na Diretoria Acadêmica de Gestão e Tecnologia da Informação, no Campus Natal-Central do Instituto Federal de Educação, Ciência e Tecnologia do Rio Grande do Norte.

Tem como objetivo relatar as implementações e os conceitos de comunicação entre tarefas na linguagem Lua, utilizando Docker e bibliotecas específicas para possibilitar a troca de informações entre tarefas e processos.

O grupo de trabalho foi formado por André Medeiros, Denju Gabriel e Lucas Gabryel.

## Comunicação entre tarefas em Lua

### Informações gerais

A comunicação entre tarefas permite que diferentes tarefas de uma aplicação troquem informações e cooperem entre si. O mecanismo utilizado depende de onde as tarefas estão sendo executadas: no mesmo processo, em processos diferentes ou em computadores diferentes.

Neste trabalho foi utilizada a linguagem Lua, juntamente com a biblioteca Lanes, para trabalhar com tarefas concorrentes.

O Docker foi utilizado para padronizar o ambiente de execução, evitando dependências das configurações do computador. Foi utilizada a imagem `nickblah/lua:5.4-luarocks`, com instalação da biblioteca Lanes.

A configuração utilizada foi:

```dockerfile
FROM nickblah/lua:5.4-luarocks

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libc6-dev

RUN luarocks install lanes

WORKDIR /app

COPY . .

CMD ["lua", "sequencial.lua"]
```

A imagem foi construída com:

```bash
docker build -t atividade_03 .
```

---

### Comunicação entre tarefas com linhas de execução no mesmo processo

Nesta etapa foi implementado um produtor-consumidor utilizando tarefas concorrentes. O produtor gera 100 números aleatórios entre 0 e 110, enquanto o consumidor recebe esses dados e calcula sua soma.

Foi utilizada a biblioteca Lanes e a biblioteca Linda para realizar a comunicação entre as tarefas. O produtor coloca os dados em Linda utilizando `set`, enquanto o consumidor os recupera utilizando `get`.

#### Código completo

```lua
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
    print("### consumidor - terminado")
end

local produtor = lanes.gen("*", produzir_dados)
local consumidor = lanes.gen("*", consumir_dados)

print("iniciou")

local thread_produtor = produtor(linda)
local thread_consumidor = consumidor(linda)

print("finalizou")

thread_produtor:join()
thread_consumidor:join()
```

O produtor e o consumidor são iniciados antes dos `join()`, permitindo que sejam executados concorrentemente. Linda funciona como intermediária na comunicação entre as duas tarefas.

#### Execução

O programa sequencial foi executado no Docker com:

```bash
docker run --rm atividade_03
```

Algumas das saídas obtidas foram:

```text
iniciou
recebeu -> 6013
finalizou
```

```text
iniciou
recebeu -> 5703
finalizou
```

Os valores variam porque os números utilizados no cálculo são gerados aleatoriamente.

Para executar o produtor-consumidor:

```bash
docker run --rm atividade_03 lua produto-consumidor.lua
```

#### Problemas encontrados e soluções

1. **Problema com `require`:** o `sequencial.lua` executava `principal()` mesmo quando era importado por `exemplo_main.lua`. O arquivo foi reorganizado para funcionar como módulo.

2. **Execução sequencial do produtor-consumidor:** inicialmente o consumidor só era iniciado depois do término do produtor. A solução foi iniciar as duas tarefas antes dos `join()` e utilizar Linda para a comunicação.

---

### Comunicação entre processos diferentes no mesmo computador utilizando Pipes

Quando a comunicação ocorre entre processos diferentes no mesmo computador, eles não compartilham diretamente a mesma área de memória. Nesse caso, podem ser utilizados mecanismos como Pipes para permitir a troca de informações.

Um Pipe funciona como um canal de comunicação, permitindo que a saída de um processo seja encaminhada para a entrada de outro.

Nesta etapa, é possível utilizar dois programas em Lua: um produtor e um consumidor. O produtor envia informações pelo Pipe, enquanto o consumidor recebe esses dados e realiza o processamento.

#### Código do consumidor (`consumidor.lua`)

```lua
print("Consumidor iniciado")

local soma = 0

for linha in io.lines() do
    local numero = tonumber(linha)

    if numero then
        soma = soma + numero
    end
end

print("Resultado recebido: " .. soma)
print("Consumidor finalizado")
```

#### Código do produtor (`produtor.lua`)

```lua
print("Produtor iniciado")

local pipe = io.popen("lua consumidor.lua", "w")

for i = 1, 10 do
    pipe:write(i .. "\n")
end

pipe:close()

print("Produtor finalizado")
```

Nesse exemplo, o produtor inicia o processo consumidor e envia dez números pelo Pipe. O consumidor recebe os valores pela entrada padrão e calcula a soma.

A utilização do Pipe permite a comunicação entre dois processos independentes, sem a necessidade de compartilhar diretamente a memória.

#### Execução

Para executar o exemplo no ambiente Lua, os dois arquivos devem estar no mesmo diretório. O produtor pode ser iniciado com:

```bash
lua produtor.lua
```

O resultado esperado é a soma dos números enviados pelo produtor, que corresponde a 55.

---

### Comunicação entre computadores diferentes utilizando Sockets

A comunicação entre computadores diferentes pode ser realizada por meio de Sockets, que permitem a troca de informações através de uma rede.

Para esse tipo de comunicação, pode ser utilizado o protocolo TCP, seguindo o modelo cliente-servidor. Nesse modelo, o servidor aguarda conexões, enquanto o cliente estabelece uma conexão para enviar e receber informações.

Com base no material de referência sobre Sockets em Python, foram estudados três exemplos de aplicação:

#### 1. Servidor e cliente básico

Esse exemplo apresenta uma conexão simples entre cliente e servidor, permitindo a troca de uma mensagem.

O servidor fica aguardando uma conexão, enquanto o cliente se conecta e envia uma mensagem. O servidor recebe a informação e pode responder ao cliente.

#### 2. Servidor e cliente Echo

Nesse modelo, o servidor recebe uma mensagem enviada pelo cliente e devolve o mesmo conteúdo.

Esse exemplo permite compreender melhor o funcionamento do envio e recebimento de dados por meio de uma conexão TCP.

#### 3. Servidor e cliente de Chat

O exemplo de Chat permite a comunicação entre vários clientes conectados a um servidor.

Para possibilitar o atendimento de vários clientes, podem ser utilizadas tarefas concorrentes, permitindo que o servidor receba e encaminhe mensagens entre os participantes.

Na linguagem Lua, esses exemplos podem ser desenvolvidos utilizando a biblioteca LuaSocket, que permite criar conexões TCP, enviar e receber dados e implementar aplicações no modelo cliente-servidor.

A comunicação por Sockets permite que aplicações executadas em computadores diferentes troquem informações através da rede.

**Observação:** os exemplos de servidor básico, Echo e Chat foram utilizados como referência conceitual a partir do material de Sockets em Python. A implementação correspondente em Lua ainda precisa ser desenvolvida e testada para que possa ser considerada concluída.

---

## Considerações finais

Foi possível implementar e executar a comunicação entre tarefas no mesmo processo utilizando Lua, Lanes e Linda. Também foi possível executar os programas dentro de um container Docker configurado com Lua 5.4 e as dependências necessárias.

Além disso, foram estudados os mecanismos de comunicação entre processos diferentes no mesmo computador, utilizando Pipes, e a comunicação entre computadores diferentes, utilizando Sockets.

O trabalho permitiu compreender diferentes formas de comunicação entre tarefas e processos, relacionando os conceitos estudados na disciplina com exemplos práticos de programação.
