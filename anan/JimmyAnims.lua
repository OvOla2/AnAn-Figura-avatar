-- + Made by Jimmy Hellp
-- + V6.1 for 0.1.0 and above
-- + Thank you GrandpaScout for helping with the library stuff!
-- + Automatically compatible with GSAnimBlend for automatic smooth animation blending
-- + Also includes Manuel's Run Later script

local animsList = {
    -- Exclusive Animations
    idle="idling",
    walk="walking",
    walkback="walking backwards",
    jumpup="jumping up caused via the jump key",
    jumpdown="jumping down after a jump up",
    fall="falling after a while",

    sprint = "sprinting",
    sprintjumpup="sprinting and jumping up caused via the jump key",
    sprintjumpdown="sprinting and jumping down after a jump up",

    crouch = "crouching",
    crouchwalk = "crouching and walking",
    crouchwalkback = "crouching and walking backwards",
    crouchjumpup = "crouching and jumping up caused via the jump key",
    crouchjumpdown = "crouching and jumping down after a jump up",

    elytra = "elytra flying",
    elytradown = "flying down/diving while elytra flying",

    trident = "riptide trident lunging",
    sleep = "sleeping",
    swim = "while swimming",

    sit = "while in any vehicle or modded sitting",
    sitmove = "while in any vehicle and moving",
    sitmoveback = "while in any vehicle and moving backwards",
    sitjumpup = "while in any vehicle and jumping up",
    sitjumpdown = "while in any vehicle and jumping down",
    sitpass = "while in any vehicle as a passenger",

    crawl = "crawling and moving",
    crawlstill = "crawling and still",

    fly = "creative flying",
    flywalk = "flying and moving",
    flywalkback = "flying and moving backwards",
    flysprint  = "flying and sprinting",
    flyup = "flying and going up",
    flydown = "flying and going down",

    climb = "climbing a ladder",
    climbstill = "not moving on a ladder without crouching (hitting a ceiling usually)",
    climbdown = "going down a ladder",
    climbcrouch = "crouching on a ladder",
    climbcrouchwalk = "crouching on a ladder and moving",

    water = "being in water without swimming",
    waterwalk = "in water and moving",
    waterwalkback = "in water and moving backwards",
    waterup = "in water and going up",
    waterdown = "in water and going down",
    watercrouch = "in water and crouching",
    watercrouchwalk = "in water and crouching and walking",
    watercrouchwalkback = "in water and crouching and walking backwards",
    watercrouchdown = "in water and crouching and going down",
    watercrouchup = "in water and crouching and going up. only possible in bubble columns",

    hurt = "MUST BE IN PLAY ONCE LOOP MODE. when hurt",
    death = "dying",

    -- Inclusive Animations:

    attackR = "MUST BE IN PLAY ONCE LOOP MODE. attacking with the right hand",
    attackL = "MUST BE IN PLAY ONCE LOOP MODE. attacking with the left hand",
    mineR = "MUST BE IN PLAY ONCE LOOP MODE. mining with the right hand",
    mineL = "MUST BE IN PLAY ONCE LOOP MODE. mining with the left hand",

    eatR = "eating from the right hand",
    eatL = "eating from the left hand",
    drinkR = "drinking from the right hand",
    drinkL = "drinking from the left hand",
    blockR = "blocking from the right hand",
    blockL = "blocking from the left hand",
    bowR = "drawing back a bow from the right hand",
    bowL = "drawing back a bow from the left hand",
    loadR = "loading a crossbow from the right hand",
    loadL = "loading a crossbow from the left hand",
    crossbowR = "holding a loaded crossbow in the right hand",
    crossbowL = "holding a loaded crossbow in the left hand",
    spearR = "holding up a trident in the right hand",
    spearL = "holding up a trident in the left hand",
    spyglassR = "holding up a spyglass from the right hand",
    spyglassL = "holding up a spyglass from the left hand",
    hornR = "using a horn in the right hand",
    hornL = "using a horn in the left hand",
    brushR = "using a brush in the right hand",
    brushL = "using a brush in the left hand",

    holdR = "holding an item in the right hand",
    holdL = "holding an item in the left hand",
}

------------------------------------------------------------------------------------------------------------------------

local function errors(paths,dismiss)
    assert(
        next(paths),
        "§aCustom Script Warning: §6No blockbench models were found, or the blockbench model found contained no animations. \n" .." Check that there are no typos in the given bbmodel name, or that the bbmodel has animations by using this line of code at the top of your script: \n"
        .."§f logTable(animations.BBMODEL_NAME_HERE) \n ".."§6If this returns nil your bbmodel name is wrong or it has no animations. You can use \n".."§f logTable(models:getChildren()) \n".."§6 to get the name of every bbmodel in your avatar.§c"
    )

    for _, path in pairs(paths) do
        for _, anim in pairs(path) do
            if anim:getName():find("%.") and not dismiss then
                error(
                    "§aCustom Script Warning: §6The animation §b'"..anim:getName().."'§6 has a period ( . ) in its name, the handler can't use that animation and it must be renamed to fit the handler's accepted animation names. \n" ..
                " If the animation isn't meant for the handler, you can dismiss this error by adding §fanims.dismiss = true§6 after the require but before setting the bbmodel.§c")
            end
        end
    end
end

