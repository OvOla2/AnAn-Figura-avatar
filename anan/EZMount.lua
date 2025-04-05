-- V1
-- Made by JimmyHelp
-- Contains GS' entityAPI:getLocalHVelocity() function from GSExtensions

local mounts = {}
local mountList = {}

local Entity = figuraMetatables.EntityAPI.__index
function Entity:getLocalHVelocity()
    return matrices.mat4()
    	:reset()
    	:rotateY(self:getRot(client.getFrameTime()).y)
    	:scale(vec(-1,1,-1))
    	:applyDir(self:getVelocity())
end

local vehicle
local currentMount = models:newPart("EmptyMount")
local forward
local up
local down
local still
local backward
local yawDiff = 0
local lastYaw = 0
local turnRight
local turnLeft
local rear
local sprint

function events.tick()
    vehicle = player:getVehicle()
    renderer:setRenderVehicle(true)
    for _,value in pairs(mountList) do
        if value == true then
            renderer:setRenderVehicle(false)
        end
    end
    if not vehicle then return end
    local velocity = vehicle:getLocalHVelocity()
    local yVel = velocity.y
    local bodyYaw = vehicle:isLiving() and vehicle:getBodyYaw()%360 or vehicle:getRot().y
    local yVelDet = vehicle:getType():find("minecart") and 0.1 or 0.001
    local sprinting = player:isSprinting()
    forward = velocity.z < 0 and ((yVel < yVelDet and yVel > -yVelDet) or yVel == 1) and not sprinting
    still = velocity:length() == 0
    backward = velocity.z > 0 and (yVel < 0.01 and yVel > -yVelDet)
    up = yVel > yVelDet and yVel ~= 1
    down = yVel < -yVelDet
    yawDiff = bodyYaw - lastYaw
    lastYaw = bodyYaw
    turnRight = (yawDiff > 1 and yawDiff < 200) or yawDiff < -200
    turnLeft = (yawDiff < -1 and yawDiff > -200) or yawDiff > 200
    rear = player:getVelocity().y > 0 and yVel == 0
    sprint = sprinting and not (down or up)
end

function events.world_render(delta)
    if not vehicle then return end
    currentMount:setPos(vehicle:getPos(delta)*16)
    if vehicle:isLiving()then
        currentMount:setRot(0,-vehicle:getBodyYaw(delta))
    else
        currentMount:setRot(0,-vehicle:getRot(delta).y)
    end
end

local function getMount(name)
    if not vehicle then return false end
    return vehicle:getType():find(name) or vehicle:getName():find(name)
end

local textGuide = '§f\nlocal textureTable  = {\n    iron = textures["reference"],\n    diamond = textures["reference"],\n    golden = textures["reference"],\n    leather = textures["reference"]\n}\n'..
                "§6You can find the texture reference of your textures using §flogTable(textures:getTextures())§c"
local repeti = "animations.bbmodelname.animationname"
local animGuide = '§f\nlocal animationTable  = {\n    still = '..repeti..',\n    forward = '..repeti..',\n    backward = '..repeti..',\n    up = '..repeti..',\n'..
                '    down = '..repeti..',\n    turnright = Animati'..repeti..',\n    turnleft = '..repeti..',\n    rear = '..repeti..',\n    gallop = '..repeti..'\n}\n'..
                "§6Unused animations can be deleted from the table.\nIf you don't know how to index an animation, check out the animation guide on the Figura wiki.§c"
local function errorCheck(id,model,head,saddle,bag,armor,text,pass,anim,name)
    local which = name == "object" and "fourth" or "ninth"
    local switch = name == "object" and "third" or "eighth"
    if type(id) ~= "string" then
        error("§aCustom Script Warning: §6The value provided for the first param (vehicle id/name) is not a string, it must be an entity's id or name as a string.§c",3)
    end

    if type(model) ~= "ModelPart" then
        error("§aCustom Script Warning: §6The value provided for the second param (vehicle part) is not a modelpart, check the spelling and modelpart path to confirm it's correct.§c",3)
    end

    if type(anim) ~= "table" and type(anim) ~= "nil" then
        error("§aCustom Script Warning: §6The value provided for the "..which.." param (animations) is not a table. It should be a table formatted like this:"..animGuide,3)
    elseif type(anim) ~= "nil" then
        for key,value in pairs(anim) do
            if type(key) ~= "string" then
                error("§aCustom Script Warning: §6The table provided for the "..which.." param (animations) is set up incorrectly, as the keys are not strings. The table should be formatted like this: "..
                animGuide,3)
            end
            if type(value) ~= "Animation" then
                error('§aCustom Script Warning: §6The value for the '..key..' animation is not an animation, check its spelling to confirm it\'s correct. The table should be formatted like this: '..
                animGuide,3)
            end
        end
    end

    local testing = {
        {head,"third","head"},
        {saddle,"fourth","saddle"},
        {bag,"fifth","bag"},
        {armor,"sixth","armor"},
        {pass,switch,"passenger"}
    }

    for _,value in pairs(testing) do
        if type(value[1]) == "table" then
            if next(value[1]) == nil then
                error("§aCustom Script Warning: §6The value provided for the "..value[2].." param ("..value[3].." part) is an empty table, check the spelling and modelpart paths of its contents to confirm it's correct.§c",3)
            else
                for num, part in pairs(value[1]) do
                    if type(part) ~= "ModelPart" then
                        error("§aCustom Script Warning: §6The value at position "..num.." of the "..value[2].." param's ("..value[3].." part) table is not a modelpart, check the spelling and modelpart path to confirm it's correct.§c",3)
                    end
                end
            end
        elseif type(value[1]) ~= "ModelPart" and type(value[1]) ~= "nil" then
            error("§aCustom Script Warning: §6The value provided for the "..value[2].." param ("..value[3].." part) is not a modelpart or a table, check the spelling and modelpart path to confirm it's correct.§c",3)
        end
    end

    if type(text) ~= "table" and (armor and type(text) == "nil") then
        error("§aCustom Script Warning: §6The value provided for the seventh param (armor textures) is not a table. It should be a table formatted like this:"..textGuide,3)
    elseif type(text) ~= "nil" then
        for key,value in pairs(text) do
            if type(key) ~= "string" then
                error('§aCustom Script Warning: §6The table provided for the seventh param (armor textures) is set up incorrectly, as the keys are not strings. The table should be formatted like this: '..
                textGuide,3)
            end
            if type(value) ~= "Texture" then
                error('§aCustom Script Warning: §6The value for the '..key..' armor is not a texture object. The table should be formatted like this: '..
                textGuide,3)
            end
        end
    end
