--[[
    Stars Chat
    PNG2Parts
    by underscorereal
]]

-- === CONFIG ===
local cfg =  _G.DHStarsPNG2Parts or {
    MAX_PARTS = 5000, -- safety cap on predicted parts (conservative)
    PIXELS_WAIT = 50, -- yield frequency
    MAX_ATTEMPTS = 20, -- fail-safe: don't loop forever
    MIN_SHRINK_FACTOR = 0.95, -- shirnk percentage
    WAIT_BEFORE_NEXT_ATTEMPT = 0.1, -- seconds to wait before next downscale attempt
    RAW_IMAGE_DATA = game:HttpGet("http://placehold.co/1000x1000.png") -- or readfile("img.png")
}
-- ==============
local MAX_PARTS = cfg.MAX_PARTS
local PIXELS_WAIT = cfg.PIXELS_WAIT
local MAX_ATTEMPTS = cfg.MAX_ATTEMPTS 
local MIN_SHRINK_FACTOR = cfg.MIN_SHRINK_FACTOR 
local WAIT_BEFORE_NEXT_ATTEMPT = cfg.WAIT_BEFORE_NEXT_ATTEMPT
local pixelSize = 1 -- thickness in Y (and Z) of parts
local spacing = 1 -- width of 1 pixel in X

local PNG = loadstring(
    game:HttpGet('https://rawscripts.net/raw/Universal-Script-PNGLib-21830')
)()
local image = PNG.new(cfg.RAW_IMAGE_DATA)

printconsole('OK loaded image with dimensions: ' .. image.Width .. 'x' .. image.Height)
printconsole('Starting to draw...')

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')

local appFramework = PlayerGui.MainScreenGui.PhoneFrame.CenterFrame.AppFramework
local appFrame = PlayerGui.MainScreenGui.PhoneFrame.CenterFrame.AppFrame

if not appFramework:FindFirstChild('Frame') then
    local phone = LocalPlayer.Backpack:FindFirstChild('[Phone]')
    if phone then
        phone.Parent = LocalPlayer.Character
    else
        if LocalPlayer.Character:FindFirstChild('[Phone]') then
           local phoneTool = LocalPlayer.Character:FindFirstChild('[Phone]')
           phoneTool.Parent = LocalPlayer.Backpack
           task.wait(0.3)
        phoneTool.Parent = LocalPlayer.Character
        end
    end
    task.wait(0.3)
    firesignal(appFrame['Stars Chat'].ImageButton.Activated)
    task.wait(0.3)
end

local dahoodViewport = appFramework.Frame.ImageLabel.ViewportFrame
dahoodViewport:ClearAllChildren()

-- -------- helpers --------
local function colorKey(col)
    if col == nil then
        return 'nil'
    end
    local t = typeof(col)
    if t == 'Color3' then
        return ('C3:%.4f,%.4f,%.4f'):format(col.R, col.G, col.B)
    end
    if t == 'table' then
        local r = col.R or col.r or col[1]
        local g = col.G or col.g or col[2]
        local b = col.B or col.b or col[3]
        local a = col.A or col.a or col[4] or 1
        if r and g and b then
            return ('T:%.4f,%.4f,%.4f,%.4f'):format(
                tonumber(r) or 0,
                tonumber(g) or 0,
                tonumber(b) or 0,
                tonumber(a) or 1
            )
        end
        return tostring(col)
    end
    return tostring(col)
end

