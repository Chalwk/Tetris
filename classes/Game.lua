local ipairs = ipairs
local math_floor = math.floor
local math_random = math.random
local math_min = math.min
local table_insert = table.insert
local table_remove = table.remove

local Game = {}
Game.__index = Game

-- Tetromino shapes and colors
local tetrominoes = {
    {
        shape = {
            { 1, 1, 1, 1 }
        },
        color = { 0.2, 0.8, 1 }, -- Cyan I
        name = "I"
    },
    {
        shape = {
            { 1, 1 },
            { 1, 1 }
        },
        color = { 1, 1, 0.2 }, -- Yellow O
        name = "O"
    },
    {
        shape = {
            { 0, 1, 0 },
            { 1, 1, 1 }
        },
        color = { 0.8, 0.2, 1 }, -- Purple T
        name = "T"
    },
    {
        shape = {
            { 1, 1, 0 },
            { 0, 1, 1 }
        },
        color = { 0.2, 1, 0.2 }, -- Green S
        name = "S"
    },
    {
        shape = {
            { 0, 1, 1 },
            { 1, 1, 0 }
        },
        color = { 1, 0.2, 0.2 }, -- Red Z
        name = "Z"
    },
    {
        shape = {
            { 1, 0, 0 },
            { 1, 1, 1 }
        },
        color = { 0.2, 0.2, 1 }, -- Blue J
        name = "J"
    },
    {
        shape = {
            { 0, 0, 1 },
            { 1, 1, 1 }
        },
        color = { 1, 0.6, 0.2 }, -- Orange L
        name = "L"
    }
}

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 1000
    instance.screenHeight = 800
    instance.boardWidth = 10
    instance.boardHeight = 20
    instance.cellSize = 30
    instance.board = {}
    instance.currentPiece = nil
    instance.nextPiece = nil
    instance.heldPiece = nil
    instance.canHold = true
    instance.gameOver = false
    instance.paused = false
    instance.score = 0
    instance.level = 1
    instance.lines = 0
    instance.fallSpeed = 1.0
    instance.fallTimer = 0
    instance.particles = {}
    instance.animations = {}
    instance.theme = "neon"

    instance.boardX = 0
    instance.boardY = 0

    instance:resetBoard()
    instance:newPiece()

    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateBoardPosition()
end

function Game:calculateBoardPosition()
    self.boardX = (self.screenWidth - (self.boardWidth * self.cellSize)) / 2
    self.boardY = (self.screenHeight - (self.boardHeight * self.cellSize)) / 2
end

function Game:resetBoard()
    self.board = {}
    for y = 1, self.boardHeight do
        self.board[y] = {}
        for x = 1, self.boardWidth do
            self.board[y][x] = { filled = false, color = { 0, 0, 0 } }
        end
    end
end