local setAllOnVar = true
local setIncluOnVar = true
local setExcluOnVar = true

local allAnims = {}
local excluAnims = {}
local incluAnims = {}
local animsTable= {
    allVar = false,
    excluVar = false,
    incluVar = false
}
local excluState
local incluState

local holdRanims = {}
local holdLanims = {}
local attackRanims = {}
local attackLanims = {}
local mineRanims = {}
local mineLanims = {}

local hasJumped = false
local oneJump = false

local hitBlock
local rightResult
local leftResult

local cFlying = false
local oldcFlying = cFlying
local flying = false
local updateTimer = 0
local flyinit = false
local distinit = false

local dist = 4.5
local oldDist = dist
local reach = 4.5

local yvel
local cooldown

local grounded
local oldgrounded

local fallVel = -0.6

-- wait code from Manuel
local timers = {}

local function wait(ticks,next)
    table.insert(timers,{t=world.getTime()+ticks,n=next})
end

events.TICK:register(function()
    for key,timer in pairs(timers) do
        if world.getTime() >= timer.t then
            timer.n()
            timers[key] = nil
        end
    end
end)
--

local bbmodels = {} -- don't put things in here

function pings.JimmyAnims_cFly(x)
    flying = x
end

function pings.JimmyAnims_Distance(x)
    reach = x
end

function pings.JimmyAnims_Update(fly,dis)
    flying = fly
    reach = dis
end

local prev
local function JimmyAnims_Swing(anim)
    -- test how this works with multiple bbmodels
    for _,path in pairs(bbmodels) do
        if path[prev] then path[prev]:stop() end
        if path[anim] then path[anim]:play() end
        prev = anim
    end
end

