# Relatório sobre implementação de comunicação entre tarefas em Lua

## Introdução

Este relato faz parte do processo avaliativo da disciplina de Sistemas Operacionais, do curso superior em Análise e Desenvolvimento de Sistemas, ofertado na Diretoria Acadêmica de Gestão e Tecnologia da Informação, no Campus Natal-Central do Instituto Federal de Educação, Ciência e Tecnologia do Rio Grande do Norte.

Tem como objetivo relatar as implementações de comunicação entre tarefas na linguagem Lua, utilizando Docker e a biblioteca Lanes.

O grupo de trabalho foi formado por André Medeiros, Denju Gabriel e Lucas Gabryel.

## Comunicação entre tarefas em Lua

### Informações gerais

A comunicação entre tarefas permite que diferentes tarefas de uma aplicação troquem informações e cooperem entre si. O mecanismo utilizado depende de onde as tarefas estão sendo executadas: no mesmo processo, em processos diferentes ou em computadores diferentes.

Neste trabalho foi utilizada a linguagem Lua, juntamente com a biblioteca Lanes, para trabalhar com tarefas concorrentes.

O Docker foi utilizado para padronizar o ambiente de execução, evitando dependências das configurações do computador. Foi utilizada a imagem `nickblah/lua:5.4-luarocks`, com instalação da biblioteca Lanes.

A configuração utilizada foi:

```
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

```
docker build -t atividade_03 .
```

---

### Comunicação entre tarefas com linhas de execução no mesmo processo

Nesta etapa foi implementado um produtor-consumidor utilizando tarefas concorrentes. O produtor gera 100 números aleatórios entre 0 e 110, enquanto o consumidor recebe esses dados e calcula sua soma.

Foi utilizada a biblioteca Lanes e a biblioteca **Linda** para realizar a comunicação entre as tarefas. O produtor coloca os dados em Linda utilizando `set`, enquanto o consumidor os recupera utilizando `get`.

#### Código completo

```
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

```
docker run --rm atividade_03
```

Algumas das saídas obtidas foram:

```
iniciou
recebeu -> 6013
finalizou
```

```
iniciou
recebeu -> 5703
finalizou
```

Os valores variam porque os números utilizados no cálculo são gerados aleatoriamente.

Para executar o produtor-consumidor:

```
docker run --rm atividade_03 lua produto-consumidor.lua
```

#### Problemas encontrados e soluções

1. **Problema com `require`:** o `sequencial.lua` executava `principal()` mesmo quando era importado por `exemplo_main.lua`. O arquivo foi reorganizado para funcionar como módulo. 
2. **Execução sequencial do produtor-consumidor:** inicialmente o consumidor só era iniciado depois do término do produtor. A solução foi iniciar as duas tarefas antes dos `join()` e utilizar uma Linda para a comunicação. 

---

### Comunicação entre tarefas em processos diferentes no mesmo computador

Quando as tarefas pertencem a processos diferentes, elas não compartilham diretamente a mesma área de memória. Nesse caso, são necessários mecanismos de comunicação específicos, como pipes, filas de mensagens ou memória compartilhada.

**Essa comunicação não foi implementada neste trabalho.** A implementação realizada utilizou tarefas concorrentes dentro do mesmo processo, utilizando Lanes e Linda.

---

### Comunicação entre tarefas em processos diferentes em computadores diferentes

Quando as tarefas estão em computadores diferentes, a comunicação precisa ocorrer através de uma rede. Nesse caso, podem ser utilizados mecanismos como sockets e protocolos de comunicação de rede.

**Essa comunicação também não foi implementada neste trabalho.** O Docker utilizado na atividade serviu para criar o ambiente de execução e não representa, por si só, uma comunicação entre computadores diferentes.

---

## Considerações finais

Foi possível implementar e executar a comunicação entre tarefas no mesmo processo utilizando Lua, Lanes e Linda. Também foi possível executar os programas dentro de um container Docker configurado com Lua 5.4 e as dependências necessárias.

O trabalho permitiu compreender, na prática, a comunicação entre tarefas concorrentes e relacioná-la aos conceitos estudados na disciplina.
