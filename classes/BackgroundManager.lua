local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

-- Tetromino shapes for background
local tetrominoShapes = {
    -- I piece
    {
        { 1, 1, 1, 1 }
    },
    -- O piece
    {
        { 1, 1 },
        { 1, 1 }
    },
    -- T piece
    {
        { 0, 1, 0 },
        { 1, 1, 1 }
    },
    -- S piece
    {
        { 0, 1, 1 },
        { 1, 1, 0 }
    },
    -- Z piece
    {
        { 1, 1, 0 },
        { 0, 1, 1 }
    },
    -- J piece
    {
        { 1, 0, 0 },
        { 1, 1, 1 }
    },
    -- L piece
    {
        { 0, 0, 1 },
        { 1, 1, 1 }
    }
}

local tetrominoColors = {
    { 0.2, 0.8, 1 }, -- Cyan I
    { 1,   1,   0.2 }, -- Yellow O
    { 0.8, 0.2, 1 }, -- Purple T
    { 0.2, 1,   0.2 }, -- Green S
    { 1,   0.2, 0.2 }, -- Red Z
    { 0.2, 0.2, 1 }, -- Blue J
    { 1,   0.6, 0.2 } -- Orange L
}

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.menuParticles = {}
    instance.backgroundTetrominos = {}
    instance.time = 0
    instance.gridSize = 40
    instance:initMenuParticles()
    instance:initBackgroundTetrominos()
    return instance
end

function BackgroundManager:initMenuParticles()
    self.menuParticles = {}
    for _ = 1, 60 do
        table_insert(self.menuParticles, {
            x = math_random() * 1200,
            y = math_random() * 1200,
            size = math_random(4, 10),
            speed = math_random(20, 50),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.3, 1.5),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 4),
            color = { math_random(0.5, 0.9), math_random(0.4, 0.8), math_random(0.6, 1), math_random(0.4, 0.8) },
            shape = math_random(1, 3)
        })
    end
end

function BackgroundManager:initBackgroundTetrominos()
    self.backgroundTetrominos = {}
    for _ = 1, 15 do
        local shapeIndex = math_random(1, #tetrominoShapes)
        local shape = tetrominoShapes[shapeIndex]
        local color = tetrominoColors[shapeIndex]

        table_insert(self.backgroundTetrominos, {
            x = math_random() * 1200,
            y = math_random() * 1200,
            shape = shape,
            color = { color[1], color[2], color[3] },
            speed = math_random(10, 30),
            rotation = 0,
            rotationSpeed = math_random(-1, 1),
            scale = math_random(0.8, 1.5),
            alpha = math_random(0.1, 0.3),
            pulseSpeed = math_random(0.5, 2),
            pulsePhase = math_random() * math_pi * 2
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    -- Update menu particles
    for _, particle in ipairs(self.menuParticles) do
        particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
        particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

        if particle.x < -50 then particle.x = 1250 end
        if particle.x > 1250 then particle.x = -50 end
        if particle.y < -50 then particle.y = 1250 end
        if particle.y > 1250 then particle.y = -50 end
    end

    -- Update background tetrominos
    for _, tetromino in ipairs(self.backgroundTetrominos) do
        tetromino.y = tetromino.y + tetromino.speed * dt
        tetromino.rotation = tetromino.rotation + tetromino.rotationSpeed * dt

        -- Reset tetromino when it goes off screen
        if tetromino.y > 1300 then
            tetromino.y = -100
            tetromino.x = math_random() * 1200
        end
    end
end

function BackgroundManager:drawMenuBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    -- Gradient background
    for y = 0, screenHeight, 3 do
        local progress = y / screenHeight
        local wave = math_sin(time * 1.5 + progress * 10) * 0.05
        local r = 0.08 + progress * 0.1 + wave
        local g = 0.05 + progress * 0.15 + wave
        local b = 0.12 + progress * 0.2 + wave
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.rectangle("fill", 0, y, screenWidth, 3)
    end

    -- Particles
    for _, particle in ipairs(self.menuParticles) do
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.4
        local alpha = 0.3 + pulse * 0.4
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        if particle.shape == 1 then
            love.graphics.rectangle("fill", particle.x, particle.y, particle.size, particle.size)
        elseif particle.shape == 2 then
            love.graphics.circle("fill", particle.x, particle.y, particle.size / 2)
        else
            love.graphics.polygon("fill",
                particle.x, particle.y - particle.size / 2,
                particle.x + particle.size / 2, particle.y + particle.size / 2,
                particle.x - particle.size / 2, particle.y + particle.size / 2
            )
        end
    end

    -- Grid overlay
    love.graphics.setColor(0.3, 0.5, 0.8, 0.1)
    local gridSize = 60
    for x = 0, screenWidth, gridSize do
        for y = 0, screenHeight, gridSize do
            love.graphics.rectangle("line", x, y, gridSize, gridSize)
        end
    end
end

function BackgroundManager:drawGameBackground(screenWidth, screenHeight)
    local time = love.timer.getTime()

    -- Dark blue gradient background
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local wave = math_sin(time * 2 + progress * 8) * 0.03
        local r = 0.05 + wave
        local g = 0.07 + progress * 0.1 + wave
        local b = 0.1 + progress * 0.15 + wave
        love.graphics.setColor(r, g, b, 0.95)
        love.graphics.rectangle("fill", 0, y, screenWidth, 2)
    end

    -- Draw subtle grid pattern
    love.graphics.setColor(0.2, 0.3, 0.4, 0.15)
    local gridSize = self.gridSize
    for x = 0, screenWidth, gridSize do
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, gridSize do
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Draw background tetrominos
    for _, tetromino in ipairs(self.backgroundTetrominos) do
        local pulse = (math_sin(tetromino.pulsePhase + time * tetromino.pulseSpeed) + 1) * 0.1
        local alpha = tetromino.alpha + pulse * 0.1

        love.graphics.push()
        love.graphics.translate(tetromino.x, tetromino.y)
        love.graphics.rotate(tetromino.rotation)
        love.graphics.scale(tetromino.scale, tetromino.scale)

        local blockSize = 8
        for row = 1, #tetromino.shape do
            for col = 1, #tetromino.shape[row] do
                if tetromino.shape[row][col] ~= 0 then
                    local x = (col - 1) * blockSize
                    local y = (row - 1) * blockSize

                    -- Block fill
                    love.graphics.setColor(tetromino.color[1], tetromino.color[2], tetromino.color[3], alpha)
                    love.graphics.rectangle("fill", x, y, blockSize, blockSize, 1)

                    -- Block outline
                    love.graphics.setColor(1, 1, 1, alpha * 0.5)
                    love.graphics.rectangle("line", x, y, blockSize, blockSize, 1)
                end
            end
        end

        love.graphics.pop()
    end

    -- Subtle border
    love.graphics.setColor(0.2, 0.3, 0.5, 0.3)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 5, 5, screenWidth - 10, screenHeight - 10)
    love.graphics.setLineWidth(1)
end

return BackgroundManager