local function anims()
    for _, value in ipairs(allAnims) do
        if value:isPlaying() then
            animsTable.allVar = true
            break
        else
            animsTable.allVar = false or not setAllOnVar
        end
    end
    if next(allAnims) == nil then
        animsTable.allVar = not setAllOnVar
    end

    for _, value in ipairs(excluAnims) do
        if value:isPlaying() then
            animsTable.excluVar = true
            break
        else
            animsTable.excluVar = false or not setExcluOnVar
        end
    end
    if next(excluAnims) == nil then
        animsTable.excluVar = not setExcluOnVar
    end

    for _, value in ipairs(incluAnims) do
        if value:isPlaying() then
            animsTable.incluVar = true
            break
        else
            animsTable.incluVar = false or not setIncluOnVar
        end
    end
    if next(incluAnims) == nil then
        animsTable.incluVar = not setIncluOnVar
    end

    excluState = not animsTable.allVar and not animsTable.excluVar
    incluState = not animsTable.allVar and not animsTable.incluVar

    if host:isHost() then
        if flyinit and not distinit then
            cFlying = host:isFlying()
            if cFlying ~= oldcFlying then
                pings.JimmyAnims_cFly(cFlying)
            end
            oldcFlying = cFlying

            updateTimer = updateTimer + 1
            if updateTimer % 200 == 0 then
                pings.JimmyAnims_cFly(cFlying)
            end
        elseif distinit and not flyinit then
            dist = host:getReachDistance()
            if dist ~= oldDist then
                pings.JimmyAnims_Distance(dist)
            end
            oldDist = dist

            updateTimer = updateTimer + 1
            if updateTimer % 200 == 0 then
                pings.JimmyAnims_Distance(dist)
            end
        elseif distinit and flyinit then
            cFlying = host:isFlying()
            if cFlying ~= oldcFlying then
                pings.JimmyAnims_cFly(cFlying)
            end
            oldcFlying = cFlying

            dist = host:getReachDistance()
            if dist ~= oldDist then
                pings.JimmyAnims_Distance(dist)
            end
            oldDist = dist

            updateTimer = updateTimer + 1
            if updateTimer % 200 == 0 then
                pings.JimmyAnims_Update(cFlying,dist)
            end
        end
    end

    local pose = player:getPose()
    local velocity = player:getVelocity()
    local moving = velocity.xz:length() > 0.01
    local sprinty = player:isSprinting()
    local vehicle = player:getVehicle()
    local sitting = vehicle ~= nil or pose == "SITTING" -- if you're reading this code and see this, "SITTING" isn't a vanilla pose, this is for mods
    local passenger = vehicle and vehicle:getControllingPassenger() ~= player
    local creativeFlying = flying and not sitting
    local standing = pose == "STANDING"
    local crouching = pose == "CROUCHING" and not creativeFlying
    local gliding = pose == "FALL_FLYING"
    local spin = pose == "SPIN_ATTACK"
    local sleeping = pose == "SLEEPING"
    local swimming = pose == "SWIMMING"
    local inWater = player:isUnderwater() and not sitting
    local inLiquid = player:isInWater() or player:isInLava()
    local liquidSwim = swimming and inLiquid
    local crawling = swimming and not inLiquid

    -- hasJumped stuff
    
    yvel = velocity.y
    local hover = yvel < .01 and yvel > -.01
    local goingUp = yvel > .01
    local goingDown =  yvel < -.01
    local falling = yvel < fallVel
    local playerGround = world.getBlockState(player:getPos():add(0,-.1,0))
    local vehicleGround = sitting and world.getBlockState(vehicle:getPos():add(0,-.1,0))
    oldgrounded = grounded
    grounded = playerGround:isSolidBlock() or player:isOnGround() or (sitting and vehicleGround:isSolidBlock() or sitting and vehicle:isOnGround())

    local pv = velocity:mul(1, 0, 1):normalize()
    local pl = models:partToWorldMatrix():applyDir(0,0,-1):mul(1, 0, 1):normalize()
    local fwd = pv:dot(pl)
    local backwards = fwd < -.8
    --local sideways = pv:cross(pl)
    --local right = sideways.y > .6
    --local left = sideways.y < -.6

    -- canJump stuff
    local webbed = world.getBlockState(player:getPos()).id == "minecraft:cobweb"
    local ladder = player:isClimbing() and not grounded and not flying

    local canJump = not (inLiquid or webbed or grounded)

    local hp = player:getHealth() + player:getAbsorptionAmount()

    if oldgrounded ~= grounded and not grounded and yvel > 0 then
        cooldown = true
        wait(10,function() cooldown = false end)
    end

    if (oldgrounded ~= grounded and not grounded and yvel > 0) and canJump then hasJumped = true end
    if (grounded and (yvel <= 0 and yvel > -0.1)) or (gliding or inLiquid) then hasJumped = false end

    local neverJump = not (gliding or spin or sleeping or swimming or ladder)
    local jumpingUp = hasJumped and goingUp and neverJump
    local jumpingDown = hasJumped and goingDown and not falling and neverJump or (cooldown and not jumpingUp)
    local isJumping = jumpingUp or jumpingDown or falling
    local sprinting = sprinty and standing and not inLiquid and not sitting
    local walking = moving and not sprinting and not isJumping and not sitting
    local forward = walking and not backwards
    local backward = walking and backwards

    -- we be holding items tho
    local handedness = player:isLeftHanded()
    local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
    local leftActive = not handedness and "OFF_HAND" or "MAIN_HAND"
    local activeness = player:getActiveHand()
    local using = player:isUsingItem()
    local rightSwing = player:getSwingArm() == rightActive and not sleeping
    local leftSwing = player:getSwingArm() == leftActive and not sleeping
    local targetEntity = type(player:getTargetedEntity()) == "PlayerAPI" or type(player:getTargetedEntity()) == "LivingEntityAPI"
    local targetBlock = player:getTargetedBlock(true, reach)
    local swingTime = player:getSwingTime() == 1
    local blockSuccess, blockResult = pcall(targetBlock.getTextures, targetBlock)
    if blockSuccess then hitBlock = not (next(blockResult) == nil) else hitBlock = true end
    local rightMine = rightSwing and hitBlock and not targetEntity
    local leftMine = leftSwing and hitBlock and not targetEntity
    local rightAttack = rightSwing and (not hitBlock or targetEntity)
    local leftAttack = leftSwing and (not hitBlock or targetEntity)
    local rightItem = player:getHeldItem(handedness)
    local leftItem = player:getHeldItem(not handedness)
    local rightSuccess = pcall(rightItem.getUseAction,rightItem)
    if rightSuccess then rightResult = rightItem:getUseAction() else rightResult = "NONE" end
    local usingR = activeness == rightActive and rightResult
    local leftSuccess = pcall(leftItem.getUseAction,leftItem)
    if leftSuccess then leftResult = leftItem:getUseAction() else leftResult = "NONE" end
    local usingL = activeness == leftActive and leftResult

    local crossR = rightItem.tag and rightItem.tag["Charged"] == 1
    local crossL = leftItem.tag and leftItem.tag["Charged"] == 1

    local drinkRState = using and usingR == "DRINK"
    local drinkLState = using and usingL == "DRINK"

    local eatRState = using and usingR == "EAT"
    local eatLState = using and usingL == "EAT"

    local blockRState = using and usingR == "BLOCK"
    local blockLState = using and usingL == "BLOCK"

    local bowRState = using and usingR == "BOW"
    local bowLState = using and usingL == "BOW"

    local spearRState = using and usingR == "SPEAR"
    local spearLState = using and usingL == "SPEAR"

    local spyglassRState = using and usingR == "SPYGLASS"
    local spyglassLState = using and usingL == "SPYGLASS"

    local hornRState = using and usingR == "TOOT_HORN"
    local hornLState = using and usingL == "TOOT_HORN"

    local loadRState = using and usingR == "CROSSBOW"
    local loadLState = using and usingL == "CROSSBOW"

    local brushRState = using and usingR == "BRUSH"
    local brushLState = using and usingL == "BRUSH"

    local exclude = not (using or crossR or crossL)
    local rightHoldState = rightItem.id ~= "minecraft:air" and exclude
    local leftHoldState = leftItem.id ~= "minecraft:air" and exclude

    -- anim states
    for _, path in pairs(bbmodels) do

        local flywalkbackState = creativeFlying and backward and (not (goingDown or goingUp))
        local flysprintState = creativeFlying and sprinting and not isJumping and (not (goingDown or goingUp))
        local flyupState = creativeFlying and goingUp
        local flydownState = creativeFlying and goingDown
        local flywalkState = creativeFlying and forward and (not (goingDown or goingUp)) and not sleeping or (flysprintState and not path.flysprint) or (flywalkbackState and not path.flywalkback)
        or (flyupState and not path.flyup) or (flydownState and not path.flydown)
        local flyState = creativeFlying and not sprinting and not moving and standing and not isJumping and (not (goingDown or goingUp)) and not sleeping or (flywalkState and not path.flywalk) 

        local watercrouchwalkbackState = inWater and crouching and backward and not goingDown
        local watercrouchwalkState = inWater and crouching and forward and not (goingDown or goingUp) or (watercrouchwalkbackState and not path.watercrouchwalkback)
        local watercrouchupState = inWater and crouching and goingUp
        local watercrouchdownState = inWater and crouching and goingDown or (watercrouchupState and not path.watercrouchup)
        local watercrouchState = inWater and crouching and not moving and not (goingDown or goingUp) or (watercrouchdownState and not path.watercrouchdown) or (watercrouchwalkState and not path.watercrouchwalk)

        local waterdownState = inWater and goingDown and not falling and standing and not creativeFlying
        local waterupState = inWater and goingUp and standing and not creativeFlying
        local waterwalkbackState = inWater and backward and hover and standing and not creativeFlying
        local waterwalkState = inWater and forward and hover and standing and not creativeFlying or (waterwalkbackState and not path.waterwalkback) or (waterdownState and not path.waterdown)
        or (waterupState and not path.waterup)
        local waterState = inWater and not moving and standing and hover and not creativeFlying or (waterwalkState and not path.waterwalk)
        
        local crawlstillState = crawling and not moving
        local crawlState = crawling and moving or (crawlstillState and not path.crawlstill)

        local swimState = liquidSwim or (crawlState and not path.crawl)

        local elytradownState = gliding and goingDown
        local elytraState = gliding and not goingDown or (elytradownState and not path.elytradown)

        local sitpassState = passenger and standing
        local sitjumpdownState = sitting and not passenger and standing and (jumpingDown or falling)
        local sitjumpupState = sitting and not passenger and jumpingUp and standing or (sitjumpdownState and not path.sitjumpdown)
        local sitmovebackState = sitting and not passenger and not isJumping and backwards and standing
        local sitmoveState = velocity:length() > 0 and not passenger and not backwards and standing and sitting and not isJumping or (sitmovebackState and not path.sitmoveback) or (sitjumpupState and not path.sitjumpup)
        local sitState = sitting and not passenger and velocity:length() == 0 and not isJumping and standing or (sitmoveState and not path.sitmove) or (sitpassState and not path.sitpass)

        local tridentState = spin
        local sleepState = sleeping

        local climbcrouchwalkState = ladder and crouching and (moving or yvel ~= 0)
        local climbcrouchState = ladder and crouching and hover and not moving or (climbcrouchwalkState and not path.climbcrouchwalk)
        local climbdownState = ladder and goingDown
        local climbstillState = ladder and not crouching and hover
        local climbState = ladder and goingUp and not crouching or (climbdownState and not path.climbdown) or (climbstillState and not path.climbstill)

        local crouchjumpdownState = crouching and jumpingDown and not ladder and not inWater
        local crouchjumpupState = crouching and jumpingUp and not ladder or (not oneJump and (crouchjumpdownState and not path.crouchjumpdown))
        local crouchwalkbackState = backward and crouching and not ladder and not inWater or (watercrouchwalkbackState and not path.watercrouchwalkback and not path.watercrouchwalk and not path.watercrouch)
        local crouchwalkState = forward and crouching and not ladder and not inWater or (crouchwalkbackState and not path.crouchwalkback) or (not oneJump and (crouchjumpupState and not path.crouchjumpup)) or ((watercrouchwalkState and not watercrouchwalkbackState) and not path.watercrouchwalk and not path.watercrouch)
        local crouchState = crouching and not walking and not isJumping and not ladder and not inWater and not cooldown or (crouchwalkState and not path.crouchwalk) or (climbcrouchState and not path.climbcrouch) or ((watercrouchState and not watercrouchwalkState) and not path.watercrouch)
        
        local fallState = falling and not gliding and not creativeFlying and not sitting
        
        local sprintjumpdownState = jumpingDown and sprinting and not creativeFlying and not ladder
        local sprintjumpupState = jumpingUp and sprinting and not creativeFlying and not ladder or (not oneJump and (sprintjumpdownState and not path.sprintjumpdown))
        local jumpdownState = jumpingDown and not sprinting and not crouching and not sitting and not gliding and not creativeFlying and not spin and not inWater or (fallState and not path.fall) or (oneJump and (sprintjumpdownState and not path.sprintjumpdown)) or (oneJump and (crouchjumpdownState and not path.crouchjumpdown))
        local jumpupState = jumpingUp and not sprinting and not crouching and not sitting and not creativeFlying and not inWater or (jumpdownState and not path.jumpdown) or (tridentState and not path.trident) or (oneJump and (sprintjumpupState and not path.sprintjumpup)) or (oneJump and (crouchjumpupState and not path.crouchjumpup))

        local sprintState = sprinting and not isJumping and not creativeFlying and not ladder and not cooldown or (not oneJump and (sprintjumpupState and not path.sprintjumpup))
        local walkbackState = backward and standing and not creativeFlying and not ladder and not inWater or (flywalkbackState and not path.flywalkback and not path.flywalk and not path.fly)
        local walkState = forward and standing and not creativeFlying and not ladder and not inWater and not cooldown or (walkbackState and not path.walkback) or (sprintState and not path.sprint) or (climbState and not path.climb) 
        or (swimState and not path.swim) or (elytraState and not path.elytra) or (jumpupState and not path.jumpup) or (waterwalkState and (not path.waterwalk and not path.water)) or ((flywalkState and not flywalkbackState) and not path.flywalk and not path.fly)
        or (crouchwalkState and not path.crouch)
        local idleState = not moving and not sprinting and standing and not isJumping and not sitting and not creativeFlying and not ladder and not inWater or (sleepState and not path.sleep) or (sitState and not path.sit)
        or ((waterState and not waterwalkState) and not path.water) or ((flyState and not flywalkState) and not path.fly) or ((crouchState and not crouchwalkState) and not path.crouch)

        local deadState = hp <= 0

        if path.death then path.death:playing(excluState and deadState) end

    -- anim play testing
        if path.hurt and player:getNbt().HurtTime == 9 then
            path.hurt:restart()
        end

        if path.idle then path.idle:playing(excluState and idleState) end
        if path.walk then path.walk:playing(excluState and walkState) end
        if path.walkback then path.walkback:playing(excluState and walkbackState) end
        if path.sprint then path.sprint:playing(excluState and sprintState) end
        if path.sprintjumpup then path.sprintjumpup:playing(excluState and sprintjumpupState) end
        if path.sprintjumpdown then path.sprintjumpdown:playing(excluState and sprintjumpdownState) end
        if path.crouch then path.crouch:playing(excluState and crouchState) end
        if path.crouchwalk then path.crouchwalk:playing(excluState and crouchwalkState) end
        if path.crouchwalkback then path.crouchwalkback:playing(excluState and crouchwalkbackState) end
        if path.crouchjumpup then path.crouchjumpup:playing(excluState and crouchjumpupState) end
        if path.crouchjumpdown then path.crouchjumpdown:playing(excluState and crouchjumpdownState) end
        if path.jumpup then path.jumpup:playing(excluState and jumpupState) end
        if path.jumpdown then path.jumpdown:playing(excluState and jumpdownState) end
        if path.fall then path.fall:playing(excluState and fallState) end
        if path.elytra then path.elytra:playing(excluState and elytraState) end
        if path.elytradown then path.elytradown:playing(excluState and elytradownState) end
        if path.trident then path.trident:playing(excluState and tridentState) end
        if path.sleep then path.sleep:playing(excluState and sleepState) end
        if path.swim then path.swim:playing(excluState and swimState) end
        if path.sit then path.sit:playing(excluState and sitState) end
        if path.sitmove then path.sitmove:playing(excluState and sitmoveState) end
        if path.sitmoveback then path.sitmoveback:playing(excluState and sitmovebackState) end
        if path.sitjumpup then path.sitjumpup:playing(excluState and sitjumpupState) end
        if path.sitjumpdown then path.sitjumpdown:playing(excluState and sitjumpdownState) end
        if path.sitpass then path.sitpass:playing(excluState and sitpassState) end
        if path.crawl then path.crawl:playing(excluState and crawlState) end
        if path.crawlstill then path.crawlstill:playing(excluState and crawlstillState) end
        if path.fly then path.fly:playing(excluState and flyState) end
        if path.flywalk then path.flywalk:playing(excluState and flywalkState) end
        if path.flywalkback then path.flywalkback:playing(excluState and flywalkbackState) end
        if path.flysprint then path.flysprint:playing(excluState and flysprintState) end
        if path.flyup then path.flyup:playing(excluState and flyupState) end
        if path.flydown then path.flydown:playing(excluState and flydownState) end
        if path.climb then path.climb:playing(excluState and climbState) end
        if path.climbstill then path.climbstill:playing(excluState and climbstillState) end
        if path.climbdown then path.climbdown:playing(excluState and climbdownState) end
        if path.climbcrouch then path.climbcrouch:playing(excluState and climbcrouchState) end
        if path.climbcrouchwalk then path.climbcrouchwalk:playing(excluState and climbcrouchwalkState) end
        if path.water then path.water:playing(excluState and waterState) end
        if path.waterwalk then path.waterwalk:playing(excluState and waterwalkState) end
        if path.waterwalkback then path.waterwalkback:playing(excluState and waterwalkbackState) end
        if path.waterup then path.waterup:playing(excluState and waterupState) end
        if path.waterdown then path.waterdown:playing(excluState and waterdownState) end
        if path.watercrouch then path.watercrouch:playing(excluState and watercrouchState) end
        if path.watercrouchwalk then path.watercrouchwalk:playing(excluState and watercrouchwalkState) end
        if path.watercrouchwalkback then path.watercrouchwalkback:playing(excluState and watercrouchwalkbackState) end
        if path.watercrouchdown then path.watercrouchdown:playing(excluState and watercrouchdownState) end
        if path.watercrouchup then path.watercrouchup:playing(excluState and watercrouchupState) end

        if path.eatR then path.eatR:playing(incluState and eatRState or (drinkRState and not path.drinkR)) end
        if path.eatL then path.eatL:playing(incluState and eatLState or (drinkLState and not path.drinkL)) end
        if path.drinkR then path.drinkR:playing(incluState and drinkRState) end
        if path.drinkL then path.drinkL:playing(incluState and drinkLState) end
        if path.blockR then path.blockR:playing(incluState and blockRState) end
        if path.blockL then path.blockL:playing(incluState and blockLState) end
        if path.bowR then path.bowR:playing(incluState and bowRState) end
        if path.bowL then path.bowL:playing(incluState and bowLState) end
        if path.loadR then path.loadR:playing(incluState and loadRState) end
        if path.loadL then path.loadL:playing(incluState and loadLState) end
        if path.crossbowR then path.crossbowR:playing(incluState and crossR) end
        if path.crossbowL then path.crossbowL:playing(incluState and crossL) end
        if path.spearR then path.spearR:playing(incluState and spearRState) end
        if path.spearL then path.spearL:playing(incluState and spearLState) end
        if path.spyglassR then path.spyglassR:playing(incluState and spyglassRState) end
        if path.spyglassL then path.spyglassL:playing(incluState and spyglassLState) end
        if path.hornR then path.hornR:playing(incluState and hornRState) end
        if path.hornL then path.hornL:playing(incluState and hornLState) end
        if path.brushR then path.brushR:playing(incluState and brushRState) end
        if path.brushL then path.brushL:playing(incluState and brushLState) end

        if path.holdR then path.holdR:playing(incluState and rightHoldState) end
        if path.holdL then path.holdL:playing(incluState and leftHoldState) end
    end

    if swingTime then
        local specialAttack = false
        if rightAttack and incluState then
            for _, value in pairs(attackRanims) do
                if value:getName():find("ID_") then
                    if rightItem.id:find(value:getName():gsub("_attackR",""):gsub("ID_","")) then
                        JimmyAnims_Swing(value:getName())
                        specialAttack = true
                    end
                elseif value:getName():find("Name_") then
                    if rightItem:getName():find(value:getName():gsub("_attackR",""):gsub("Name_","")) then
                        JimmyAnims_Swing(value:getName())
                        specialAttack = true
                    end
                end
            end
            if not specialAttack then
                JimmyAnims_Swing("attackR")
            end
        elseif leftAttack and incluState then
            for _, value in pairs(attackLanims) do
                if value:getName():find("ID_") then
                    if leftItem.id:find(value:getName():gsub("_attackL",""):gsub("ID_","")) then
                        JimmyAnims_Swing(value:getName())
                        specialAttack = true
                    end
                elseif value:getName():find("Name_") then
                    if leftItem:getName():find(value:getName():gsub("_attackL",""):gsub("Name_","")) then
                        JimmyAnims_Swing(value:getName())
                        specialAttack = true
                    end
                end
            end
            if specialAttack == false then
                JimmyAnims_Swing("attackL")
            end
        elseif rightMine and incluState then
            for _, value in pairs(mineRanims) do
                if value:getName():find("ID_") then
                    if rightItem.id:find(value:getName():gsub("_mineR",""):gsub("ID_","")) then
                        JimmyAnims_Swing(value:getName())
                        specialAttack = true
                    end
                elseif value:getName():find("Name_") then
                    if rightItem:getName():find(value:getName():gsub("_mineR",""):gsub("Name_","")) then
                        JimmyAnims_Swing(value:getName())
                        specialAttack = true
                    end
                end
            end
            if not specialAttack then
                JimmyAnims_Swing("mineR")
            end
        elseif leftMine and incluState then
            for _, value in pairs(mineLanims) do
                if value:getName():find("ID_") then
                    if leftItem.id:find(value:getName():gsub("_mineL",""):gsub("ID_","")) then
                        JimmyAnims_Swing(value:getName())
                        specialAttack = true
                    end
                elseif value:getName():find("Name_") then
                    if leftItem:getName():find(value:getName():gsub("_mineL",""):gsub("Name_","")) then
                        JimmyAnims_Swing(value:getName())
                        specialAttack = true
                    end
                end
            end
            if not specialAttack then
                JimmyAnims_Swing("mineL")
            end
        end
    end 

    for _,value in pairs(holdRanims) do
        if value:getName():find("ID_") then
            value:setPlaying(rightItem.id:find(value:getName():gsub("_holdR",""):gsub("ID_","")) and incluState and exclude)
        elseif value:getName():find("Name_") then
            value:setPlaying(rightItem:getName():find(value:getName():gsub("_holdR",""):gsub("Name_","")) and incluState and exclude)
        end
        if value:isPlaying() then
            for _, path in pairs(bbmodels) do
                if path.holdR then path.holdR:stop() end
            end
        end
    end

    for _,value in pairs(holdLanims) do
        if value:getName():find("ID_") then
            value:setPlaying(leftItem.id:find(value:getName():gsub("_holdL",""):gsub("ID_","")) and incluState and exclude)
        elseif value:getName():find("Name_") then
            value:setPlaying(leftItem:getName():find(value:getName():gsub("_holdL",""):gsub("Name_","")) and incluState and exclude)
        end
        if value:isPlaying() then
            for _, path in pairs(bbmodels) do
                if path.holdL then path.holdL:stop() end
            end
        end
    end
