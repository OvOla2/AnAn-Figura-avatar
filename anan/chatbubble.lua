--[[
    Figura Chat Bubble Module v1.0
]]

local config = {
    bubbleLifetime = 100,
    fadeTime = 20,
    maxMessageLength = 64,
    maxBubbles = 3,
    localIndicator = "\\"
}

-- 保持原始存储结构
local activeBubbles = {}
local modelRoot = models.chatBubble.Camera_speech

-- 保持原始updateBubble逻辑
local function updateBubble(bubble, offset)
    -- 与原代码完全一致
    local baseY = offset or 0
    bubble.textDisplay:setPos(
        0,
        baseY + (bubble.textDims.y-1)/2,
        -0.001
    )
end

-- 修改newBubble直接绑定发送者
local function newBubble(sender, text)
    -- 清理旧气泡（与原逻辑一致）
    if #activeBubbles >= config.maxBubbles then
        activeBubbles[1].textDisplay:remove()
        table.remove(activeBubbles, 1)
    end

    -- 文本计算保持原样
    local rawDims = client.getTextDimensions(text, 200, true)
    local textDims = vec(
        math.max(rawDims[1], 10),
        math.max(rawDims[2], 12)
    )

    -- 创建带发送者绑定的气泡
    local bubble = {
        sender = sender,  -- 直接存储玩家对象
        textDisplay = modelRoot:newText("bubble_"..#activeBubbles+1)
            :setText(text:sub(1, config.maxMessageLength))
            :alignment("CENTER")
            :setWidth(200)
            :setShadow(true)
            :setScale(0.5),
        textDims = textDims,
        age = 0
    }

    updateBubble(bubble)
    table.insert(activeBubbles, bubble)
    return bubble
end

-- 简化Ping函数（自动捕获发送者）
function pings.addBubble(text)
    -- 直接使用内置的sender变量
    newBubble(sender, text)  -- Figura自动注入sender对象
end

-- 保持原始事件处理
function events.CHAT_SEND_MESSAGE(message)
    local isLocal = message:sub(1, #config.localIndicator) == config.localIndicator
    local isCommand = message:sub(1,1) == "/"

    if isCommand then
        return isLocal and nil or message
    end

    if isLocal then
        pings.addBubble(message:sub(#config.localIndicator+1))
        return nil
    end

    pings.addBubble(message)
    return message
end

-- 保持原始生命周期管理
function events.TICK()
    for i = #activeBubbles, 1, -1 do
        activeBubbles[i].age = activeBubbles[i].age + 1
        if activeBubbles[i].age >= config.bubbleLifetime then
            activeBubbles[i].textDisplay:remove()
            table.remove(activeBubbles, i)
        end
    end
end

-- 修改渲染逻辑（直接使用sender对象）
function events.RENDER(delta)
    for _, bubble in ipairs(activeBubbles) do
        if bubble.sender and bubble.sender:isLoaded() then
            -- 动态位置计算
            local headPos = bubble.sender:getPos(delta):add(0, bubble.sender:getEyeHeight() * 1.2, 0)
            local camPos = matrices.camera:invertTransformPoint(headPos)
            bubble.textDisplay:setMatrix(matrices.model:translate(camPos))
        end

        -- 保持原始淡出逻辑
        if bubble.age > config.bubbleLifetime - config.fadeTime then
            local progress = (bubble.age - (config.bubbleLifetime - config.fadeTime)) / config.fadeTime
            bubble.textDisplay:opacity(1 - math.min(progress, 1))
        end
    end
end

return config
