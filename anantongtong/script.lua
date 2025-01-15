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







