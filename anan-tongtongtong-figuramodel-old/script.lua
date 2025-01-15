-- Auto generated script file --

--hide vanilla model
vanilla_model.PLAYER:setVisible(false)

--hide vanilla armor model
vanilla_model.ARMOR:setVisible(false)

local anims = require('JimmyAnims')
anims.excluBlendTime = 4
anims.incluBlendTime = 4
anims.autoBlend = true
anims.dismiss = false
anims.addExcluAnimsController()
anims.addIncluAnimsController()
anims.addAllAnimsController()
anims(animations.model)


local mainPage = action_wheel:newPage()
local secondPage = action_wheel:newPage() -- make sure you save the pages to unique variables
action_wheel:setPage(mainPage) -- this is setting the page you'll see when you first open the wheel to mainPage
local toSecond = mainPage:newAction()



local mainPage = action_wheel:newPage()
local secondPage = action_wheel:newPage() -- make sure you save the pages to unique variables
action_wheel:setPage(mainPage) -- this is setting the page you'll see when you first open the wheel to mainPage
local toSecond = mainPage:newAction()
    :title("disabletongtong")
    :item("red_wool")
    :onLeftClick(function()
    -- this is a new action on mainPage. its purpose will be to swap to secondPage
    -- this doesn't need to be pinged
	models.model.Tongtong:setVisible(true)
    action_wheel:setPage(secondPage)
end)

local toMain = secondPage:newAction()
    :title("enabletongtong")
    :item("green_wool")
    :onLeftClick(function()
    -- this is a new action on secondPage. its purpose will be to swap to mainPage
    models.model.Tongtong:setVisible(false)
    action_wheel:setPage(mainPage)
    end)


