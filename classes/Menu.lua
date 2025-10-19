local ipairs = ipairs
local math_sin = math.sin

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 1000
    instance.screenHeight = 800
    instance.difficulty = "normal"
    instance.theme = "neon"
    instance.title = {
        text = "Tetris",
        subtitle = "A modern experience",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.15,
        minScale = 0.98,
        maxScale = 1.02,
        pulse = 0
    }

    instance.smallFont = love.graphics.newFont(16)
    instance.mediumFont = love.graphics.newFont(24)
    instance.largeFont = love.graphics.newFont(64)
    instance.subtitleFont = love.graphics.newFont(28)

    instance:createMenuButtons()
    instance:createOptionsButtons()

    return instance
end

function Menu:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:updateButtonPositions()
end

function Menu:createMenuButtons()
    self.menuButtons = {
        {
            text = "Start Game",
            action = "start",
            width = 220,
            height = 50,
            x = 0,
            y = 0,
            color = {0.2, 0.8, 0.4}
        },
        {
            text = "Options",
            action = "options",
            width = 220,
            height = 50,
            x = 0,
            y = 0,
            color = {0.4, 0.6, 1}
        },
        {
            text = "Quit",
            action = "quit",
            width = 220,
            height = 50,
            x = 0,
            y = 0,
            color = {1, 0.4, 0.4}
        }
    }
    self:updateButtonPositions()
end

function Menu:createOptionsButtons()
    self.optionsButtons = {
        {
            text = "Easy",
            action = "difficulty easy",
            width = 120,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Normal",
            action = "difficulty normal",
            width = 120,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Expert",
            action = "difficulty expert",
            width = 120,
            height = 40,
            x = 0,
            y = 0,
            section = "difficulty"
        },
        {
            text = "Neon",
            action = "theme neon",
            width = 140,
            height = 40,
            x = 0,
            y = 0,
            section = "theme"
        },
        {
            text = "Matrix",
            action = "theme matrix",
            width = 140,
            height = 40,
            x = 0,
            y = 0,
            section = "theme"
        },
        {
            text = "Retro",
            action = "theme retro",
            width = 140,
            height = 40,
            x = 0,
            y = 0,
            section = "theme"
        },
        {
            text = "Back",
            action = "back",
            width = 120,
            height = 40,
            x = 0,
            y = 0,
            section = "navigation"
        }
    }
    self:updateOptionsButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = self.screenHeight / 2 + 40
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 65
    end
end

function Menu:updateOptionsButtonPositions()
    local centerX = self.screenWidth / 2
    local startY = self.screenHeight / 2

    -- Difficulty buttons
    local diffTotalWidth = 360
    local diffStartX = centerX - diffTotalWidth / 2
    for i = 1, 3 do
        self.optionsButtons[i].x = diffStartX + (i-1) * 120
        self.optionsButtons[i].y = startY - 20
    end

    -- Theme buttons
    local themeTotalWidth = 420
    local themeStartX = centerX - themeTotalWidth / 2
    for i = 4, 6 do
        self.optionsButtons[i].x = themeStartX + (i-4) * 140
        self.optionsButtons[i].y = startY + 40
    end

    -- Back button
    self.optionsButtons[7].x = centerX - 60
    self.optionsButtons[7].y = startY + 100
end

function Menu:update(dt, screenWidth, screenHeight)
    if screenWidth ~= self.screenWidth or screenHeight ~= self.screenHeight then
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self:updateButtonPositions()
        self:updateOptionsButtonPositions()
    end

    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt
    self.title.pulse = self.title.pulse + dt * 2

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end
end

function Menu:draw(screenWidth, screenHeight, state)
    local pulse = (math_sin(self.title.pulse) + 1) * 0.15

    -- Title
    love.graphics.setColor(0.3 + pulse, 0.7 + pulse, 1, 1)
    love.graphics.setFont(self.largeFont)
    love.graphics.printf(self.title.text, 0, screenHeight / 4 - 50, screenWidth, "center")

    -- Subtitle
    love.graphics.setColor(0.8, 0.9, 1, 0.8)
    love.graphics.setFont(self.subtitleFont)
    love.graphics.printf(self.title.subtitle, 0, screenHeight / 4 + 30, screenWidth, "center")

    if state == "menu" then
        self:drawMenuButtons()

        love.graphics.setColor(0.9, 0.9, 1, 0.7)
        love.graphics.setFont(self.smallFont)
        love.graphics.printf("Rotate • Clear Lines • Survive", 0, screenHeight / 2 - 30, screenWidth, "center")

    elseif state == "options" then
        self:drawOptionsInterface()
    end

    -- Footer
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("Tetris by Jericho Crosby (Chalwk)", 10, screenHeight - 25, screenWidth - 20, "center")
end

function Menu:drawOptionsInterface()
    love.graphics.setColor(0.8, 0.9, 1)
    love.graphics.setFont(self.mediumFont)
    love.graphics.printf("Difficulty & Theme", 0, self.screenHeight / 2 - 60, self.screenWidth, "center")

    self:drawOptionSection("difficulty")
    self:drawOptionSection("theme")
    self:drawOptionSection("navigation")
end

function Menu:drawOptionSection(section)
    for _, button in ipairs(self.optionsButtons) do
        if button.section == section then
            local isSelected = false
            if button.action:sub(1, 11) == "difficulty " then
                isSelected = button.action:sub(12) == self.difficulty
            elseif button.action:sub(1, 6) == "theme " then
                isSelected = button.action:sub(7) == self.theme
            end

            self:drawButton(button, isSelected)
        end
    end
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button, false)
    end
end

function Menu:drawButton(button, isSelected)
    local pulse = (math_sin(self.title.pulse * 3) + 1) * 0.1

    -- Button background
    love.graphics.setColor(0.1, 0.15, 0.25, 0.8)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8)

    -- Button fill with selection highlight
    if isSelected then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", button.x + 2, button.y + 2, button.width - 4, button.height - 4, 6)
    end

    if button.color then
        love.graphics.setColor(button.color[1] + pulse, button.color[2] + pulse, button.color[3] + pulse, 0.9)
    else
        love.graphics.setColor(0.4 + pulse, 0.6 + pulse, 1, 0.9)
    end
    love.graphics.rectangle("fill", button.x + 4, button.y + 4, button.width - 8, button.height - 8, 5)

    -- Button border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8)

    -- Button text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)
    local textWidth = self.mediumFont:getWidth(button.text)
    local textHeight = self.mediumFont:getHeight()
    love.graphics.print(button.text, button.x + (button.width - textWidth) / 2, button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = state == "menu" and self.menuButtons or self.optionsButtons

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end
    return nil
end

function Menu:setDifficulty(difficulty)
    self.difficulty = difficulty
end

function Menu:getDifficulty()
    return self.difficulty
end

function Menu:setTheme(theme)
    self.theme = theme
end

function Menu:getTheme()
    return self.theme
end

return Menu