-- John Conway's Game of Life
-- LOVE2D implementation by Jesse Dufrene

-- ##########
-- # CONFIG #
-- ##########
-- {red, green, blue, alpha}
local borderColor = {0.2, 0.2, 0.2, 1}
local aliveColor = {0.8, 0.8, 0.8, 1}
local deadColor = {0, 0, 0, 1}
local cellBorderSize = 2
local cellSize = 30
local cellsWide = 40
local cellsTall = 25
local secondsBetweenGenerations = 0.25
-- ####################
-- # ADVANCED OPTIONS #
-- ####################
local calculationsPerUpdate = -1  -- if less than 1, update whole board.
-- ##############
-- # END CONFIG #
-- ##############

function love.load()
    math.randomseed(os.time())
    setWindowSize(cellsWide,cellsTall)
    currentGrid = getNewGrid(cellsWide,cellsTall,10)
    secondsSinceLastGeneration = 0
    --[[-- glider
    currentGrid[4][3] = true
    currentGrid[5][4] = true
    currentGrid[5][5] = true
    currentGrid[3][5] = true
    currentGrid[4][5] = true
    -- block
    currentGrid[10][2] = true
    currentGrid[11][2] = true
    currentGrid[10][3] = true
    currentGrid[11][3] = true
    -- blinker
    currentGrid[2][10] = true
    currentGrid[3][10] = true
    currentGrid[4][10] = true]]--
end

function love.draw()
    drawBorders()
    drawCells(currentGrid)
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
    for a = 1, updatesThisRound do
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


---Sets window size based on the grid size
function setWindowSize(w, h)
    ---get total width or height window should be based on number of cells given
    function getDimensionSize(cellCount)
        local dimensionSize = ((cellCount+1)*cellBorderSize)+(cellCount*cellSize)
        return dimensionSize
    end
    local windowWidth, windowHeight = getDimensionSize(w), getDimensionSize(h)
    love.window.setMode(windowWidth, windowHeight)
end
---Returns a new grid table, and randomly fills based on percentage from 0-100
function getNewGrid(w, h, percentFilled)
    local newGrid = {}
    for i = 1,w do
        newRow = {}
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
    for a, b in pairs(relativesToCheck) do
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
    local alive = nil
    if oldGrid[x][y] then
        alive = true
    else
        alive = false
    end
    local newState = calculateGOL(alive,neighbors)
    return newState
end

-- ##################
-- # DRAW FUNCTIONS #
-- ##################
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

function drawBorders()
    if cellBorderSize == 0 then return end
    -- center of top left pixel is 0.5, 0.5
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(cellBorderSize)
    local centerOfLine = cellBorderSize*0.5
    local windowWidth, windowHeight = love.graphics.getDimensions()
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
    for k,v in pairs(xCoords) do
        love.graphics.line(v, 0.5, v, windowHeight+0.5)
    end
    for k,v in pairs(yCoords) do
        love.graphics.line(0.5, v, windowWidth+0.5, v)
    end
end
