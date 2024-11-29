love.graphics.setDefaultFilter("nearest", "nearest") -- only needs to be done because pixel art
local Player = require("player")
local GUI = require("gui")
local Camera = require("camera")
local Map = require("map")
local Sounds = require("sounds")
local Explosion = require("explosion")
local Smoke = require("smoke")
local Aura = require("aura")
local Menu = require("menu")
local Hitbox = require("hitbox")
local Portal = require("portal")
local Anima = require("myTextAnima")
local BackgroundObject = require("backgroundObject")
local PickupItem = require("pickupItem")
local Recipes = require("recipes")
local NPC = require("npc")
WorldPause = false

function love.load()
    Sounds:load()
    Portal.loadAssets()
    Explosion.loadAssets()
    Smoke.loadAssets()
    Aura.loadAssets()
    NPC.loadAssets() -- rule of thumb: assets need to load before the map
    Map:load()
    GUI:load()
    Player:load()
    Menu:load()
    Recipes:load()
end

-- menu screen toggle update to pause game
function love.update(dt)
    if not WorldPause then
        World:update(dt)
        Sounds:update(dt)
        Camera:setPosition(Player.x, Player.y)
        Player:update(dt)
        PickupItem.updateAll()
        GUI:update(dt)
        Portal.updateAll(dt)
        Explosion.updateAll(dt)
        Smoke.updateAll(dt)
        Aura.updateAll(dt)
        Map:update(dt)
        Menu:update(dt)
        Hitbox.updateAll(dt)
        Anima.updateAll(dt)
        BackgroundObject.updateAll(dt)
        NPC.updateAll(dt)
    end
end

function love.draw()
    Map:drawBackground()

    Camera:apply() -- between
    BackgroundObject.drawAll()
    Map.level:draw(-Camera.x, -Camera.y, Camera.scale, Camera.scale)
    Explosion.drawAll()
    Portal.drawAll()
    NPC.drawAll()
    Player:draw()
    PickupItem.drawAll()
    Aura.drawAll()
    Smoke.drawAll()
    Hitbox.drawAll()
    Anima.drawAll()
    Camera:clear() -- these

    GUI:draw()
    Menu:draw()
end

function love.keypressed(key)
    if not WorldPause then
        if Map.moveThroughPortal(key) then return end
        if NPC.interact(key) then return end
        Player:keypressed(key)
    end

    Menu:Escape(key)
end

function love.mousepressed(mx, my, button)
    GUI:mousepressed(mx, my, button)
    Menu:mousepressed(mx, my, button)
end

function beginContact(a, b, collision)
    if PickupItem.beginContact(a, b, collision) then return end
    if Hitbox.beginContact(a, b, collision) then return end
    if Portal.beginContact(a, b, collision) then return end
    if NPC.beginContact(a, b, collision) then return end
    Player:beginContact(a, b, collision)
end

function endContact(a, b, collision)
    if Hitbox.endContact(a, b, collision) then return end
    if Portal.endContact(a, b, collision) then return end
    if NPC.endContact(a, b, collision) then return end
    Player:endContact(a, b, collision)
end
