-- CONFIG
local cellBorderSize = 2
local cellSize = 30
-- {red, green, blue, alpha}
local borderColor = {0.2, 0.2, 0.2, 1}
local aliveColor = {0.8, 0.8, 0.8, 1}
local deadColor = {0, 0, 0, 1}
local cellsWide = 40
local cellsTall = 25
-- END CONFIG

function love.load()
    math.randomseed(os.time())
    setWindowSize(cellsWide,cellsTall)
    myGrid = getNewGrid(cellsWide,cellsTall,15)
end
function love.update(dt)

end

function love.draw()
    drawBorders()
    drawCells(myGrid)
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

---Given boolean current state and number of neighbors,
---run against conway's game of life rules and returns if cell is alive or not
function getNewState(currentState, numberOfNeighbors)
    if currentState then  -- for living cells
        if numberOfNeighbors == 2 or numberOfNeighbors == 3 then  -- if there's 2-3 neighbors
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
function getRelInd(table,index)
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
function getNeighbors(grid, x, y)
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
function getStateForCell(oldgrid, newgrid, x, y)

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