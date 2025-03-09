local math = math
local beautiful = require("beautiful")
local tonumber = tonumber
local string = string
local ipairs = ipairs
local floor = math.floor
local max = math.max
local mouse = mouse
local mousegrabber = mousegrabber
local screen = screen

local focuswork = { name = "focuswork" }

local function arrange(p)
    local t = p.tag or screen[p.screen].selected_tag
    local wa = p.workarea
    local cls = p.clients

    if #cls == 0 then return end

    -- Get the master width factor (between 0.01 and 0.99)
    local mwfact = t.master_width_factor
    
    -- Single window centered
    if #cls == 1 then
        local c = cls[1]
        local g = {}
        g.width = floor(wa.width * mwfact)
        g.height = wa.height
        g.x = wa.x + floor((wa.width - g.width) / 2)
        g.y = wa.y
        c:geometry(g)
        return
    end

    -- Two windows side by side
    if #cls == 2 then
        local total_width = floor(wa.width * max(mwfact, 0.75))
        local individual_width = floor(total_width / 2)
        local x_offset = floor((wa.width - total_width) / 2)

        for i, c in ipairs(cls) do
            local g = {}
            g.width = individual_width
            g.height = wa.height
            g.x = wa.x + x_offset + (i-1) * individual_width
            g.y = wa.y
            c:geometry(g)
        end
        return
    end

    -- Three or more windows
    if #cls >= 3 then
        -- Main window in center
        local main = cls[1]
        local main_width = floor(wa.width * mwfact)
        local remaining_width = wa.width - main_width
        local side_width = floor(remaining_width / 2)
        
        main:geometry({
            x = wa.x + side_width,
            y = wa.y,
            width = main_width,
            height = wa.height
        })

        -- Handle side windows
        local left_clients = {}
        local right_clients = {}
        
        -- Distribute remaining windows to left and right
        for i = 2, #cls do
            if i == 2 then
                table.insert(left_clients, cls[i])
            elseif i == 3 then
                table.insert(right_clients, cls[i])
            else
                if #left_clients <= #right_clients then
                    table.insert(left_clients, cls[i])
                else
                    table.insert(right_clients, cls[i])
                end
            end
        end

        -- Arrange left side
        local left_width = side_width / #left_clients
        for i, c in ipairs(left_clients) do
            c:geometry({
                x = wa.x + (i-1) * left_width,
                y = wa.y,
                width = left_width,
                height = wa.height
            })
        end

        -- Arrange right side
        local right_width = side_width / #right_clients
        for i, c in ipairs(right_clients) do
            c:geometry({
                x = wa.x + side_width + main_width + (i-1) * right_width,
                y = wa.y,
                width = right_width,
                height = wa.height
            })
        end
    end
end

-- Add mouse resize handler
function focuswork.mouse_resize_handler(c, corner, x, y)
    local wa = c.screen.workarea
    local mwfact = c.screen.selected_tag.master_width_factor
    local g = c:geometry()
    local offset = 0
    local cursor = "cross"

    if g.width + 15 >= wa.width then
        offset = g.width * .5
        cursor = "sb_h_double_arrow"
    elseif g.x + g.width + 15 <= wa.x + wa.width then
        offset = g.width
    end
    
    local corner_coords = { x = wa.x + wa.width * (1 - mwfact) / 2, y = g.y + offset }
    mouse.coords(corner_coords)

    local prev_coords = {}

    mousegrabber.run(function(m)
        if not c.valid then return false end
        for _, v in ipairs(m.buttons) do
            if v then
                prev_coords = { x = m.x, y = m.y }
                local new_mwfact = 1 - (m.x - wa.x) / wa.width * 2
                c.screen.selected_tag.master_width_factor = math.min(math.max(new_mwfact, 0.01), 0.99)
                return true
            end
        end
        return prev_coords.x == m.x and prev_coords.y == m.y
    end, cursor)
end

function focuswork.arrange(p)
    return arrange(p)
end

return focuswork