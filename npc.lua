local NPC = {}
NPC.__index = NPC

ActiveNPCs = {}
local Player = require("player")
local Anima = require("myTextAnima")
local Dialogue = require("dialogue")
local GUI = require("gui")
local Helper = require("helper")

--@param type: string "princess" or "nicoRobin"
function NPC.new(x, y, type)
    local instance = setmetatable({}, NPC)

    instance.x = x
    instance.y = y
    instance.type = type

    instance.state = "idle"
    instance.idleTime = { current = 0, duration = 3} -- robin

    -- Animations
    instance.animation = { timer = 0, rate = 0.2 }
    instance.animation.npc = { total = 4, current = 1, img = NPC.princessAnim } -- change this to princess later
    instance:updateAnimationImgType() -- remove this later
    instance.animation.draw = instance.animation.npc.img[1]

    -- Physics
    instance.physics = {}
    instance.physics.body = love.physics.newBody(World, instance.x, instance.y, "static")
    instance.physics.shape = love.physics.newRectangleShape(instance.width, instance.height)
    instance.physics.fixture = love.physics.newFixture(instance.physics.body, instance.physics.shape)
    instance.physics.fixture:setSensor(true) -- prevents collisions but can be sensed
    instance.physics.fixture:setUserData("npc")

    -- dialogue
    instance.interactText = Anima.new(instance.physics.fixture, Dialogue[instance.type].message, "above")
    instance.dialogue = Dialogue[instance.type].sequence
    instance.dialogueIndex = 0
    instance.dialogueGrace = { time = 2, duration = 2 }

    table.insert(ActiveNPCs, instance)
end

function NPC.loadAssets()
    NPC.princessAnim = {}
    for i = 1, 4 do
        NPC.princessAnim[i] = love.graphics.newImage("assets/princess/idle/" .. i .. ".png")
    end

    NPC.width = NPC.princessAnim[1]:getWidth()
    NPC.height = NPC.princessAnim[1]:getHeight()
end

-- changes the animation image based on the NPC type, necessary for NPCs that have different animations
function NPC:updateAnimationImgType()
    if self.type == "princess" then
        self.animation.npc.total = 4
        self.animation.npc.img = NPC.princessAnim
    end
end

function NPC.removeAll()
    for _, v in ipairs(ActiveNPCs) do
        v.physics.body:destroy()
        Anima.remove(v.physics.fixture)
    end

    ActiveNPCs = {}
end

function NPC:setState(dt)
    if self.type == "NicoRobin" then
        self:setNicoRobinState(dt)
    end
end

function NPC:setNicoRobinState(dt)
    if self.state == "idle" then
        self.idleTime.current = self.idleTime.current + dt
        if self.idleTime.current >= self.idleTime.duration then
            self.state = "sittingDown"
        end
    elseif self.state == "sittingDown"
    and self.animation.sittingDown.current >= self.animation.sittingDown.total then
        self.state = "reading"
    end
end

function NPC:update(dt)
    self:setState(dt)
    self:animate(dt)
end

function NPC:animate(dt)
    self.animation.timer = self.animation.timer + dt
    if self.animation.timer > self.animation.rate then
        self.animation.timer = 0
        self:setNewFrame()
    end
end

-- updates the image
function NPC:setNewFrame()
    local anim = self.animation.npc
    if anim.current < anim.total then
        anim.current = anim.current + 1
    else
        anim.current = 1
    end
    self.animation.draw = anim.img[anim.current]
end

function NPC:draw()
    love.graphics.draw(self.animation.draw, self.x, self.y, 0, self.scaleX, 1, self.width / 2, self.height / 2)
end

function NPC.updateAll(dt)
    for i, instance in ipairs(ActiveNPCs) do
        instance:update(dt)
    end
end

function NPC:runDialogue(dt)
    if Player.talking and self.interactable then
        if not Anima.currentlyAnimating() then
            if self.dialogueGrace.time == self.dialogueGrace.duration then
                local playerAnima = Player.interactText
                local originalPlayerAnimaText = playerAnima.text
                playerAnima:modifyAnimationRate(0.1)
    
                local npcAnima = self.interactText
                local originalNPCAnimaText = npcAnima.text

                self.dialogueIndex = self.dialogueIndex + 1
                if self.dialogueIndex <= #self.dialogue then
                    if self.dialogue[self.dialogueIndex][1] ~= "Player" then
                        npcAnima:newTypingAnimation(self.dialogue[self.dialogueIndex][2])
                    elseif self.dialogue[self.dialogueIndex][1] == "Player" then
                        playerAnima:newTypingAnimation(self.dialogue[self.dialogueIndex][2])
                    end
                    print(self.dialogue[self.dialogueIndex][2])
                end

                if self.dialogueIndex > #self.dialogue then
                    self.dialogueIndex = 1
                    playerAnima:modifyAnimationRate(0)
                    playerAnima:newTypingAnimation("interact (E)")
                    npcAnima:newTypingAnimation("Hey Franky!")
                    Player.talking = false
                    GUI:goNextLevelIndicatorAnimationStart()
                end
            end
            self.dialogueGrace.time = self.dialogueGrace.time - dt
            if self.dialogueGrace.time <= 0 then
                self.dialogueGrace.time = self.dialogueGrace.duration
            end
        end
    end
end

function NPC.interact(key)
    if not Player:doingAction() and key == "e" then
        for _, instance in ipairs(ActiveNPCs) do
            if instance.interactable then
                Player.talking = true
                Player.interactText:newTypingAnimation("")
                Player:setPosition(instance.x - instance.width / 2, instance.y)
                Player.xVel = 0
                Player.direction = "right"
                Player:cancelActiveActions()
                return true
            end
        end
    end
end

function NPC.drawAll()
    for i, instance in ipairs(ActiveNPCs) do
        instance:draw()
    end
end

function NPC.beginContact(a, b, collision)
    if Helper.checkFUD(a, b, "player") and Helper.checkFUD(a, b, "npc") then
        for i, instance in ipairs(ActiveNPCs) do
            print("looking through NPCs")
            if a == instance.physics.fixture or b == instance.physics.fixture then
                print("found the NPC")
                if a == Player.physics.fixture or b == Player.physics.fixture then
                    print("found the player")
                    instance.interactText:animationStart()
                    Player.interactText:animationStart()
                    return true
                end
            end
        end
    end
end

function NPC.endContact(a, b, collision)
    for i, instance in ipairs(ActiveNPCs) do
        if a == instance.physics.fixture or b == instance.physics.fixture then
            if a == Player.physics.fixture or b == Player.physics.fixture then
                instance.interactText:animationEnd()
                Player.interactText:animationEnd()
                return true
            end
        end
    end
end

return NPC