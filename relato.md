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

**Dockerfile**

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

## Comunicação entre tarefas com linhas de execução no mesmo processo

Nesta etapa foi implementado um produtor-consumidor utilizando tarefas concorrentes. O produtor gera 100 números aleatórios entre 0 e 110, enquanto o consumidor recebe esses dados e calcula sua soma.

Foi utilizada a biblioteca Lanes e a biblioteca Linda para realizar a comunicação entre as tarefas. O produtor coloca os dados em Linda utilizando `set`, enquanto o consumidor os recupera utilizando `get`.

### Código completo

**produto-consumidor.lua**

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

### Execução

O programa sequencial foi executado no Docker com:

```bash
docker run --rm atividade_03
```

Algumas das saídas obtidas foram:

```text
iniciou
recebeu -> 6013
finalizou

iniciou
recebeu -> 5703
finalizou
```

Os valores variam porque os números utilizados no cálculo são gerados aleatoriamente.

Para executar o produtor-consumidor:

```bash
docker run --rm atividade_03 lua produto-consumidor.lua
```

### Problemas encontrados e soluções

**Problema com require:** o `sequencial.lua` executava `principal()` mesmo quando era importado por `exemplo_main.lua`. O arquivo foi reorganizado para funcionar como módulo.

**Execução sequencial do produtor-consumidor:** inicialmente o consumidor só era iniciado depois do término do produtor. A solução foi iniciar as duas tarefas antes dos `join()` e utilizar Linda para a comunicação.

## Comunicação entre processos diferentes no mesmo computador utilizando Pipes

Quando a comunicação ocorre entre processos diferentes no mesmo computador, eles não compartilham diretamente a mesma área de memória. Nesse caso, podem ser utilizados mecanismos como Pipes para permitir a troca de informações.

Um Pipe funciona como um canal de comunicação, permitindo que a saída de um processo seja encaminhada para a entrada de outro.

Nesta etapa foram implementados dois programas em Lua: um produtor e um consumidor. O produtor inicia o processo consumidor e envia uma mensagem pelo Pipe, enquanto o consumidor recebe e apresenta essa mensagem na tela.

### Estrutura dos arquivos

```text
lua/
└── pipes/
    ├── produtor.lua
    └── consumidor.lua
```

### Código do consumidor

**lua/pipes/consumidor.lua**

```lua
print("Consumidor iniciado!")

local mensagem = io.read()

print("Mensagem recebida: " .. mensagem)

print("Consumidor finalizado!")
```

O consumidor utiliza `io.read()` para receber a mensagem enviada pelo produtor através da entrada padrão.

### Código do produtor

**lua/pipes/produtor.lua**

```lua
print("Produtor iniciado!")

local pipe = io.popen("lua5.4 lua/pipes/consumidor.lua", "w")

if pipe then
    pipe:write("Hello World!\n")
    pipe:close()
else
    print("Erro ao iniciar o consumidor!")
end

print("Produtor finalizado!")
```

O produtor utiliza `io.popen()` para iniciar outro processo e estabelecer um canal de comunicação com ele. Em seguida, utiliza `pipe:write()` para enviar a mensagem "Hello World!" ao consumidor.

### Execução

No ambiente GitHub Codespaces, com Lua 5.4 instalado, o programa foi executado a partir da pasta principal do projeto utilizando:

```bash
lua5.4 lua/pipes/produtor.lua
```

O resultado obtido foi:

```text
Produtor iniciado!
Consumidor iniciado!
Mensagem recebida: Hello World!
Consumidor finalizado!
Produtor finalizado!
```

Nesse exemplo, o produtor inicia o consumidor e envia a mensagem pelo Pipe. O consumidor recebe a informação e apresenta o conteúdo na tela.

A utilização do Pipe demonstra a comunicação unidirecional entre dois processos diferentes, sem a necessidade de compartilhar diretamente a memória.

## Comunicação entre computadores diferentes utilizando Sockets

A comunicação entre computadores diferentes pode ser realizada por meio de Sockets, que permitem a troca de informações através de uma rede.

Para esse tipo de comunicação, foi utilizado o protocolo TCP, seguindo o modelo cliente-servidor. Nesse modelo, o servidor aguarda conexões, enquanto o cliente estabelece uma conexão para enviar e receber informações.

Com base no material de referência sobre Sockets em Python, foram desenvolvidos exemplos equivalentes na linguagem Lua, utilizando a biblioteca LuaSocket.