local function Downscale(imageSrc, newW, newH)
    assert(type(newW) == "number" and type(newH) == "number", "newW/newH must be numbers")

    local srcW, srcH = imageSrc.Width, imageSrc.Height
    local scaleX = srcW / newW
    local scaleY = srcH / newH

    local acc = {}
    for i = 1, newW * newH do
        acc[i] = { r = 0, g = 0, b = 0, a = 0, w = 0 }
    end

    for sy = 1, srcH do
        for sx = 1, srcW do
            local tx = math.floor((sx - 1) / scaleX) + 1
            local ty = math.floor((sy - 1) / scaleY) + 1
            if tx < 1 then tx = 1 end
            if tx > newW then tx = newW end
            if ty < 1 then ty = 1 end
            if ty > newH then ty = newH end

            local c, a = imageSrc:GetPixel(sx, sy)
            local idx = (ty - 1) * newW + tx

            if c == nil or (a ~= nil and a == 0) then
            else
                local alpha = (a or 255) / 255
                local r, g, b
                if typeof(c) == "Color3" then
                    r, g, b = c.R, c.G, c.B
                elseif type(c) == "table" then
                    r = tonumber(c.R or c.r or c[1]) or 0
                    g = tonumber(c.G or c.g or c[2]) or 0
                    b = tonumber(c.B or c.b or c[3]) or 0
                else
                    r, g, b = 0, 0, 0
                end

                local aWeighted = alpha
                local e = acc[idx]
                e.r = e.r + r * aWeighted
                e.g = e.g + g * aWeighted
                e.b = e.b + b * aWeighted
                e.a = e.a + alpha
                e.w = e.w + 1
            end
        end
    end

    local pixels = {}
    local nonNil = 0
    for ty = 1, newH do
        for tx = 1, newW do
            local idx = (ty - 1) * newW + tx
            local e = acc[idx]
            if e.a > 0 then
                local alpha = e.a / math.max(e.w, 1) 
                local r, g, b
                if e.a > 0 then
                    r = e.r / e.a
                    g = e.g / e.a
                    b = e.b / e.a
                else
                    r, g, b = 0, 0, 0
                end
                r = math.clamp(r, 0, 1)
                g = math.clamp(g, 0, 1)
                b = math.clamp(b, 0, 1)
                local color = Color3.new(r, g, b)
                local alphaByte = math.clamp(math.floor((e.a / math.max(e.w,1)) * 255 + 0.5), 0, 255)

                pixels[idx] = { color = color, alpha = alphaByte, key = colorKey(color) }
                nonNil = nonNil + 1
            else
                pixels[idx] = { color = nil, alpha = 0, key = "nil" }
            end
        end
    end

    local newImage = {}
    function newImage:GetPixel(x, y)
        if type(x) ~= "number" then x = tonumber(x) end
        if type(y) ~= "number" then y = tonumber(y) end
        if not x or not y then return nil end
        if x < 1 or x > newW or y < 1 or y > newH then return nil end
        local p = pixels[(y - 1) * newW + x]
        if not p then return nil end
        return p.color, p.alpha
    end
    function newImage:GetKey(x, y)
        if type(x) ~= "number" then x = tonumber(x) end
        if type(y) ~= "number" then y = tonumber(y) end
        if not x or not y then return "nil" end
        if x < 1 or x > newW or y < 1 or y > newH then return "nil" end
        local p = pixels[(y - 1) * newW + x]
        if not p then return "nil" end
        return p.key
    end

    newImage.Width = newW
    newImage.Height = newH
    newImage._debug_nonNil = nonNil
    newImage._pixels = pixels
    return newImage
end

