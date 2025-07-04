-- ==========================
-- 导弹发射系统 (带导弹模型和碰撞检测)
-- 按V键发射导弹，30秒后自动爆炸
-- ==========================

-- 导弹管理器
local MissileManager = {
    missiles = {},  -- 存储所有活跃导弹
    cooldown = 0,   -- 发射冷却时间
    rootPart = nil  -- 导弹模型根部件
}

--- 初始化导弹系统
function MissileManager.init()
    -- 创建导弹模型的根部件
    MissileManager.rootPart = models:newPart("missile_root", "World")
    -- 隐藏原始导弹模型（如果存在）
    if models.missile then
        models.missile:setVisible(false)
    end
    print("导弹系统已初始化")
end

--- 创建新导弹
---@param startPos Vector3 起始位置
---@param direction Vector3 飞行方向
function MissileManager.createMissile(startPos, direction)
    -- 创建导弹实例
    local missile = {
        position = startPos:copy(),
        velocity = direction:normalize():scale(1.5), -- 标准化并加速
        lifetime = 600, -- 30秒生命周期(20tick/s * 30s = 600)
        active = true,
        id = math.random(10000, 99999), -- 唯一ID用于识别
        model = nil, -- 导弹模型实例
        sound = nil -- 导弹音效
    }

    -- 创建导弹模型
    if models.missile then
        missile.model = models.missile:copy(missile.id)
        MissileManager.rootPart:addChild(missile.model)
        missile.model:setPos(startPos * 16) -- 转换为方块坐标
        missile.model:setVisible(true)
    end

    -- 计算导弹旋转角度
    local pitch = -math.deg(math.asin(direction.y))
    local yaw = math.deg(math.atan2(direction.z, direction.x)) + 90
    missile.rotation = vectors.vec3(pitch, yaw, 0)

    -- 添加发射效果
    particles:newParticle("minecraft:flame", startPos):setScale(1.5)
    particles:newParticle("minecraft:smoke", startPos):setScale(1.2)

    -- 播放发射音效
    missile.sound = sounds:playSound("minecraft:entity.firework_rocket.launch", startPos, 0.8, 1.2)

    table.insert(MissileManager.missiles, missile)

    -- 发送导弹创建事件
    pings.missileCreated(missile.id, startPos, direction)

    return missile
end

--- 碰撞检测函数 (基于drone_missile.lua实现)
---@param position Vector3 检测位置
---@return boolean 是否发生碰撞
function MissileManager.checkCollision(position)
    -- 获取位置所在的方块状态
    local blockState = world.getBlockState(position)

    -- 如果方块是空气，则没有碰撞
    if blockState.name == "minecraft:air" then
        return false
    end

    -- 获取方块的碰撞箱
    local collisionShapes = blockState:getCollisionShape()

    -- 如果方块没有碰撞箱，则没有碰撞
    if #collisionShapes == 0 then
        return false
    end

    -- 计算方块的世界坐标
    local blockPos = position:copy():floor()

    -- 检查所有碰撞箱
    for _, collisionBox in ipairs(collisionShapes) do
        -- 计算碰撞箱的实际世界坐标
        local collisionBoxStart = blockPos:copy():add(collisionBox[1])
        local collisionBoxEnd = blockPos:copy():add(collisionBox[2])

        -- 检查位置是否在碰撞箱内
        if position.x >= collisionBoxStart.x and position.x <= collisionBoxEnd.x and
           position.y >= collisionBoxStart.y and position.y <= collisionBoxEnd.y and
           position.z >= collisionBoxStart.z and position.z <= collisionBoxEnd.z then
            return true -- 发生碰撞
        end
    end

    return false -- 没有碰撞
end

