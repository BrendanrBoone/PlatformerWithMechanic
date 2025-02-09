local ScreenTransition = {}

local Player = require("player")

function ScreenTransition:load()
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()

    self.state = "null" -- 3 states: "null", "open", "close"
    self.animation = { timer = 0, rate = 0.1 }
    
    self.xCenter = self.screenWidth - self.screenWidth / 2 -- Centering the square
    self.yCenter = self.screenHeight - self.screenHeight / 2 -- Centering the square
    self.x, self.y = 0, 0

    self:loadAssets()
end

function ScreenTransition:loadAssets()
    self.animAssets = {}
    local maxCircleSize = self.screenHeight

    --black
    self.animAssets.black = {}
    self.animAssets.black.current = 1
    self.animAssets.black.total = 2
    self.animAssets.black.circleSize = {}
    self.animAssets.black.circleSize[1] = 0
    self.animAssets.black.circleSize[2] = 0

    --open
    self.animAssets.open = {}
    self.animAssets.open.current = 1
    self.animAssets.open.circleSize = {}
    for i=1, maxCircleSize/5 do
        self.animAssets.open.circleSize[i] = i * 5
    end
    self.animAssets.open.total = #self.animAssets.open.circleSize

    --close
    self.animAssets.close = {}
    self.animAssets.close.current = 1
    self.animAssets.close.circleSize = {}
    for i=1, maxCircleSize/5 do
        self.animAssets.close.circleSize[i] = maxCircleSize - i * 5
    end
    self.animAssets.close.total = #self.animAssets.close.circleSize

    self.curCircleSize = maxCircleSize
end

function ScreenTransition:update(dt)
    self:animate(dt)
end

function ScreenTransition:animate(dt)
    if self.state ~= "null" then
        self:setNewFrame()
    end
end

function ScreenTransition:setNewFrame()
    local anim = ScreenTransition.animAssets[self.state]
    if anim.current < anim.total then
        anim.current = anim.current + 1
    else
        self:transitionState(anim)
    end
    self.curCircleSize = anim.circleSize[anim.current]
end

function ScreenTransition:transitionState(anim)
    if self.state == "close" then
        self.state = "black"
        anim.current = 1
    elseif self.state == "open" then
        self.state = "null"
        anim.current = 1
        Player.actionable = true
    end
end

-- start screen transition with close()
function ScreenTransition:close()
    self.state = "close"
    Player.actionable = false
end

function ScreenTransition:open()
    self.state = "open"
end

function ScreenTransition:draw()
    if self.state ~= "null" then
        love.graphics.setColor(0, 0, 0)
        love.graphics.stencil(function()
            love.graphics.circle("fill", self.x + self.xCenter, self.y + self.yCenter, self.curCircleSize)
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.rectangle("fill", self.x, self.y, self.screenWidth, self.screenHeight)
        love.graphics.setStencilTest()
        love.graphics.setColor(1, 1, 1)
    end
end

return ScreenTransition