local function simulate_full_build(imageToSim, cap)
    local width, height = imageToSim.Width, imageToSim.Height
    local prevRowRuns = {}
    local totalParts = 0

    for y = 1, height do
        local x = 1
        local currentRowRuns = {}
        local newParts = {}

        while x <= width do
            local startColor, startAlpha = imageToSim:GetPixel(x, y)
            if startColor == nil or (startAlpha ~= nil and startAlpha == 0) then
                x = x + 1
            else
                local runLen = 1
                while x + runLen <= width do
                    local nc, na = imageToSim:GetPixel(x + runLen, y)
                    if nc == nil or (na ~= nil and na == 0) then
                        break
                    end
                    if colorKey(nc) ~= colorKey(startColor) then
                        break
                    end
                    runLen = runLen + 1
                end

                local runStart = x
                local runEnd = x + runLen - 1
                local colKey = colorKey(startColor)
                local runKey = runStart .. '-' .. runEnd .. '-' .. colKey

                if prevRowRuns[runKey] then
                    local prev = prevRowRuns[runKey]
                    prev.height = (prev.height or 1) + 1
                    currentRowRuns[runKey] = prev
                else
                    local matchedOverlap = false
                    for oldKey, oldEntry in pairs(prevRowRuns) do
                        local s, e, c =
                            string.match(oldKey, '(%d+)%-(%d+)%-(.+)')
                        if s and e and c and c == colKey then
                            local oldStart = tonumber(s)
                            local oldEnd = tonumber(e)
                            if not (runStart > oldEnd or runEnd < oldStart) then
                                table.insert(newParts, {
                                    start = runStart,
                                    ['end'] = runEnd,
                                    color = colKey,
                                })
                                matchedOverlap = true
                                break
                            end
                        end
                    end

                    if not matchedOverlap then
                        table.insert(newParts, {
                            start = runStart,
                            ['end'] = runEnd,
                            color = colKey,
                        })
                    end
                end

                x = x + runLen
            end
        end

        table.sort(newParts, function(a, b)
            return a.start < b.start
        end)
        local merged = {}
        local last = nil
        for _, p in ipairs(newParts) do
            if
                last
                and p.color == last.color
                and (last['end'] + 1) == p.start
            then
                last['end'] = p['end']
            else
                last = {
                    start = p.start,
                    ['end'] = p['end'],
                    color = p.color,
                    height = 1,
                }
                table.insert(merged, last)
            end
        end

        for _, m in ipairs(merged) do
            local key = m.start .. '-' .. m['end'] .. '-' .. m.color
            currentRowRuns[key] = {
                start = m.start,
                ['end'] = m['end'],
                color = m.color,
                height = 1,
            }
            totalParts = totalParts + 1
            if cap and totalParts > cap then
                return totalParts
            end
        end

        prevRowRuns = currentRowRuns
    end

    return totalParts
end

local function ensure_under_limit(img)
    local working = img
    local attempt = 0

    while true do
        attempt = attempt + 1
        local predicted = simulate_full_build(working, MAX_PARTS + 0)
        printconsole(
            ('[Attempt %d] simulate_full_build predicted = %d (image %dx%d)'):format(
                attempt,
                predicted,
                working.Width,
                working.Height
            )
        )

        if predicted <= MAX_PARTS then
            return working, predicted
        end

        if attempt >= MAX_ATTEMPTS then
            warn(
                ('ensure_under_limit: reached max attempts (%d). Predicted parts = %d; returning best-effort size %dx%d'):format(
                    MAX_ATTEMPTS,
                    predicted,
                    working.Width,
                    working.Height
                )
            )
            return working, predicted
        end

        local factor = math.sqrt(MAX_PARTS / predicted)

        if factor > 0 and factor > MIN_SHRINK_FACTOR then
            factor = math.min(factor, MIN_SHRINK_FACTOR)
        end

        local newW = math.max(1, math.floor(working.Width * factor))
        local newH = math.max(1, math.floor(working.Height * factor))

        if newW == working.Width and newH == working.Height then
            local shrinkPct = 0.05
            local shrinkW =
                math.max(1, math.floor(working.Width * (1 - shrinkPct)))
            local shrinkH =
                math.max(1, math.floor(working.Height * (1 - shrinkPct)))

            if shrinkW == working.Width then
                shrinkW = math.max(1, working.Width - 1)
            end
            if shrinkH == working.Height then
                shrinkH = math.max(1, working.Height - 1)
            end

            printconsole(
                ('Downscaling (forced percent): %dx%d -> %dx%d'):format(
                    working.Width,
                    working.Height,
                    shrinkW,
                    shrinkH
                )
            )
            working = Downscale(working, shrinkW, shrinkH)
        else
            printconsole(
                ('Downscaling: %dx%d -> %dx%d (factor %.4f)'):format(
                    working.Width,
                    working.Height,
                    newW,
                    newH,
                    factor
                )
            )
            working = Downscale(working, newW, newH)
        end
        task.wait(WAIT_BEFORE_NEXT_ATTEMPT)
    end
end

-- -------- ensure image is under limit --------
local finalImage, predictedParts = ensure_under_limit(image)
if predictedParts > MAX_PARTS then
    warn(
        ('Unable to reduce predicted parts below %d (predicted %d). Aborting.'):format(
            MAX_PARTS,
            predictedParts
        )
    )
    return
