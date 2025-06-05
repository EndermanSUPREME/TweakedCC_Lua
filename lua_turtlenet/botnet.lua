local INFO = "[*] "
local OK = "[+] "
local ERR = "[-] "

-- list of bots we can connect to
local Bots = {
    "yapper"
}
-- list of bots with speaker components
local LoudBots = {
    "yapper"
}
-- global connected bots reference
local ConnectedBots = {}


function PrintInfo(msg)
    print(INFO .. msg)
end

function PrintErr(msg)
    print(ERR .. msg)
end

function PrintOk(msg)
    print(OK .. msg)
end

function InitializeHost()
    -- locate wireless modem on this device
    local online = peripheral.find("modem", function(_, m)
        return m.isWireless and m.isWireless()
    end)
    
    
    if online then
        PrintOk("Host is Online!")
        return true
    else
        PrintErr("Modem Not Found!")
        return false
    end
end

function FindBots()
    PrintInfo("Checking Remote Connections")
    
    -- clear connections list for
    -- updating botnet conn. status
    ConnectedBots = {}
    
    -- estab connections to all bots
    -- within the list
    for i,name in ipairs(Bots) do
        local id = rednet.lookup("EnderNet", name)
        
        if id then
            PrintOk(name .. "....CONNECTED")
            table.insert(ConnectedBots, id)
        else
            PrintErr(name .. "....DISCONNECTED")
        end
    end
end

-- query bots for status and display
-- returned fuel level with their name
function ShowBotsInfo()
    print("-----------------------")
    print("+++++++FUEL_LEVEL++++++")
    for i, id in ipairs(ConnectedBots) do
        rednet.send(id, "status")
        local ack, msg, proto = rednet.receive("bot_status", 5)

        if not ack then
            PrintErr("No Ack from Bot-ID: " .. id)
        else
            local data = textutils.unserialiseJSON(msg)
            PrintInfo(data.name .. "....." .. data.fuel)
        end
    end
    print("-----------------------")
end

function ShutdownBots()
    for i, id in ipairs(ConnectedBots) do
        rednet.send(id, "close_turtle")
    end
end

function BattleCry()
    PrintInfo("Engaging Battle Cry!")
    for i, name in ipairs(LoudBots) do
        local id = rednet.lookup("EnderNet", name)
        
        -- Send Audio to bots
        if id then
            local fileName = "audio/sound.dfpwm"
            local handle = fs.open(fileName, "rb")
            local chunkSize = 16384

            -- ensure file can be read
            if not handle then
                PrintErr("Error Reading from " .. fileName)
                return
            end
            
            -- send signal to bot
            rednet.send(id, "battle_cry")
            local ack,msg = rednet.receive(nil,5)
            if not ack then
                PrintErr("No Ack Recieved")
            else
                -- ensure file transmission            
                while true do
                    local data = handle.read(chunkSize)
                    if not data then
                        break
                    end
                
                    rednet.send(id, data, "audio_chunk")
                end
            
                rednet.send(id, "EOF", "audio_chunk")
                handle.close()
                PrintOk("Audio Sent Successfully!")
            end
        else
            PrintErr("No Connection to..." .. name)
        end
    end
end

function RefuelBots()
    for i, id in ipairs(ConnectedBots) do
        rednet.send(id, "refuel")
    end
end

local helpText = [[
help...........show this page
exit...........close botnet
battle_cry.....scare the enemy
status.........check botnet status
refuel.........refuel active bots
]]

-- controller func
function Handler()
    print("==== BOTNET HANDLER ====")
    while true do
        local cmd = read()
        if cmd == "exit" then
            ShutdownBots()
            break;
        end
        
        if cmd == "battle_cry" then
            BattleCry()
        elseif cmd == "help" then
            print(helpText)
        elseif cmd == "status" then
            FindBots()
            ShowBotsInfo()
        elseif cmd == "refuel" then
            RefuelBots()
        else
            PrintErr(cmd .. " not a valid cmdlet")
        end
    end
end

function BotNet()
    -- Initialize Remote Connections
    FindBots()
    -- Allow controller to manipulate
    -- remote bots (64 bc range)
    Handler()
end

function main()
    local ready = InitializeHost()

    if ready then
        PrintInfo("Starting up Bot-Net")
        BotNet()        
    else
        PrintErr("Host is not Ready!")
    end
end

main()
PrintInfo("Bot-Net Closed!")
