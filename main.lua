-- John Conway's Game of Life
-- LOVE2D implementation by Jesse Dufrene

-- ##########
-- # CONFIG #
-- ##########

-- Color options. Alpha should be left at 1. {red, green, blue, alpha}
local borderColor = {0.2, 0.2, 0.2, 1}
local aliveColor = {0.8, 0.8, 0.8, 1}
local deadColor = {0, 0, 0, 1}

-- Border size. 0 disables borders
local cellBorderSize = 1

-- Cell size
local cellSize = 10

-- Board size
local cellsWide = 120
local cellsTall = 60

-- Update speed. If 0 or less, update as fast as possible
local generationsPerSecond = 8

-- Whether to use a new seed every time.
local randomSeed = true
-- seed should be a number (can be integer or float). Ignored if randomSeed set to true.
local seedToUse = 0

-- Whether to use the seed to determine a fill percentage.
local seedFill = true
-- fill percentage between 0-100. Ignored if seedFill set to true.
local fillPercentage = 15

-- ####################
-- # ADVANCED OPTIONS #
-- ####################

-- Number of calculations to do per call to love.update(). If less than zero, all calculations will be done immediately.
local calculationsPerUpdate = 0

-- ##############
-- # END CONFIG #
-- ##############

-- get start time in case it's used for the seed later
local startTime = os.time()
-- set seed based on start time if enabled
if randomSeed then
    seedToUse = startTime
end
-- randomly fill if enabled based on start time as seed
if seedFill then
    math.randomseed(seedToUse)
    fillPercentage = math.random()*100
end

local secondsBetweenGenerations = 0
if generationsPerSecond > 0 then
    secondsBetweenGenerations = 1 / generationsPerSecond
end
-- If running ComputerCraft, create the love table so further functions can exist.
if _CC_DEFAULT_SETTINGS then
    love = {}
end

function love.load()
    setWindowSize(cellsWide,cellsTall)
    currentGrid = getNewGrid(cellsWide,cellsTall,fillPercentage,seedToUse)
    secondsSinceLastGeneration = 0
    --[[-- glider
    currentGrid[4][3] = true
    currentGrid[5][4] = true
    currentGrid[5][5] = true
    currentGrid[3][5] = true
    currentGrid[4][5] = true]]--
end

function love.draw()
    drawBorders()
    drawCells(currentGrid)
    --[[
    love.graphics.setColor(0.15,0.15,0.15,.8)
    love.graphics.rectangle("fill",10.5,10.5,150,49)
    love.graphics.setColor(1,1,1,1)
    local winX, winY = love.graphics.getDimensions()
    love.graphics.print("seed: " .. seed,13,13)
    love.graphics.print("fill %: " .. math.floor(fillPercentage + 0.5),13,26)
    --love.graphics.print("os.time() " .. os.time(),13,39)
    ]]--
end