### Estrutura dos arquivos

```text
lua/
└── sockets/
    ├── servidor_basico.lua
    ├── cliente_basico.lua
    ├── servidor_echo.lua
    ├── cliente_echo.lua
    ├── servidor_chat.lua
    └── cliente_chat.lua
```

### 1. Servidor e cliente básico

Esse exemplo apresenta uma conexão simples entre cliente e servidor, permitindo a troca de uma mensagem.

O servidor fica aguardando uma conexão, enquanto o cliente se conecta e envia uma mensagem. O servidor recebe a informação e responde ao cliente.

**servidor_basico.lua**

```lua
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
```

**cliente_basico.lua**

```lua
local socket = require("socket")

local cliente = assert(socket.connect("127.0.0.1", 8080))

cliente:send("Ola, servidor!\n")

local resposta = cliente:receive("*l")

print("Resposta do servidor: " .. (resposta or ""))

cliente:close()
```

### 2. Servidor e cliente Echo

Nesse modelo, o servidor recebe uma mensagem enviada pelo cliente e devolve o mesmo conteúdo.

Esse exemplo permite compreender melhor o funcionamento do envio e recebimento de dados por meio de uma conexão TCP.

**servidor_echo.lua**

```lua
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
```

**cliente_echo.lua**

```lua
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
```

### 3. Servidor e cliente Chat

O exemplo de Chat permite a comunicação entre vários clientes conectados a um servidor.

O servidor recebe mensagens dos clientes e encaminha essas informações aos demais participantes conectados. Para isso, utiliza uma estrutura de repetição para verificar as conexões e receber as mensagens.

**servidor_chat.lua**

```lua
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
```

**cliente_chat.lua**

```lua
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
```

### Biblioteca utilizada

A biblioteca LuaSocket foi utilizada para criar conexões TCP, enviar e receber mensagens e implementar a comunicação entre cliente e servidor.

Para instalar a biblioteca no ambiente Lua, foi utilizado:

```bash
luarocks install luasocket
```

### Execução

Para executar os exemplos, é necessário iniciar primeiro o servidor e depois o cliente correspondente, utilizando dois terminais.

Exemplo básico:

Terminal 1:

```bash
lua5.4 lua/sockets/servidor_basico.lua
```

Terminal 2:

```bash
lua5.4 lua/sockets/cliente_basico.lua
```

Para o exemplo Echo:

```bash
lua5.4 lua/sockets/servidor_echo.lua
```

```bash
lua5.4 lua/sockets/cliente_echo.lua
```

Para o exemplo Chat:

```bash
lua5.4 lua/sockets/servidor_chat.lua
```

```bash
lua5.4 lua/sockets/cliente_chat.lua
```

Os exemplos utilizam o endereço `127.0.0.1`, que representa o próprio computador. Para a comunicação entre computadores diferentes, é necessário utilizar o endereço IP da máquina que executa o servidor e configurar o acesso à rede.

## Considerações finais

O desenvolvimento da atividade permitiu compreender diferentes mecanismos de comunicação entre tarefas e processos utilizando a linguagem Lua.

Na comunicação dentro do mesmo processo, foram utComunicação entre computadores diferentes utilizando Sockets

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

**Observação:** os exemplos de servidor básico, Echo e Chat foram utilizados como referência conceitual a partir do material de Sockets em Python. A implementação correspondente em Lua ainda precisa ser desenvolvida e testada para que possa ser considerada concluída.ilizadas Lanes e Linda para permitir a troca de informações entre tarefas concorrentes. Na comunicação entre processos diferentes no mesmo computador, foi utilizado Pipe, por meio de `io.popen()`, para transmitir a mensagem "Hello World!". Já para a comunicação em rede, foram desenvolvidos exemplos utilizando a biblioteca LuaSocket, seguindo o modelo cliente-servidor.

Durante o desenvolvimento, foram encontrados desafios relacionados à configuração do ambiente, à instalação das bibliotecas e à execução dos programas. A realização dos testes e a correção dos caminhos dos arquivos também foram importantes para o funcionamento das implementações.

Dessa forma, a atividade contribuiu para relacionar os conceitos estudados na disciplina de Sistemas Operacionais com exemplos práticos de programação, demonstrando diferentes maneiras de realizar a comunicação entre tarefas e processos.
