---- SittingAPI.lua ----
---- [OVERRIDE NOTICE] 该脚本基于CatMaid项目中sit_down.lua二次开发
---- Original Author: Gakuto1112
---- License: MIT

---@class SittingAPI 坐立控制API
SittingAPI = {
    isSitting = false,
    _initialized = false,
    _isSynced = false
}

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
        if SittingAPI.isSitting and player:isMoving(true) then
            SittingAPI.standUp()
        end
    end)

    SittingAPI._initialized = true
end

-- Ping同步函数
function pings.syncSitState(state)
    if not SittingAPI._isSynced then
        SittingAPI._isSynced = true
        SittingAPI.isSitting = state

        -- 仅控制动画
        if state then
            animations.model.sit_down:play()
            animations.model.stand_up:stop()
        else
            animations.model.stand_up:play()
            animations.model.sit_down:stop()
        end

        SittingAPI._isSynced = false
    end
end

--- 检查坐下条件
function SittingAPI.canSit()
	if player then
		return player:getPose() == "STANDING" and
		player:isOnGround() and
		not player:getVehicle() and
		not player:isMoving(true)
	else
		return false
	end
end

--- 执行坐下
function SittingAPI.sitDown()
    if not SittingAPI.canSit() then return end

    -- 更新本地状态
    SittingAPI.isSitting = true

    -- 播放本地动画
    animations.model.sit_down:play()
    animations.model.stand_up:stop()

    -- 网络同步
    if not SittingAPI._isSynced then
        pings.syncSitState(true)
    end
end

--- 执行站立
function SittingAPI.standUp()
    -- 更新本地状态
    SittingAPI.isSitting = false

    -- 播放本地动画
    animations.model.stand_up:play()
    animations.model.sit_down:stop()

    -- 网络同步
    if not SittingAPI._isSynced then
        pings.syncSitState(false)
    end
end

--- 获取当前状态
function SittingAPI.getState()
    return SittingAPI.isSitting
end

return SittingAPI