function love.update(dt)
    secondsSinceLastGeneration = secondsSinceLastGeneration + dt
    -- check for an in progress grid and make one if it doesnt exist
    if not gridInProgress then  -- if we don't have an in progress grid, make one
        gridInProgress = getNewGrid(cellsWide, cellsTall, 0)
        cellsNeedingUpdate = {}
        for a = 1, cellsWide do
            for b = 1, cellsTall do
                table.insert(cellsNeedingUpdate,{a,b})
            end
        end
    end
    -- do a few cell calculations
    local updatesThisRound = 0
    if calculationsPerUpdate < 1 then
        updatesThisRound = #cellsNeedingUpdate
    else
        updatesThisRound = math.min(calculationsPerUpdate, #cellsNeedingUpdate)
    end
    for _ = 1, updatesThisRound do
        local cellToCheck = table.remove(cellsNeedingUpdate, #cellsNeedingUpdate)
        local newState = getStateForCell(currentGrid, cellToCheck[1], cellToCheck[2])
        gridInProgress[cellToCheck[1]][cellToCheck[2]] = newState
    end
    -- check if all calculations are done and it's time for the new grid, and shift to new grid if they are
    if secondsSinceLastGeneration >= secondsBetweenGenerations and #cellsNeedingUpdate == 0 then
        secondsSinceLastGeneration = 0
        currentGrid = gridInProgress
        gridInProgress = nil
    end
end

---Returns a new grid table, and randomly fills based on percentage from 0-100. Optionally sets a given seed
function getNewGrid(w, h, percentFilled, seed)
    if seed then math.randomseed(seed) end
    local newGrid = {}
    for i = 1,w do
        local newRow = {}
        for j = 1,h do
            if percentFilled >= math.random(1,100) then
                newRow[j] = true
            else
                newRow[j] = false
            end
        end
        newGrid[i] = newRow
    end
    return newGrid
end

-- ######################################
-- # GAME OF LIFE CALCULATION FUNCTIONS #
-- ######################################
---Given boolean current state and number of neighbors, run against rules and return whether cell should be alive or not
local function calculateGOL(currentState, numberOfNeighbors)
    if currentState then  -- for living cells
        if numberOfNeighbors >= 2 and numberOfNeighbors <= 3 then  -- if there's 2-3 neighbors
            return true  -- cell survives
        else  -- if there's too few or too many neighbors
            return false  -- cell dies from under or overpopulation
        end
    else  -- for dead cells
        if numberOfNeighbors == 3 then  -- if there's 3 neighbors
            return true  -- cell is born
        else  -- if there isn't 3 neighbors
            return false  -- cell remains dead
        end
    end
end
---Get Relative Index by looping back to other side if one end of the table is passed up
local function getRelInd(table,index)
    -- For example, say the 'table' passed has 4 items (expected to be all indexed from 1-4)
    -- Here's what the return would look like with different 'index' values given
    -- Index:  -2 -1  0  1  2  3  4  5  6  7  8  9
    -- Return:  2  3  4  1  2  3  4  1  2  3  4  1
    while index > #table or index < 1 do
        if index > #table then
            index = index-#table
        elseif index < 1 then
            index = index+#table
        end
    end
    return index
end
---Get count of all surrounding live cells around a certain cell
local function getNeighborCount(grid, x, y)
    local relativesToCheck = { {-1,-1}, {-1,0}, {-1,1}, {0,-1}, {0,1}, {1,-1}, {1,0}, {1,1} }
    local neighborCount = 0
    for _, b in pairs(relativesToCheck) do
        if grid[getRelInd(grid,x+b[1])][getRelInd(grid[x],y+b[2])] then
            neighborCount = neighborCount + 1
        end
    end
    return neighborCount
end
---Do update for a certain cell
function getStateForCell(oldGrid, x, y)
    local neighbors = getNeighborCount(oldGrid,x,y)
    -- get current state of cell
    local alive
    if oldGrid[x][y] then
        alive = true
    else
        alive = false
    end
    local newState = calculateGOL(alive,neighbors)
    return newState
end

-- ##################
-- # LOVE FUNCTIONS #
-- ##################
---Sets window size based on the grid size
function setWindowSize(w, h)
    ---get total width or height window should be based on number of cells given
    function getDimensionSize(cellCount)
        local dimensionSize = ((cellCount+1)*cellBorderSize)+(cellCount*cellSize)
        return dimensionSize
    end
    local windowWidth, windowHeight = getDimensionSize(w), getDimensionSize(h)
    love.window.setMode(windowWidth, windowHeight, {
        resizable = true,
    })
end
---Passed a grid, render the cells in it
function drawCells(grid)
    for a, b in pairs(grid) do
        local x = (cellBorderSize*a)+(cellSize*(a-1))
        for c, d in pairs(b) do
            local y = (cellBorderSize*c)+(cellSize*(c-1))
            if d then
                love.graphics.setColor(aliveColor)
            else
                love.graphics.setColor(deadColor)
            end
            love.graphics.rectangle("fill",x,y,cellSize,cellSize)
        end
    end
end
---Draws borders
function drawBorders()
    if cellBorderSize == 0 then return end
    -- center of top left pixel is 0.5, 0.5
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(cellBorderSize)
    local centerOfLine = cellBorderSize*0.5
    local endLineWidth = ((cellBorderSize+cellSize)*cellsWide)+centerOfLine
    local endLineHeight = ((cellBorderSize+cellSize)*cellsTall)+centerOfLine
    ---Given a cell count along a dimension, get each border coordinate
    function getCoordinatesToDraw(cellCount)
        local coordinates = {}
        for i=0,cellCount do
            local coordinate = ((cellBorderSize+cellSize)*i)+centerOfLine
            coordinates[i+1] = coordinate
        end
        return coordinates
    end
    local xCoords = getCoordinatesToDraw(cellsWide)
    local yCoords = getCoordinatesToDraw(cellsTall)
    for _,v in pairs(xCoords) do
        love.graphics.line(v, 0.5, v, endLineHeight +0.5)
    end
    for _,v in pairs(yCoords) do
        love.graphics.line(0.5, v, endLineWidth +0.5, v)
    end
end

-- ###########################
-- # COMPUTERCRAFT FUNCTIONS #
-- ###########################

function ccLoad()
    math.randomseed(os.epoch())
    currentGrid = getNewGrid(cellsWide,cellsTall,10)
    secondsSinceLastGeneration = 0
end

---Passed a grid, render the cells in it
function ccDraw(grid)
    for x, b in pairs(grid) do
        for y, d in pairs(b) do
            term.setCursorPos(x,y)
            if d then
                term.write(string.char(127))
            else
                term.write(" ")
            end
        end
    end
end

---This is main loop if run in computercraft
function computercraft()
    local dt = os.clock() - timeOfLastUpdate
    timeOfLastUpdate = timeOfLastUpdate + dt
    love.update(dt)
    ccDraw(currentGrid)
end

-- run the computercraft version if we find this
if _CC_DEFAULT_SETTINGS then
    blankLine = ""
    cellsWide, cellsTall = term.getSize()
    for i = 1,cellsWide do
        blankLine = blankLine .. " "
    end
    term.setPaletteColor(colors.black,deadColor[1],deadColor[2],deadColor[3])
    term.setPaletteColor(colors.white,aliveColor[1],aliveColor[2],aliveColor[3])
    ccLoad()
    timeOfLastUpdate = os.clock()
    while true do
        computercraft()
        -- yields
        os.queueEvent("fakeEvent");
        os.pullEvent("fakeEvent");
    end
end