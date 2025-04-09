-- eye_tracking_api.lua
local M = {} -- 模块主表

-- ======================= 默认配置 =======================
local config = {
    -- [!] 默认模型路径（当主脚本不提供配置时使用）
    left_eye_path = "model.root.Torso.Head.Eyes.lefteye.leftpupil",
    right_eye_path = "model.root.Torso.Head.Eyes.righteye.rightpupil",
    head_part = "Head", -- 默认头部部件名称

    -- [!] 默认行为参数
    max_offset = 0.5, -- 默认瞳孔最大偏移
    sensitivity = 35, -- 默认灵敏度
    update_interval = 2, -- 默认更新间隔
    debug_mode = false -- 默认关闭调试
}

-- ======================= 工具函数 =======================
-- 数值钳制函数：确保数值在[min, max]范围内
-- @param value 输入值
-- @param min 最小值
-- @param max 最大值
-- @return 钳制后的数值
local function clamp(value, min, max)
    return value < min and min or (value > max and max or value)
end

-- ================= 模型部件解析函数 ====================
-- 根据路径字符串查找模型部件（核心实现）
-- @param path 点分隔的层级路径（如"model.head.left_eye"）
-- @return 模型部件对象 或 nil（找不到时）
local function resolve_part(path)
    -- 实现方案1：使用Blockbench官方API（需取消注释）
    -- return models:findPart(path) -- 注意API函数名可能为findPart/find_part

    -- 实现方案2：通用层级遍历（当前启用）
    local parts = {}
    for segment in path:gmatch("[^.]+") do -- 分割路径为层级数组
        table.insert(parts, segment)
    end
    local current = models -- 从根模型对象开始
    for _, part in ipairs(parts) do
        current = current[part]
        if not current then
            print("[ERROR] 路径解析失败:", part) -- 打印具体失效节点
            return nil
        end
    end
    return current
end

-- ====================== 初始化函数 =====================
-- 模块初始化入口（主脚本必须调用）
-- @param user_config 用户配置表（可覆盖默认值）
function M.init(user_config)
    -- 合并用户配置与默认配置
    if user_config then
        for k, v in pairs(user_config) do
            config[k] = v -- 用户配置优先
        end
    end

    -- [!] 关键模型部件获取
    M.left_pupil = resolve_part(config.left_eye_path) -- 解析左眼路径
    M.right_pupil = resolve_part(config.right_eye_path) -- 解析右眼路径
    M.head_part = vanilla_model[config.head_part] -- 获取头部部件引用

    -- 错误校验（中断并提示具体问题）
    assert(M.left_pupil, "左眼路径无效: "..config.left_eye_path.."\n请检查：\n1.路径拼写\n2.模型层级\n3.部件可见性")
    assert(M.right_pupil, "右眼路径无效: "..config.right_eye_path)
    assert(M.head_part, "头部部件不存在: "..config.head_part.."\n确认部件是否在vanilla_model中注册")
end

-- =================== 瞳孔偏移计算逻辑 ===================
-- 根据头部旋转计算瞳孔偏移量
-- @param rotationY 头部Y轴旋转角度（-180~180度）
-- @return x, y, z 三维偏移（当前仅使用X轴）
local function calculate_pupil_offset(rotationY)
    -- 归一化处理：将角度映射到[-1,1]范围
    local normalized = clamp(rotationY / config.sensitivity, -1, 1)
    -- X轴取反实现自然跟随效果
    return -normalized * config.max_offset, 0, 0
end

-- ==================== 游戏刻事件处理 ====================
-- 每帧执行的主逻辑
function events.tick()
    if not (M.left_pupil and M.right_pupil) then return end -- 安全防护

    -- 更新计时器
    M.pupilUpdateTimer = (M.pupilUpdateTimer or 0) + 1
    if M.pupilUpdateTimer >= config.update_interval then
        -- 获取头部Y轴旋转角度
        local headRotationY = M.head_part:getOriginRot().y

        -- 计算偏移量
        local x, y, z = calculate_pupil_offset(headRotationY)

        -- 应用瞳孔位置
        M.left_pupil:pos(x, y, z)
        M.right_pupil:pos(x, y, z)

        -- 调试输出
        if config.debug_mode then
            print(string.format("瞳孔偏移量: X=%.2f (头部旋转 %.1f 度)", x, headRotationY))
            -- 可添加更多调试信息：
            -- print("当前配置:", textutils.serialise(config))
        end

        M.pupilUpdateTimer = 0 -- 重置计时器
    end
end

return M
