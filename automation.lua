function TryRefuel()
    -- iterate over all slots and
    -- find valid fuel sources and
    -- refuel this bot
    
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then
            -- consume 5 items in the stack
            -- for optimizing
            local ok, err = turtle.refuel(5)
            if ok then
                print("[+] Refuel Successful!")
                local level = turtle.getFuelLevel()
                print("[*] Fuel Status...." .. level)
                return
            end
        end
    end
end

function NeedFuel()
    sleep(0.5)
    return turtle.getFuelLevel() == 0
end

-- customizable movement
-- instructions
local instructions = {
    { dir = "forward", dist = 11 },
    
    -- left/right
    -- must have dist=1
    -- { dir = "left", dist = 1 },
    -- { dir = "forward", dist = 3 },
    
    -- { dir = "left", dist = 1 },
    -- { dir = "forward", dist = 11 },

    --{ dir = "forward", dist=220 },
    --{ dir = "back", dist=220 },
}

-- detect if there is a block
-- in front of the bot
function PathBlocked()
    return turtle.detect()
end

-- dig block in front of bot
function MineAction()
    turtle.dig()
end

function IsPlaceable(item)
    if not item then
        print("[-] No Item Selected!")
        return
    end
    
    local itemName = item.name
    
    -- list of agreeable known
    -- placement blocks
    local placeable = {
        ["minecraft:dirt"] = true,
        ["minecraft:cobblestone"] = true,
        ["minecraft:andesite"] = true,
        ["minecraft:granite"] = true,
    }
    
    return item and placeable[itemName] == true
end

function TryPlaceBlock()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if IsPlaceable(item) then
            turtle.placeDown()
            return
        end 
    end
end

-- place blocks under the bot if
-- needed (bridge build)
function BuildBridge()
    -- check if there is a block
    -- below the bot
    if not turtle.detectDown() then
        TryPlaceBlock()
    end
end

-- perform movement knowing
-- we have fuel to make this
-- single move action
function TurtleMove(dir)
    if dir == "forward" then
        return turtle.forward()
    elseif dir == "backward" then
        turtle.back()
    elseif dir == "left" then
        turtle.turnLeft()
    elseif dir == "right" then
        turtle.turnRight()
    end
end

function FollowPath()
    for i, move in ipairs(instructions) do
        print("[*] Move " .. move.dir .. " " .. move.dist .. " blocks...")
        local steps = 0
        while steps < move.dist do
            if not NeedFuel() then
                -- attempt to place
                -- block under the bot
                BuildBridge()
                
                -- check if path blocked
                if not PathBlocked() then
                    -- move along clear
                    -- path
                    TurtleMove(move.dir)
                    steps = steps + 1
                else
                    MineAction()
                end
            else
                TryRefuel()
            end
        end
    end
end

function Main()
    print("[*] Starting Automation!")
    
    FollowPath()
    
    print("[*] Task Finished!")
end

Main()
