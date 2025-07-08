---@class BugScareClass 蠹虫/蜘蛛恐惧系统控制类
BugScareClass = {
    BugsNearby = false,
    BugCheckTimer = 0,
    BugCheckInterval = 10, -- 每10tick检测一次(0.5秒)
    BugCheckRadius = 4,    -- 4方块检测半径
    ScaryTypes = {"minecraft:silverfish", "minecraft:spider", "minecraft:cave_spider"}, -- 蠹虫、蜘蛛、洞穴蜘蛛
    Debug = true, -- 调试模式开关
    fearState = "normal"   -- 添加恐惧状态跟踪: normal, initial, looping
}

-- 调试日志函数
local function logDebug(message)
    if BugScareClass.Debug then
        print("[BugScare] " .. message)
    end
end

-- 安全获取实体列表（使用边界框）
local function getEntitiesInRadius(center, radius)
    if not world or not world.getEntities then
        logDebug("world.getEntities not available")
        return {}
    end

    -- 创建检测范围的边界框
    local minPos = {
        x = center.x - radius,
        y = center.y - radius,
        z = center.z - radius
    }

    local maxPos = {
        x = center.x + radius,
        y = center.y + radius,
        z = center.z + radius
    }

    -- 使用坐标参数
    success, entities = pcall(world.getEntities,
        minPos.x, minPos.y, minPos.z,
        maxPos.x, maxPos.y, maxPos.z)

    if success and type(entities) == "table" then
        return entities
    end

    logDebug("Failed to get entities: " .. tostring(entities))
    return {}
end