--- 更新所有导弹
function MissileManager.updateMissiles()
    -- 更新冷却时间
    if MissileManager.cooldown > 0 then
        MissileManager.cooldown = MissileManager.cooldown - 1
    end

    for i = #MissileManager.missiles, 1, -1 do
        local missile = MissileManager.missiles[i]

        if missile.active then
            -- 更新位置
            missile.position:add(missile.velocity)

            -- 更新导弹模型位置和旋转
            if missile.model then
                missile.model:setPos(missile.position * 16) -- 转换为方块坐标

                -- 平滑旋转到飞行方向
                local targetPitch = -math.deg(math.asin(missile.velocity.y))
                local targetYaw = math.deg(math.atan2(missile.velocity.z, missile.velocity.x)) + 90

                missile.rotation.x = missile.rotation.x * 0.8 + targetPitch * 0.2
                missile.rotation.y = missile.rotation.y * 0.8 + targetYaw * 0.2

                missile.model:setRot(missile.rotation)
            end

            -- 更新音效位置
            if missile.sound then
                missile.sound:setPos(missile.position)
            end

            -- 检查碰撞 (使用改进的碰撞检测)
            if MissileManager.checkCollision(missile.position) then
                MissileManager.explodeMissile(missile)
                missile.active = false
            end

            -- 检查超时
            missile.lifetime = missile.lifetime - 1
            if missile.lifetime <= 0 then
                MissileManager.explodeMissile(missile)
                missile.active = false
            end

            -- 添加尾迹
            if world.getTime() % 1 == 0 then -- 每1tick添加一次粒子
                particles:newParticle("minecraft:smoke", missile.position):setScale(0.8)
                particles:newParticle("minecraft:flame", missile.position):setScale(0.6):setLifetime(10)
            end
        else
            -- 移除导弹模型和音效
            if missile.model then
                missile.model:remove()
            end
            if missile.sound then
                missile.sound:stop()
            end
            table.remove(MissileManager.missiles, i)
        end
    end
end

--- 导弹爆炸
---@param missile table 导弹对象
function MissileManager.explodeMissile(missile)
    -- 爆炸效果
    particles:newParticle("minecraft:explosion_emitter", missile.position):setScale(2)
    particles:newParticle("minecraft:flash", missile.position):setScale(3)

    -- 爆炸冲击波效果
    for i = 1, 20 do
        local angle = math.rad(i * 18)
        local offset = vectors.vec3(math.cos(angle) * 0.5, math.random() * 0.5, math.sin(angle) * 0.5)
        particles:newParticle("minecraft:poof", missile.position:copy():add(offset)):setScale(1.5)
    end

    sounds:playSound("minecraft:entity.generic.explode", missile.position, 0.7, 0.9)

    -- 发送导弹爆炸事件
    pings.missileExploded(missile.id, missile.position)
end

--- 发射导弹
function MissileManager.launchMissile()
    if MissileManager.cooldown > 0 then
        sounds:playSound("minecraft:block.dispenser.fail", player:getPos(), 0.5, 1)
        return
    end

    -- 设置冷却时间(1秒)
    MissileManager.cooldown = 20

    -- 获取起始位置(玩家眼睛位置)
    local startPos = player:getPos():add(0, 1.6, 0)

    -- 获取视线方向
    local lookDir = player:getLookDir()

    -- 生成导弹
    MissileManager.createMissile(startPos, lookDir)
end

-- =====================
-- 客户端通信函数
-- =====================

--- 导弹创建事件
---@param missileId number 导弹ID
---@param position Vector3 位置
---@param direction Vector3 方向
function pings.missileCreated(missileId, position, direction)
    -- 在实际应用中，这里可以通知其他客户端创建导弹
    -- 本示例仅用于演示通信结构
    if host:isHost() then
    end
end

--- 导弹爆炸事件
---@param missileId number 导弹ID
---@param position Vector3 爆炸位置
function pings.missileExploded(missileId, position)
    -- 在实际应用中，这里可以通知其他客户端播放爆炸效果
    if host:isHost() then
    end
end

-- =====================
-- 事件注册
-- =====================

-- 初始化导弹系统
MissileManager.init()

-- 在tick事件中更新导弹
events.TICK:register(function()
    MissileManager.updateMissiles()
end)

-- 注册按键监听
keybinds:newKeybind("发射导弹", "key.keyboard.v"):onPress(function()
    MissileManager.launchMissile()
end)
-- 初始化提示
print("导弹系统已加载 - 按V键发射导弹")
print("导弹将在30秒后自动爆炸或碰撞时爆炸")
