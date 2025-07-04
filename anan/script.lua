-- Auto generated script file --

-- hide vanilla model
vanilla_model.PLAYER:setVisible(false)

-- hide vanilla armor model
vanilla_model.ARMOR:setVisible(false)

local anims = require("EZAnims")
local example = anims:addBBModel(animations.model)
anims:setFallVel(-1)
anims:setOneJump(true)
---------------------------------------
physBone = require('physBoneAPI')

function events.entity_init()
  physBone.physEar1:setSimSpeed(3)
  physBone.physEar2:setSimSpeed(3)
  physBone.physEar1:setSpringForce(70)
  physBone.physEar2:setSpringForce(70)
end

---------------------------------------

local mainPage = action_wheel:newPage()
action_wheel:setPage(mainPage)

function pings.actionClicked()
    animations.model.yeeeee:play()
    -- animation example (commented out to avoid erroring):
    -- animations.bbmodelname.animationname:play()
end

local action = mainPage:newAction()
    :title("yeeeee")
    :item("minecraft:oak_log")
    :hoverColor(1, 0, 1)
    :onLeftClick(pings.actionClicked)

---------------------------------------

local mount = require("EZMount")

local minecart = animations.minecart

local minecartList = {
	["still"] = minecart.still,
	["forward"] = minecart.forward,
	["backward"] = minecart.backward,
	["turnright"] = minecart.turnright,
	["turnleft"] = minecart.turnleft,
	["up"] = minecart.up,
	["down"] = minecart.down,
	["rear"] = minecart.rear,
}



-- mount:newLivingMount("mule",models.horse,headcubes,saddlecubes,bagcubes,armorcubes,armortex,animlist)
mount:newObjectMount("minecart",models.minecart,passengercubes,minecartList)

---------------------------------------------------
-- 引入眼球追踪API模块
local eyeTracking = require("eye-tracking-api")

-- 自定义配置参数（覆盖默认值）
eyeTracking.init({
    -- [!] 必须根据实际模型层级结构填写路径
    left_eye_path = "model.root.Torso.Head.Eyes.lefteye.leftpupil", -- 左眼瞳孔部件的完整路径（点分隔层级）
    right_eye_path = "model.root.Torso.Head.Eyes.righteye.rightpupil", -- 右眼瞳孔部件的完整路径
    head_part = "Head", -- 头部模型部件的名称（需与model文件中的部件名一致）

    -- [!] 参数调节区
    max_offset = 0.5, -- 瞳孔最大水平偏移量（单位：游戏内方块坐标，建议0.3~0.7）
    sensitivity = 35, -- 灵敏度系数（值越大响应越平缓，建议20~50）
    update_interval = 3, -- 更新间隔（单位：游戏刻，1秒=20刻，建议2~5）
    debug_mode = false -- 调试模式开关（true时输出实时数据）
})


-----------------------------------------------------
local sitting = require("SittingAPI") -- 引入API
-- 初始化（只需一次）
function events.TICK()
    sitting.init()
end

-----------------------------------------------------
local WetClass = require("Wet-control")

-----------------------------------------------------
local ChatBubble = require("chatbubble")
