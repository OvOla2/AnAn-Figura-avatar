---- SittingAPI.lua
---- [OVERRIDE NOTICE] 该脚本基于CatMaid项目中sit_down.lua二次开发
---- Original Author: Gakuto1112
---- Source: https://github.com/Gakuto1112/CatMaid
---- License: MIT

---@class SittingAPI 坐立控制API（Ping同步版）
SittingAPI = {
    isSitting = false,
    _initialized = false
}

-- 定义Ping函数
function pings.syncSitState(state)
    if state then
        animations.model.sit_down:play()
        animations.model.stand_up:stop()
    else
        animations.model.stand_up:play()
        animations.model.sit_down:stop()
    end
end

--- 初始化API
function SittingAPI.init()
    if SittingAPI._initialized then return end

    -- 注册按键绑定
    keybinds:newKeybind("坐立切换", "key.keyboard.n")
        :onPress(function()
            if SittingAPI.isSitting then
                SittingAPI.standUp()
            else
                if SittingAPI.canSit() then
                    SittingAPI.sitDown()
                end
            end
        end)

    -- 注册受伤事件
    events.DAMAGE:register(function()
        if SittingAPI.isSitting then
            SittingAPI.standUp()
        end
    end)

     -- 检测移动自动站立
    events.TICK:register(function()
        if SittingAPI.isSitting and player:isMoving(true) then  -- 检测到移动时强制站立
            SittingAPI.standUp()
        end
    end)

    SittingAPI._initialized = true
end

--- 检查坐下条件
function SittingAPI.canSit()
    return player and
        player:getPose() == "STANDING" and
        player:isOnGround() and
        not player:getVehicle() and
        not player:isMoving(true)
end

--- 执行坐下（带Ping同步）
function SittingAPI.sitDown()
    -- 本地动画控制
    animations.model.sit_down:play()
    animations.model.stand_up:stop()
    SittingAPI.isSitting = true

    -- 发送Ping（使用1字节布尔值）
    pings.syncSitState(true) -- 占用总字节：1(type) + 0(bool) = 1 byte
end

--- 执行站立（带Ping同步）
function SittingAPI.standUp()
    -- 本地动画控制
    animations.model.stand_up:play()
    animations.model.sit_down:stop()
    SittingAPI.isSitting = false

    -- 发送Ping
    pings.syncSitState(false) -- 1(type) + 0(bool) = 1 byte
end

--- 获取当前状态
function SittingAPI.getState()
    return SittingAPI.isSitting
end

return SittingAPI