function Game:newPiece()
    self.currentPiece = self.nextPiece or self:getRandomPiece()
    self.nextPiece = self:getRandomPiece()
    self.currentPiece.x = math_floor(self.boardWidth / 2) - math_floor(#self.currentPiece.shape[1] / 2)
    self.currentPiece.y = 1
    self.canHold = true

    -- Check if game over
    if self:checkCollision(self.currentPiece.x, self.currentPiece.y, self.currentPiece.shape) then
        self.gameOver = true
    end
end

function Game:getRandomPiece()
    local piece = tetrominoes[math_random(1, #tetrominoes)]
    return {
        shape = self:copyTable(piece.shape),
        color = { piece.color[1], piece.color[2], piece.color[3] },
        name = piece.name,
        x = 0,
        y = 0
    }
end

function Game:copyTable(t)
    local copy = {}
    for i, v in ipairs(t) do
        if type(v) == "table" then
            copy[i] = self:copyTable(v)
        else
            copy[i] = v
        end
    end
    return copy
end

function Game:rotatePiece()
    if not self.currentPiece then return end

    local newShape = {}
    local oldShape = self.currentPiece.shape
    local rows = #oldShape
    local cols = #oldShape[1]

    -- Create rotated shape
    for i = 1, cols do
        newShape[i] = {}
        for j = 1, rows do
            newShape[i][j] = oldShape[rows - j + 1][i]
        end
    end

    -- Check if rotation is valid
    if not self:checkCollision(self.currentPiece.x, self.currentPiece.y, newShape) then
        self.currentPiece.shape = newShape
    end
end

function Game:movePiece(dx, dy)
    if not self.currentPiece or self.gameOver then return end

    if not self:checkCollision(self.currentPiece.x + dx, self.currentPiece.y + dy, self.currentPiece.shape) then
        self.currentPiece.x = self.currentPiece.x + dx
        self.currentPiece.y = self.currentPiece.y + dy
        return true
    end

    -- If moving down and collision, lock the piece
    if dy > 0 then
        self:lockPiece()
        self:clearLines()
        self:newPiece()
    end

    return false
end

function Game:hardDrop()
    if not self.currentPiece then return end

    while self:movePiece(0, 1) do
        -- Continue moving down until collision
    end
end

function Game:holdCurrentPiece()
    if not self.currentPiece or not self.canHold then return end

    if self.heldPiece then
        local temp = self.currentPiece
        self.currentPiece = self.heldPiece
        self.currentPiece.x = math_floor(self.boardWidth / 2) - math_floor(#self.currentPiece.shape[1] / 2)
        self.currentPiece.y = 1
        self.heldPiece = temp
    else
        self.heldPiece = self.currentPiece
        self:newPiece()
    end
    self.canHold = false
end

function Game:checkCollision(x, y, shape)
    for row = 1, #shape do
        for col = 1, #shape[row] do
            if shape[row][col] ~= 0 then
                local boardX = x + col - 1
                local boardY = y + row - 1

                if boardX < 1 or boardX > self.boardWidth or
                    boardY > self.boardHeight or
                    (boardY >= 1 and self.board[boardY] and self.board[boardY][boardX].filled) then
                    return true
                end
            end
        end
    end
    return false
end

function Game:lockPiece()
    for row = 1, #self.currentPiece.shape do
        for col = 1, #self.currentPiece.shape[row] do
            if self.currentPiece.shape[row][col] ~= 0 then
                local boardX = self.currentPiece.x + col - 1
                local boardY = self.currentPiece.y + row - 1

                if boardY >= 1 then
                    self.board[boardY][boardX] = {
                        filled = true,
                        color = { self.currentPiece.color[1], self.currentPiece.color[2], self.currentPiece.color[3] }
                    }
                end
            end
        end
    end

    -- Create lock particles
    self:createLockParticles()
end

function Game:clearLines()
    local linesCleared = 0

    for y = self.boardHeight, 1, -1 do
        local fullLine = true
        for x = 1, self.boardWidth do
            if not self.board[y][x].filled then
                fullLine = false
                break
            end
        end

        if fullLine then
            linesCleared = linesCleared + 1

            -- Create clear animation
            self:createClearAnimation(y)

            -- Remove the line
            table_remove(self.board, y)

            -- Add new empty line at top
            local newLine = {}
            for x = 1, self.boardWidth do
                newLine[x] = { filled = false, color = { 0, 0, 0 } }
            end
            table_insert(self.board, 1, newLine)
        end
    end

    if linesCleared > 0 then
        self:addScore(linesCleared)
        self.lines = self.lines + linesCleared
        self.level = math_floor(self.lines / 10) + 1
        self.fallSpeed = 1.0 / self.level
    end
end

function Game:addScore(lines)
    local lineScores = { 100, 300, 500, 800 } -- Single, Double, Triple, Tetris
    self.score = self.score + (lineScores[lines] or 1000) * self.level
end

function Game:createLockParticles()
    for row = 1, #self.currentPiece.shape do
        for col = 1, #self.currentPiece.shape[row] do
            if self.currentPiece.shape[row][col] ~= 0 then
                local x = self.boardX + (self.currentPiece.x + col - 1) * self.cellSize + self.cellSize / 2
                local y = self.boardY + (self.currentPiece.y + row - 1) * self.cellSize + self.cellSize / 2

                for _ = 1, 3 do
                    table_insert(self.particles, {
                        x = x,
                        y = y,
                        dx = (math_random() - 0.5) * 100,
                        dy = (math_random() - 0.5) * 100,
                        life = math_random(0.5, 1.0),
                        color = { self.currentPiece.color[1], self.currentPiece.color[2], self.currentPiece.color[3] },
                        size = math_random(2, 5)
                    })
                end
            end
        end
    end
end

function Game:createClearAnimation(line)
    table_insert(self.animations, {
        type = "line_clear",
        line = line,
        progress = 0,
        duration = 0.5
    })
end

function Game:update(dt)
    if self.gameOver or self.paused then return end

    self.fallTimer = self.fallTimer + dt

    -- Auto fall
    if self.fallTimer >= self.fallSpeed then
        self:movePiece(0, 1)
        self.fallTimer = 0
    end

    -- Update particles
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt

        if particle.life <= 0 then
            table_remove(self.particles, i)
        end
    end

    -- Update animations
    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        anim.progress = anim.progress + dt / anim.duration
        if anim.progress >= 1 then
            table_remove(self.animations, i)
        end
    end
end

function Game:startNewGame(difficulty, theme)
    self.difficulty = difficulty or "normal"
    self.theme = theme or "neon"
    self:resetGame()
end

function Game:resetGame()
    self:resetBoard()
    self.currentPiece = nil
    self.nextPiece = nil
    self.heldPiece = nil
    self.canHold = true
    self.gameOver = false
    self.paused = false
    self.score = 0
    self.level = 1
    self.lines = 0
    self.fallSpeed = 1.0
    self.fallTimer = 0
    self.particles = {}
    self.animations = {}
    self:newPiece()
end

function Game:draw()
    self:drawBoard()
    self:drawUI()
    self:drawParticles()

    if self.gameOver then
        self:drawGameOver()
    end
end

function Game:drawBoard()
    -- Draw board background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", self.boardX - 10, self.boardY - 10,
        self.boardWidth * self.cellSize + 20,
        self.boardHeight * self.cellSize + 20, 5)

    -- Draw board border
    love.graphics.setColor(0.3, 0.5, 0.8, 0.6)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", self.boardX - 10, self.boardY - 10,
        self.boardWidth * self.cellSize + 20,
        self.boardHeight * self.cellSize + 20, 5)
    love.graphics.setLineWidth(1)

    -- Draw placed blocks
    for y = 1, self.boardHeight do
        for x = 1, self.boardWidth do
            if self.board[y][x].filled then
                self:drawBlock(x, y, self.board[y][x].color)
            end
        end
    end

    -- Draw current piece
    if self.currentPiece then
        for row = 1, #self.currentPiece.shape do
            for col = 1, #self.currentPiece.shape[row] do
                if self.currentPiece.shape[row][col] ~= 0 then
                    local x = self.currentPiece.x + col - 1
                    local y = self.currentPiece.y + row - 1
                    if y >= 1 then
                        self:drawBlock(x, y, self.currentPiece.color)
                    end
                end
            end
        end
    end

    -- Draw grid
    love.graphics.setColor(0.3, 0.3, 0.4, 0.3)
    for x = 0, self.boardWidth do
        love.graphics.line(
            self.boardX + x * self.cellSize, self.boardY,
            self.boardX + x * self.cellSize, self.boardY + self.boardHeight * self.cellSize
        )
    end
    for y = 0, self.boardHeight do
        love.graphics.line(
            self.boardX, self.boardY + y * self.cellSize,
            self.boardX + self.boardWidth * self.cellSize, self.boardY + y * self.cellSize
        )
    end
end

function Game:drawBlock(x, y, color)
    local blockX = self.boardX + (x - 1) * self.cellSize
    local blockY = self.boardY + (y - 1) * self.cellSize

    -- Block fill
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("fill", blockX + 1, blockY + 1, self.cellSize - 2, self.cellSize - 2, 3)

    -- Block highlight
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("fill", blockX + 2, blockY + 2, self.cellSize - 6, 4, 2)
    love.graphics.rectangle("fill", blockX + 2, blockY + 2, 4, self.cellSize - 6, 2)

    -- Block shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", blockX + self.cellSize - 6, blockY + 6, 4, self.cellSize - 8, 2)
    love.graphics.rectangle("fill", blockX + 6, blockY + self.cellSize - 6, self.cellSize - 8, 4, 2)
end

function Game:drawUI()
    local sidePanelX = self.boardX + self.boardWidth * self.cellSize + 30
    local sidePanelWidth = 200

    -- Next piece preview
    love.graphics.setColor(0.1, 0.15, 0.25, 0.8)
    love.graphics.rectangle("fill", sidePanelX, self.boardY, sidePanelWidth, 150, 8)

    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("NEXT", sidePanelX + 20, self.boardY + 15)

    if self.nextPiece then
        local previewX = sidePanelX + 60
        local previewY = self.boardY + 60

        for row = 1, #self.nextPiece.shape do
            for col = 1, #self.nextPiece.shape[row] do
                if self.nextPiece.shape[row][col] ~= 0 then
                    love.graphics.setColor(self.nextPiece.color[1], self.nextPiece.color[2], self.nextPiece.color[3], 0.8)
                    love.graphics.rectangle("fill",
                        previewX + (col - 1) * 20,
                        previewY + (row - 1) * 20,
                        18, 18, 3)
                end
            end
        end
    end

    -- Hold piece
    love.graphics.setColor(0.1, 0.15, 0.25, 0.8)
    love.graphics.rectangle("fill", sidePanelX, self.boardY + 180, sidePanelWidth, 150, 8)

    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("HOLD", sidePanelX + 20, self.boardY + 195)

    if self.heldPiece then
        local holdX = sidePanelX + 60
        local holdY = self.boardY + 225

        for row = 1, #self.heldPiece.shape do
            for col = 1, #self.heldPiece.shape[row] do
                if self.heldPiece.shape[row][col] ~= 0 then
                    love.graphics.setColor(self.heldPiece.color[1], self.heldPiece.color[2], self.heldPiece.color[3], 0.8)
                    love.graphics.rectangle("fill",
                        holdX + (col - 1) * 20,
                        holdY + (row - 1) * 20,
                        18, 18, 3)
                end
            end
        end
    end

    -- Stats panel
    love.graphics.setColor(0.1, 0.15, 0.25, 0.8)
    love.graphics.rectangle("fill", sidePanelX, self.boardY + 360, sidePanelWidth, 260, 8)

    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.print("SCORE: " .. self.score, sidePanelX + 20, self.boardY + 380)
    love.graphics.print("LINES: " .. self.lines, sidePanelX + 20, self.boardY + 410)
    love.graphics.print("LEVEL: " .. self.level, sidePanelX + 20, self.boardY + 440)
    love.graphics.print("SPEED: " .. string.format("%.1f", self.fallSpeed), sidePanelX + 20, self.boardY + 470)

    -- Controls help
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("CONTROLS:", sidePanelX + 20, self.boardY + 510)
    love.graphics.print("Arrow Keys - Move", sidePanelX + 20, self.boardY + 530)
    love.graphics.print("WASD - Move & Rotate", sidePanelX + 20, self.boardY + 550)
    love.graphics.print("Space - Hard Drop", sidePanelX + 20, self.boardY + 570)
    love.graphics.print("C - Hold Piece", sidePanelX + 20, self.boardY + 590)
end

function Game:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = math_min(1, particle.life * 2)
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end

function Game:drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("GAME OVER", 0, self.screenHeight / 2 - 60, self.screenWidth, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Final Score: " .. self.score, 0, self.screenHeight / 2, self.screenWidth, "center")
    love.graphics.printf("Lines Cleared: " .. self.lines, 0, self.screenHeight / 2 + 40, self.screenWidth, "center")

    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("Click to return to menu", 0, self.screenHeight / 2 + 100, self.screenWidth, "center")
end

function Game:isGameOver()
    return self.gameOver
end

return Game