-- 检测附近是否有恐惧生物
function BugScareClass.areBugsNearby()
    -- 确保玩家对象存在且有效
    if not player or not player.getPos or not player:getPos() then
        logDebug("Player not available")
        return false
    end

    -- 跳过无效状态
    local pose = player:getPose()
    if pose == "SLEEPING" or pose == "DYING" then
        logDebug("Skipping detection: player is sleeping or dying")
        return false
    end

    -- 获取玩家位置
    local playerPos = player:getPos()
    local entities = getEntitiesInRadius(playerPos, BugScareClass.BugCheckRadius)
    local radiusSq = BugScareClass.BugCheckRadius * BugScareClass.BugCheckRadius

    logDebug("Scanning " .. #entities .. " entities near player")

    -- 扫描附近实体
    for _, entity in ipairs(entities) do
        if entity and entity.getPos and entity.getType then
            local success, entPos = pcall(entity.getPos, entity)
            if success and entPos then
                local dx = entPos.x - playerPos.x
                local dy = entPos.y - playerPos.y
                local dz = entPos.z - playerPos.z
                local distSq = dx*dx + dy*dy + dz*dz

                -- 检查是否在检测范围内
                if distSq <= radiusSq then
                    local success, entType = pcall(entity.getType, entity)
                    if success and entType then
                        -- 检查实体类型是否匹配
                        for _, scaryType in ipairs(BugScareClass.ScaryTypes) do
                            if entType == scaryType then
                                logDebug("Found scary entity: " .. entType .. " at distance " .. math.sqrt(distSq))
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    logDebug("No scary entities found")
    return false
end

-- 处理发现恐惧生物
function BugScareClass.handleBugDetection()
    logDebug("Handling bug detection")
    BugScareClass.fearState = "initial"  -- 进入初始恐惧状态

    -- 确保模型存在
    local face = models.model and models.model.root and models.model.root.Torso and models.model.root.Torso.Head and models.model.root.Torso.Head.Face
    if face then
        pcall(function()
            face.Eyebrow:setVisible(false)
            face.Eyes:setVisible(false)
            face.test:setVisible(true)
            logDebug("Face parts visibility updated")
        end)
    end

    -- 停止可能正在播放的恢复动画
    if animations.model.stand_up and animations.model.stand_up:isPlaying() then
        pcall(animations.model.stand_up.stop, animations.model.stand_up)
        logDebug("Stopped stand_up animation")
    end

    -- 停止循环动画（如果有）
    if animations.model.bug1 and animations.model.bug1:isPlaying() then
        pcall(animations.model.bug1.stop, animations.model.bug1)
        logDebug("Stopped bug1 animation")
    end

    -- 播放初始动画
    if animations.model.bug0 then
        pcall(function()
            animations.model.bug0:setLoop("ONCE")
            animations.model.bug0:play()
            logDebug("Playing bug0 animation (single play)")
        end)
    else
        logDebug("bug0 animation not found")
        -- 如果没有bug0动画，直接进入循环状态
        BugScareClass.fearState = "looping"
        BugScareClass.startLoopAnimation()
    end
end

-- 处理恐惧生物离开
function BugScareClass.handleBugDeparture()
    logDebug("Handling bug departure")
    BugScareClass.fearState = "normal"  -- 回到正常状态

    -- 停止恐惧动画
    if animations.model.bug0 and animations.model.bug0:isPlaying() then
        pcall(animations.model.bug0.stop, animations.model.bug0)
        logDebug("Stopped bug0 animation")
    end

    if animations.model.bug1 and animations.model.bug1:isPlaying() then
        pcall(function()
            animations.model.bug1:stop()
            logDebug("Stopped bug1 animation")
        end)
    end

    -- 播放恢复动画
    if animations.model.stand_up then
        pcall(function()
            animations.model.stand_up:setLoop("ONCE")
            animations.model.stand_up:play()
            logDebug("Playing stand_up recovery animation")
        end)
    else
        logDebug("stand_up animation not found - skipping")
    end

    -- 无论动画是否存在都恢复面部
    pcall(function()
        local face = models.model and models.model.root and models.model.root.Torso and models.model.root.Torso.Head and models.model.root.Torso.Head.Face
        if face then
            face.Eyebrow:setVisible(true)
            face.Eyes:setVisible(true)
            face.test:setVisible(false)
            logDebug("Restored face parts without animation")
        end
    end)
end

-- 启动循环动画
function BugScareClass.startLoopAnimation()
    logDebug("Starting loop animation")
    BugScareClass.fearState = "looping"  -- 进入循环恐惧状态

    if animations.model.bug1 then
        pcall(function()
            animations.model.bug1:setLoop("LOOP")
            animations.model.bug1:play()
            logDebug("Playing bug1 animation (looping)")
        end)
    else
        logDebug("bug1 animation not found")
    end
end

-- 主检测循环
events.TICK:register(function()
    if not host or not host.isHost or not host:isHost() then
        return
    end

    BugScareClass.BugCheckTimer = BugScareClass.BugCheckTimer + 1

    -- 每tick都检查动画状态转换（确保无缝过渡）
    if BugScareClass.fearState == "initial" then
        -- 检查初始动画是否完成
        if animations.model.bug0 and animations.model.bug0:isStopped() then
            BugScareClass.startLoopAnimation()
        end
    end

    -- 达到检测间隔时执行
    if BugScareClass.BugCheckTimer >= BugScareClass.BugCheckInterval then
        BugScareClass.BugCheckTimer = 0

        -- 安全执行检测
        local success, bugsNearby = pcall(BugScareClass.areBugsNearby)
        if not success then
            logDebug("areBugsNearby failed: " .. tostring(bugsNearby))
            bugsNearby = false
        end

        logDebug("Bugs nearby: " .. tostring(bugsNearby) .. ", Current state: " .. tostring(BugScareClass.BugsNearby) .. ", Fear state: " .. BugScareClass.fearState)

        -- 状态变化处理
        if bugsNearby and not BugScareClass.BugsNearby then
            BugScareClass.BugsNearby = true
            BugScareClass.handleBugDetection()
        elseif not bugsNearby and BugScareClass.BugsNearby then
            BugScareClass.BugsNearby = false
            BugScareClass.handleBugDeparture()
        elseif bugsNearby and BugScareClass.BugsNearby then
            -- 如果虫子仍在附近但循环动画未播放，启动循环动画
            if BugScareClass.fearState == "initial" and animations.model.bug0 and animations.model.bug0:isStopped() then
                BugScareClass.startLoopAnimation()
            end
        end
    end
end)

-- 初始化日志
logDebug("BugScare system initialized. Debug mode: " .. tostring(BugScareClass.Debug))

return BugScareClass