end

---@param id string
---@param modelpart ModelPart | table
---@param headpart ModelPart | table
---@param saddlepart ModelPart | table
---@param bagpart ModelPart | table
---@param armorpart ModelPart | table
---@param armortext table
---@param passenger ModelPart | table
---@param anim table
function mounts:newLivingMount(id,modelpart,headpart,saddlepart,bagpart,armorpart,armortext,passenger,anim)
    errorCheck(id,modelpart,headpart,saddlepart,bagpart,armorpart,armortext,passenger,anim)
    modelpart:setParentType("World"):setVisible(false):scale(-1,1,-1)
    local saddles = type(saddlepart)=="table" and saddlepart or {saddlepart}
    local bags = type(bagpart) and bagpart or {bagpart}
    local head = type(headpart)=="table" and headpart or {headpart}
    local armor = type(armorpart)=="table" and armorpart or {armorpart}
    local pass = type(passenger)=="table" and passenger or {passenger}
    mountList[id] = false
    function events.tick()
        if not vehicle then modelpart:setVisible(false) return end
        if not getMount(id) then mountList[id] = false return end
        currentMount = modelpart
        modelpart:setVisible(getMount(id) or false):setLight(world.getBlockLightLevel(vehicle:getPos()),world.getSkyLightLevel(vehicle:getPos()))
        mountList[id] = true
        for _,value in pairs(saddles) do
            value:setVisible(vehicle:getControllingPassenger()==player)
        end
        for _,value in pairs(bags) do
            value:setVisible(vehicle:getNbt().Items or false)
        end
        for _,value in pairs(armor) do
            value:setVisible(vehicle:getNbt().ArmorItems[3].id or false)
            if vehicle:getNbt().ArmorItems[3].id ~= nil and armortext then
                value:setPrimaryTexture("Custom",armortext[vehicle:getNbt().ArmorItems[3].id:gsub(".-:", ""):match("^[^_]+")])
                if vehicle:getNbt().ArmorItems[3].tag then
                    value:setColor(vectors.intToRGB(player:getVehicle():getNbt().ArmorItems[3].tag.display.color))
                else
                    value:setColor(vehicle:getNbt().ArmorItems[3].id:gsub(".-:", ""):match("^[^_]+")=="leather" and vec(79/255,50/255,14/255) or vec(1,1,1))
                end
            end
        end
        for _,value in pairs(pass) do
            value:setVisible(#vehicle:getPassengers() > 1)
        end
        if anim then
            if anim.forward then anim.forward:setPlaying(forward) end
            if anim.backward then anim.backward:setPlaying(backward) end
            if anim.still then anim.still:setPlaying(still) end
            if anim.up then anim.up:setPlaying(up or (down and not anim.down)) end
            if anim.down then anim.down:setPlaying(down) end
            if anim.turnright then anim.turnright:setPlaying(turnRight) end
            if anim.turnleft then anim.turnleft:setPlaying(turnLeft) end
            if anim.rear then if rear then anim.rear:play() end end
            if anim.gallop then anim.gallop:setPlaying(sprint) end
        end
    end
    function events.render(delta)
        if not vehicle then return end
        if not getMount(id) or vehicle:getControllingPassenger() == nil then return end
        for _,value in pairs(head) do
            value:setOffsetRot(math.clamp(-player:getRot(delta).x,-40,30))
        end
    end
end

---@param id string
---@param modelpart ModelPart | table
---@param passenger ModelPart | table
---@param anim table
function mounts:newObjectMount(id,modelpart,passenger,anim)
    errorCheck(id,modelpart,_,_,_,_,_,passenger,anim,"object")
    modelpart:setParentType("World"):setVisible(false):scale(-1,1,-1)
    mountList[id] = false
    local pass = type(passenger)=="table" and passenger or {passenger}
    function events.tick()
        if not vehicle then modelpart:setVisible(false) return end
        if not getMount(id) then mountList[id] = false return end
        currentMount = modelpart
        modelpart:setVisible(getMount(id) or false):setLight(world.getBlockLightLevel(vehicle:getPos()),world.getSkyLightLevel(vehicle:getPos()))
        mountList[id] = true
        for _,value in pairs(pass) do
            value:setVisible(#vehicle:getPassengers() > 1)
        end
        if anim then
            if anim.forward then anim.forward:setPlaying(forward) end
            if anim.backward then anim.backward:setPlaying(backward) end
            if anim.still then anim.still:setPlaying(still) end
            if anim.up then anim.up:setPlaying(up or (down and not anim.down)) end
            if anim.down then anim.down:setPlaying(down) end
            if anim.turnright then anim.turnright:setPlaying(turnRight) end
            if anim.turnleft then anim.turnleft:setPlaying(turnLeft) end
            if anim.rear then if rear then anim.rear:play() end end
            if anim.gallop then anim.gallop:setPlaying(sprint) end
        end
    end
end

return mounts