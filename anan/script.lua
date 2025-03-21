-- Auto generated script file --

--hide vanilla model
vanilla_model.PLAYER:setVisible(false)

--hide vanilla armor model
vanilla_model.ARMOR:setVisible(false)

local anims = require("EZAnims")
local example = anims:addBBModel(animations.model)
anims:setFallVel(-1)
anims:setOneJump(true)

physBone = require('physBoneAPI')

function events.entity_init()
  physBone.physEar1:setSimSpeed(3)
  physBone.physEar2:setSimSpeed(3)
  physBone.physEar1:setSpringForce(70)
  physBone.physEar2:setSpringForce(70)
end


local mainPage = action_wheel:newPage()
action_wheel:setPage(mainPage)

function pings.actionClicked()
    animations.model.sit_down:play()
    -- animation example (commented out to avoid erroring):
    -- animations.bbmodelname.animationname:play()
end

local action = mainPage:newAction()
    :title("sit")
    :item("minecraft:oak_stairs")
    :hoverColor(1, 0, 1)
    :onLeftClick(pings.actionClicked)



