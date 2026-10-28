print ("Produtor iniciado!")

local pipe = io.popen("lua pipes/consumidor.lua", "w")

if pipe then
    pipe:write("Hello World!")
    pipe:close
else
    print ("Erro ao iniciar o consumidor!")
end

print ("Produtor finalizado!")