end

printconsole(
    ('Final image for rendering: %dx%d, predicted parts: %d'):format(
        finalImage.Width,
        finalImage.Height,
        predictedParts
    )
)
printconsole('Downscaled nonNil:', finalImage and finalImage._debug_nonNil)
printconsole(
    'Sample pixel (1,1):',
    tostring((function()
        local c, a = finalImage:GetPixel(1, 1)
        return c and tostring(c) or 'nil', a
    end)())
)
printconsole(
    'Sample key (1,1):',
    finalImage
        and (finalImage.GetKey and finalImage:GetKey(1, 1) or 'no-getkey')
)

-- -------- BUILD PASS (creates Parts in viewport) --------
local prevRowRuns = {}
local totalCreated = 0
local pixelsdrawn = 0

for y = 1, finalImage.Height do
    local x = 1
    local currentRowRuns = {}
    local newParts = {}
    pixelsdrawn = pixelsdrawn + 1

    while x <= finalImage.Width do
        local startColor, startAlpha = finalImage:GetPixel(x, y)
        if startColor == nil or (startAlpha ~= nil and startAlpha == 0) then
            x = x + 1
        else
            local runLength = 1
            while x + runLength <= finalImage.Width do
                local nextColor, nextAlpha =
                    finalImage:GetPixel(x + runLength, y)
                if
                    nextColor == nil or (nextAlpha ~= nil and nextAlpha == 0)
                then
                    break
                end
                if colorKey(nextColor) ~= colorKey(startColor) then
                    break
                end
                runLength = runLength + 1
            end

            local runStart = x
            local runEnd = x + runLength - 1
            local colorstr = colorKey(startColor)
            local runKey = runStart .. '-' .. runEnd .. '-' .. colorstr

            local prev = prevRowRuns[runKey]
            if prev then
                prev.part.Size = prev.part.Size + Vector3.new(0, pixelSize, 0)
                prev.part.Position = prev.part.Position
                    + Vector3.new(0, -pixelSize / 2, 0)
                prev.height = (prev.height or 1) + 1
                currentRowRuns[runKey] = prev
            else
                local matched = false
                for oldKey, oldEntry in pairs(prevRowRuns) do
                    local s, e, c = string.match(oldKey, '(%d+)%-(%d+)%-(.+)')
                    if s and e and c and c == colorstr then
                        local oldStart = tonumber(s)
                        local oldEnd = tonumber(e)
                        if not (runStart > oldEnd or runEnd < oldStart) then
                            local part = Instance.new('Part')
                            part.Anchored = true
                            part.Material = Enum.Material.SmoothPlastic
                            part.Size = Vector3.new(
                                (runEnd - runStart + 1) * spacing,
                                pixelSize,
                                pixelSize
                            )
                            part.Position = Vector3.new(
                                (runStart + (runEnd - runStart + 1) / 2 - 0.5)
                                    * spacing,
                                -y * spacing,
                                0
                            )
                            part.Color = startColor
                            part.Parent = dahoodViewport

                            local entry = { part = part, height = 1 }
                            currentRowRuns[runKey] = entry
                            table.insert(newParts, {
                                start = runStart,
                                ['end'] = runEnd,
                                color = colorstr,
                                entry = entry,
                            })
                            matched = true
                            totalCreated = totalCreated + 1
                            break
                        end
                    end
                end

                if not matched then
                    local part = Instance.new('Part')
                    part.Anchored = true
                    part.Material = Enum.Material.SmoothPlastic
                    part.Size = Vector3.new(
                        (runEnd - runStart + 1) * spacing,
                        pixelSize,
                        pixelSize
                    )
                    part.Position = Vector3.new(
                        (runStart + (runEnd - runStart + 1) / 2 - 0.5) * spacing,
                        -y * spacing,
                        0
                    )
                    part.Color = startColor
                    part.Parent = dahoodViewport

                    local entry = { part = part, height = 1 }
                    currentRowRuns[runKey] = entry
                    table.insert(newParts, {
                        start = runStart,
                        ['end'] = runEnd,
                        color = colorstr,
                        entry = entry,
                    })
                    totalCreated = totalCreated + 1
                end
            end

            x = x + runLength
        end
    end

    table.sort(newParts, function(a, b)
        return a.start < b.start
    end)
    local lastItem = nil
    for _, np in ipairs(newParts) do
        if
            lastItem
            and np.color == lastItem.color
            and (lastItem['end'] + 1) == np.start
        then
            local lastPart = lastItem.entry.part
            local npPart = np.entry.part
            local combinedPixels = (lastItem['end'] - lastItem.start + 1)
                + (np['end'] - np.start + 1)
            local newWidth = combinedPixels * spacing
            local newCenterX = (
                (lastPart.Position.X * lastPart.Size.X)
                + (npPart.Position.X * npPart.Size.X)
            ) / (lastPart.Size.X + npPart.Size.X)
            lastPart.Size =
                Vector3.new(newWidth, lastPart.Size.Y, lastPart.Size.Z)
            lastPart.Position = Vector3.new(
                newCenterX,
                lastPart.Position.Y,
                lastPart.Position.Z
            )
            npPart:Destroy()
            lastItem['end'] = np['end']
        else
            lastItem = np
        end
    end

    prevRowRuns = currentRowRuns

    if (pixelsdrawn % PIXELS_WAIT) == 0 then
        task.wait()
    end