end

local attackinit = true
local function animInit()
    for _, path in pairs(bbmodels) do
        for _,anim in pairs(path) do
            if (anim:getName():find("attackR") or anim:getName():find("attackL") or anim:getName():find("mineR") or anim:getName():find("mineL")) and attackinit then
                attackinit = false
                distinit = true
            end
            if anim:getName():find("^fly") then
                flyinit = true
            end
            if anim:getName():find("_holdR") then
                holdRanims[#holdRanims+1] = anim
            end
            if anim:getName():find("_holdL") then
                holdLanims[#holdLanims+1] = anim
            end
            if anim:getName():find("_attackR") then
                attackRanims[#attackRanims+1] = anim
            end
            if anim:getName():find("_attackL") then
                attackLanims[#attackLanims+1] = anim
            end
            if anim:getName():find("_mineR") then
                mineRanims[#mineRanims+1] = anim
            end
            if anim:getName():find("_mineL") then
                mineLanims[#mineLanims+1] = anim
            end
        end
    end
end

local function tick()
    anims()
end

local GSAnimBlend
for _, key in ipairs(listFiles(nil,true)) do
    if key:find("GSAnimBlend$") then
        GSAnimBlend = require(key)
        break
    end
end
if GSAnimBlend then GSAnimBlend.safe = false end

local function blend(paths, time, itemTime)
    if not GSAnimBlend then return end
    for _, path in pairs(paths) do
        if path.walk then path.walk:blendTime(time) end
        if path.idle then path.idle:blendTime(time) end
        if path.crouch then path.crouch:blendTime(time) end
        if path.walkback then path.walkback:blendTime(time) end
        if path.sprint then path.sprint:blendTime(time) end
        if path.crouchwalk then path.crouchwalk:blendTime(time) end
        if path.crouchwalkback then path.crouchwalkback:blendTime(time) end
        if path.elytra then path.elytra:blendTime(time) end
        if path.elytradown then path.elytradown:blendTime(time) end
        if path.fly then path.fly:blendTime(time) end
        if path.flywalk then path.flywalk:blendTime(time) end
        if path.flywalkback then path.flywalkback:blendTime(time) end
        if path.flysprint then path.flysprint:blendTime(time) end
        if path.flyup then path.flyup:blendTime(time) end
        if path.flydown then path.flydown:blendTime(time) end
        if path.sit then path.sit:blendTime(time) end
        if path.sitmove then path.sitmove:blendTime(time) end
        if path.sitmoveback then path.sitmoveback:blendTime(time) end
        if path.sitjumpup then path.sitjumpup:blendTime(time) end
        if path.sitjumpdown then path.sitjumpdown:blendTime(time) end
        if path.sitpass then path.sitpass:blendTime(time) end
        if path.sleep then path.sleep:blendTime(time) end
        if path.climb then path.climb:blendTime(time) end
        if path.climbstill then path.climbstill:blendTime(time) end
        if path.climbdown then path.climbdown:blendTime(time) end
        if path.climbcrouch then path.climbcrouch:blendTime(time) end
        if path.climbcrouchwalk then path.climbcrouchwalk:blendTime(time) end
        if path.swim then path.swim:blendTime(time) end
        if path.crawl then path.crawl:blendTime(time) end
        if path.crawlstill then path.crawlstill:blendTime(time) end
        if path.fall then path.fall:blendTime(time) end
        if path.jumpup then path.jumpup:blendTime(time) end
        if path.jumpdown then path.jumpdown:blendTime(time) end
        if path.sprintjumpup then path.sprintjumpup:blendTime(time) end
        if path.sprintjumpdown then path.sprintjumpdown:blendTime(time) end
        if path.crouchjumpup then path.crouchjumpup:blendTime(time) end
        if path.crouchjumpdown then path.crouchjumpdown:blendTime(time) end
        if path.trident then path.trident:blendTime(time) end
        if path.death then path.death:blendTime(time) end
        if path.water then path.water:blendTime(time) end
        if path.waterwalk then path.waterwalk:blendTime(time) end
        if path.waterwalkback then path.waterwalkback:blendTime(time) end
        if path.waterup then path.waterup:blendTime(time) end
        if path.waterdown then path.waterdown:blendTime(time) end
        if path.watercrouch then path.watercrouch:blendTime(time) end
        if path.watercrouchwalk then path.watercrouchwalk:blendTime(time) end
        if path.watercrouchwakback then path.watercrouchwakback:blendTime(time) end
        if path.watercrouchdown then path.watercrouchdown:blendTime(time) end
        if path.watercrouchup then path.watercrouchup:blendTime(time) end

        if path.eatR then path.eatR:blendTime(itemTime) end
        if path.eatL then path.eatL:blendTime(itemTime) end
        if path.drinkR then path.drinkR:blendTime(itemTime) end
        if path.drinkL then path.drinkL:blendTime(itemTime) end
        if path.blockR then path.blockR:blendTime(itemTime) end
        if path.blockL then path.blockL:blendTime(itemTime) end
        if path.bowR then path.bowR:blendTime(itemTime) end
        if path.bowL then path.bowL:blendTime(itemTime) end
        if path.crossbowR then path.crossbowR:blendTime(itemTime) end
        if path.crossbowL then path.crossbowL:blendTime(itemTime) end
        if path.loadR then path.loadR:blendTime(itemTime) end
        if path.loadL then path.loadL:blendTime(itemTime) end
        if path.spearR then path.spearR:blendTime(itemTime) end
        if path.spearL then path.spearL:blendTime(itemTime) end
        if path.spyglassR then path.spyglassR:blendTime(itemTime) end
        if path.spyglassL then path.spyglassL:blendTime(itemTime) end
        if path.hornR then path.hornR:blendTime(itemTime) end
        if path.hornL then path.hornL:blendTime(itemTime) end
        if path.brushR then path.brushR:blendTime(itemTime) end
        if path.brushL then path.brushL:blendTime(itemTime) end
        if path.attackR then path.attackR:blendTime(itemTime) end
        if path.attackL then path.attackL:blendTime(itemTime) end
        if path.mineR then path.mineR:blendTime(itemTime) end
        if path.mineL then path.mineL:blendTime(itemTime) end
        if path.holdR then path.holdR:blendTime(itemTime) end
        if path.holdL then path.holdL:blendTime(itemTime) end
    end
    for _,value in pairs(holdRanims) do
        value:blendTime(itemTime)
    end
    for _,value in pairs(holdLanims) do
        value:blendTime(itemTime)
    end
    for _,value in pairs(attackRanims) do
        value:blendTime(itemTime)
    end
    for _,value in pairs(attackLanims) do
        value:blendTime(itemTime)
    end
    for _,value in pairs(mineRanims) do
        value:blendTime(itemTime)
    end
    for _,value in pairs(mineLanims) do
        value:blendTime(itemTime)
    end
end

wait(20,function()
   assert(
    next(bbmodels),
   "§aCustom Script Warning: §6JimmyAnims isn't being required, or a blockbench model isn't being provided to it. \n".."§6 Put this code in a DIFFERENT script to use JimmyAnims: \n".."§flocal anims = require('JimmyAnims') \n"..
   "§fanims(animations.BBMODEL_NAME_HERE) \n".."§6 Where you replace BBMODEL_NAME_HERE with the name of your bbmodel. \n".."§6 Or go to the top of the script or to the top of the Discord forum for more complete instructions.".."§c") 
end)

local init = false
local animMT = {__call = function(self, ...)
    local paths = {...}
    local should_blend = true
    if self.autoBlend ~= nil then should_blend = self.autoBlend end
    if self.fall ~= nil then fallVel = self.fall end

    errors(paths,self.dismiss)

    for _, v in ipairs(paths) do
        bbmodels[#bbmodels+1] = v
    end
    if #bbmodels >= 64 then
        error(
            "§aCustom Script Warning: §6You've reached the max limit of 64 bbmodels that can be added to JimmyAnims. To save your FPS the script has been stopped. \n"..
            "To prevent this from happening accidentally you should move the function call out of any function it is in.§c"
            ,2
        )
    end

    -- Init stuff.
    if init then return end
    animInit()
    if should_blend then blend(paths, self.excluBlendTime or 4, self.incluBlendTime or 4) end
    events.TICK:register(tick)
    init = true
end}

local function addAllAnimsController(...)
    if #allAnims >= 1024 then
        error(
            "§aCustom Script Warning: §6You've reached the max limit of 1024 animations that can be added to the addAllAnimsController. To save your FPS the script has been stopped. \n"..
            "To prevent this from happening accidentally you should move the function call out of any function it is in.§c"
            ,2
        )
    end
    for _, v in ipairs{...} do
        assert(
            type(v) == "Animation",
            "§aCustom Script Warning: §6addAllAnimsController was given something that isn't an animation, check its spelling for errors.§c")
      allAnims[#allAnims+1] = v
    end
end

local function addExcluAnimsController(...)
    if #excluAnims >= 1024 then
        error(
            "§aCustom Script Warning: §6You've reached the max limit of 1024 animations that can be added to the addExcluAnimsController. To save your FPS the script has been stopped. \n"..
            "To prevent this from happening accidentally you should move the function call out of any function it is in.§c"
            ,2
        )
    end
    for _, v in ipairs{...} do
        assert(
            type(v) == "Animation",
            "§aCustom Script Warning: §6addExcluAnimsController was given something that isn't an animation, check its spelling for errors.§c")
      excluAnims[#excluAnims+1] = v
    end
end

local function addIncluAnimsController(...)
    if #incluAnims >= 1024 then
        error(
            "§aCustom Script Warning: §6You've reached the max limit of 1024 animations that can be added to the addIncluAnimsController. To save your FPS the script has been stopped. \n"..
            "To prevent this from happening accidentally you should move the function call out of any function it is in.§c"
            ,2
        )
    end
    for _, v in ipairs{...} do
        assert(
            type(v) == "Animation",
            "§aCustom Script Warning: §6addIncluAnimsController was given something that isn't an animation, check its spelling for errors.§c")
      incluAnims[#incluAnims+1] = v
    end
end

local function setAllOn(x)
    setAllOnVar = x
end

local function setExcluOn(x)
    setExcluOnVar = x
end

local function setIncluOn(x)
    setIncluOnVar = x
end

local function oneJumpFunc(x)
    oneJump = x
end

-- If you're choosing to edit this script, don't put anything beneath the return line

return setmetatable(
    {
        animsList = animsList,
        addAllAnimsController = addAllAnimsController,
        addExcluAnimsController = addExcluAnimsController,
        addIncluAnimsController = addIncluAnimsController,
        setAllOn = setAllOn,
        setExcluOn = setExcluOn,
        setIncluOn = setIncluOn,
        oneJump = oneJumpFunc,
    },
    animMT
)
