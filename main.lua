local Game = require("classes/Game")
local Menu = require("classes/Menu")
local BackgroundManager = require("classes/BackgroundManager")

local game, menu, backgroundManager
local screenWidth, screenHeight
local gameState = "menu"

local function updateScreenSize()
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
end

function love.load()
    love.window.setTitle("Tetris")
    love.graphics.setLineStyle("smooth")
    love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))

    game = Game.new()
    menu = Menu.new()
    backgroundManager = BackgroundManager.new()

    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end

function love.update(dt)
    updateScreenSize()

    if gameState == "playing" then
        game:update(dt)
    elseif gameState == "menu" or gameState == "options" then
        menu:update(dt, screenWidth, screenHeight)
    end

    backgroundManager:update(dt)
end

function love.draw()
    if gameState == "menu" or gameState == "options" then
        backgroundManager:drawMenuBackground(screenWidth, screenHeight)
    elseif gameState == "playing" then
        backgroundManager:drawGameBackground(screenWidth, screenHeight)
    end

    if gameState == "menu" or gameState == "options" then
        menu:draw(screenWidth, screenHeight, gameState)
    elseif gameState == "playing" then
        game:draw()
    end
end

function love.mousepressed(x, y, button, istouch)
    if gameState == "menu" then
        local action = menu:handleClick(x, y, "menu")
        if action == "start" then
            gameState = "playing"
            game:startNewGame(menu:getDifficulty(), menu:getTheme())
        elseif action == "options" then
            gameState = "options"
        elseif action == "quit" then
            love.event.quit()
        end
    elseif gameState == "options" then
        local action = menu:handleClick(x, y, "options")
        if action == "back" then
            gameState = "menu"
        elseif action:sub(1, 11) == "difficulty " then
            menu:setDifficulty(action:sub(12))
        elseif action:sub(1, 6) == "theme " then
            menu:setTheme(action:sub(7))
        end
    elseif gameState == "playing" then
        if game:isGameOver() then
            gameState = "menu"
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "playing" or gameState == "options" then
            gameState = "menu"
        else
            love.event.quit()
        end
    elseif key == "r" and gameState == "playing" then
        game:resetGame()
    elseif gameState == "playing" then
        if key == "left" or key == "a" then
            game:movePiece(-1, 0)
        elseif key == "right" or key == "d" then
            game:movePiece(1, 0)
        elseif key == "down" or key == "s" then
            game:movePiece(0, 1)
        elseif key == "up" or key == "w" then
            game:rotatePiece()
        elseif key == "space" then
            game:hardDrop()
        elseif key == "c" then
            game:holdCurrentPiece()
        end
    end
end

function love.resize(w, h)
    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end