end

printconsole(
    ('Done. Parts created: %d (predicted upper bound: %d)'):format(
        totalCreated,
        predictedParts or 0
    )
)

local cam = dahoodViewport.Parent:FindFirstChild('Camera')
if not cam then
    cam = Instance.new('Camera')
    cam.Parent = dahoodViewport.Parent
end

local imageWidth = finalImage.Width * spacing
local imageHeight = finalImage.Height * spacing
local centerPos = Vector3.new(imageWidth / 2, -imageHeight / 2, 0)
local camOffset = Vector3.new(0, 0, math.max(imageWidth, imageHeight) * 0.7)
local desiredCFrame = CFrame.new(centerPos + camOffset, centerPos)

do
    local ok, mt = pcall(getrawmetatable, cam)
    if ok and mt then
        setreadonly(mt, false)
        local oldNewIndex
        oldNewIndex = hookmetamethod(
            cam,
            '__newindex',
            function(self, key, value)
                if self == cam and key == 'CFrame' then
                    return oldNewIndex(self, key, desiredCFrame)
                end
                return oldNewIndex(self, key, value)
            end
        )
        setreadonly(mt, true)
    end
end

printconsole('Camera fitted and locked.')

--[[
                             ░██                                                                                                         ░██                                      
                             ░██                                                                                                         ░██                                      
░██    ░██ ░████████   ░████████  ░███████  ░██░████  ░███████   ░███████   ░███████  ░██░████  ░███████  ░██░████  ░███████   ░██████   ░██      ░████████  ░██████   ░██    ░██ 
░██    ░██ ░██    ░██ ░██    ░██ ░██    ░██ ░███     ░██        ░██    ░██ ░██    ░██ ░███     ░██    ░██ ░███     ░██    ░██       ░██  ░██     ░██    ░██       ░██  ░██    ░██ 
░██    ░██ ░██    ░██ ░██    ░██ ░█████████ ░██       ░███████  ░██        ░██    ░██ ░██      ░█████████ ░██      ░█████████  ░███████  ░██     ░██    ░██  ░███████  ░██    ░██ 
░██   ░███ ░██    ░██ ░██   ░███ ░██        ░██             ░██ ░██    ░██ ░██    ░██ ░██      ░██        ░██      ░██        ░██   ░██  ░██     ░██   ░███ ░██   ░██  ░██   ░███ 
 ░█████░██ ░██    ░██  ░█████░██  ░███████  ░██       ░███████   ░███████   ░███████  ░██       ░███████  ░██       ░███████   ░█████░██ ░██ ░██  ░█████░██  ░█████░██  ░█████░██ 
                                                                                                                                                        ░██                   ░██ 
                                                                                                                                                  ░███████              ░███████  
                                                                                                                                                                                  
                                                                                underscoreReal.gay
]]
