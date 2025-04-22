---- Wet-control.lua
---- [OVERRIDE NOTICE] 该脚本基于CatMaid项目中wet.lua二次开发
---- Original Author: Gakuto1112
---- Source: https://github.com/Gakuto1112/CatMaid
---- License: MIT

---@class WetClass 控制润湿功能的类
---@field WetCount integer 润湿程度计数器
WetClass = {
    WetCount = 0,
    _shakeCooldown = 0,
    _isShaking = false,
    -- 粒子参数优化
    SHAKE_PARTICLES = 48,      -- 甩动时生成的粒子数量（原8→48）
    PARTICLE_SPREAD = 1.2,     -- 粒子散布范围（原0.7→1.2）
    DRIP_PARTICLES = 3         -- 干燥阶段每次生成的粒子数量
}

events.TICK:register(function()
    if client:isPaused() then return end  -- 游戏暂停时跳过逻辑

    if player:isWet() then
        -- [湿润状态] 重置所有干燥相关状态
        WetClass.WetCount = player:isInWater() and 1200 or math.min(WetClass.WetCount + 4, 1200)
        WetClass._shakeCooldown = 0
        WetClass._isShaking = false
    elseif WetClass.WetCount > 0 then
        local pos = player:getPos()

        -- [干燥阶段] 常规粒子效果（优化粒子数量计算）
        if not WetClass._isShaking and WetClass.WetCount % 6 == 0 then
            for _ = 1, WetClass.DRIP_PARTICLES do
                particles:newParticle(
                    "minecraft:falling_water",
                    pos.x + (math.random() - 0.5) * 0.8,
                    pos.y + math.random() * 0.3 + 0.5,
                    pos.z + (math.random() - 0.5) * 0.8
                )
            end
        end

        -- 自动甩水逻辑（添加粒子生成）
        if not WetClass._isShaking then
            WetClass._shakeCooldown = WetClass._shakeCooldown + 1

            if WetClass._shakeCooldown >= 40 then
                animations.model.shake:play()
                 -- 新增抖水音效播放
                sounds:playSound("entity.wolf.shake", player:getPos())

                -- 甩动时生成爆发式粒子
                for _ = 1, WetClass.SHAKE_PARTICLES do
                    particles:newParticle(
                        "minecraft:splash",  -- 改为更明显的水花粒子
                        pos.x + (math.random() - 0.5) * WetClass.PARTICLE_SPREAD,
                        pos.y + math.random() * 0.5 + 0.5,
                        pos.z + (math.random() - 0.5) * WetClass.PARTICLE_SPREAD,
                        0, 0.2, 0  -- 添加初始速度
                    )
                end

                WetClass._isShaking = true
                WetClass.WetCount = 0
                WetClass._shakeCooldown = 0
            else
                WetClass.WetCount = WetClass.WetCount - 1
            end
        end
    end

    -- 动画结束检测（增加暂停状态过滤）
    if WetClass._isShaking and animations.model.shake:getPlayState() == "STOPPED" then
        WetClass._isShaking = false
    end
end)

return WetClass
