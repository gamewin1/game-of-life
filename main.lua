-- CONFIG
local cellBorderSize = 1
local cellSize = 8
-- local borderColor =
-- local aliveColor =
-- local deadColor =
-- END CONFIG

function love.load()
    setWindow(80,50)
end
function love.update(dt)

end

function love.draw()

end

---Sets window size based on the grid size
function setWindow(w,h)
    ---get total width or height window should be based on number of cells given
    function getDimensionSize(cellCount)
        local dimensionSize = ((cellCount+1)*cellBorderSize)+(cellCount*cellSize)
        return dimensionSize
    end
    local windowWidth, windowHeight = getDimensionSize(w), getDimensionSize(h)
    love.window.setMode(windowWidth, windowHeight)
end