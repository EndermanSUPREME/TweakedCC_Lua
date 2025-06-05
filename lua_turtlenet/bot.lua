rednet.open("left")
local turtleName = "yapper"
rednet.host("EnderNet", turtleName)

local fuelAlert = false

function BattleCry()
    local audFile = "battlecry.dfpwm"
    local handle = fs.open(audFile, "wb")
    
    -- recv byte chunks and
    -- write to file
    while true do
        local senderId, data, protocol = rednet.receive("audio_chunk", 5)
        if data == "EOF" then
            break
        end
        
        handle.write(data)
    end
    
    handle.close()
    print("Battle Cry Audio Installed!")

    -- play audio file
    local speaker = peripheral.find("speaker")
    local dfpwm = require("cc.audio.dfpwm")
    local decoder = dfpwm.make_decoder()
    
    local audHandle = fs.open(audFile, "rb")
    print("Sounding Battle Cry!")
    
    while true do
        local chunk = audHandle.read(16*1024)
        if not chunk then
            break
        end
        
        local decoded = decoder(chunk)
        while not speaker.playAudio(decoded) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    audHandle.close()
end

function GetStatus()
    local level = turtle.getFuelLevel()
    return level
end

-- function that runs forever
function ListenForCommands()
    while true do
        local senderId, recvMsg = rednet.receive()
        local msg = tostring(recvMsg)
    
        if msg == "close_turtle" then
            print("Host Disconnected!")
        elseif msg == "refuel" then
            if fuelAlert then
                SelfRefuel()
            end
        elseif msg == "status" then
            -- send fuel level
            local level = GetStatus()
            print("Host Querying Status...")
            print("|____Fuel: " .. level)
            
            local data = {
                name = turtleName,
                fuel = level
            }
            local jsonData = textutils.serialiseJSON(data)
            rednet.send(senderId, jsonData, "bot_status")
        elseif msg == "battle_cry" then
            rednet.send(senderId, "ack")
            BattleCry() 
        end
    end
end

function NeedFuel()
    local level = turtle.getFuelLevel()
    
    if level < 50 then
        if not fuelAlert then
            fuelAlert = true
            print("This bot needs fuel!")
            print(turtleName .. " will remain stationary until refueled!")
        end
        
        return true
    end
    
    fuelAlert = false
    return false
end

function SelfRefuel()
    local ok, err = turtle.refuel()
    
    if ok then
        local level = turtle.getFuelLevel()
        print("Refuel Successful!")
        print("Fuel Level: " .. level)
    else
        print("Error Refueling..." .. err)
    end
end

function AttackEnemy()
end

function MovementHandler()
    while true do
        if not NeedFuel() then
            -- attempt to roam poorly
            
            -- try to move fwd and
            -- if move failed rotate
            -- right and try again
            local moveFwd = turtle.forward()
            if not moveFwd then
                turtle.turnRight()
            end
        end
        
        -- give code breath
        sleep(0.1)
    end
end

function main()
    print("Bot Starting Up...")
    -- run two functions in parallel
    parallel.waitForAll(
        ListenForCommands,
        MovementHandler
    )
    
    -- section executes after both
    -- functions end
    print("Bot Shutting Down...")
end

main()
