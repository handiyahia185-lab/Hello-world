-- KZM v3.1 — Full UI + TBO TP system (no emojis, no Side Dash Assist, Respawn in Combat, 1HP button)
-- UI overhaul: animated intro, gradient borders, search, toasts, sliding tabs, mobile scaling
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RS                = game:GetService("ReplicatedStorage")
local ReplicatedStorage = RS
local LocalPlayer       = Players.LocalPlayer

for _, g in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
    if g.Name == "KZM" or g.Name == "KZMIntro" then g:Destroy() end
end
if shared.KZMUI and shared.KZMUI.conn then
    pcall(function() shared.KZMUI.conn:Disconnect() end)
end

-- ── COLOURS ──────────────────────────────────────────────────
local C = {
    bg        = Color3.fromRGB(8,   5,  18),
    panel     = Color3.fromRGB(13,  9,  26),
    row       = Color3.fromRGB(22,  16, 40),
    rowHover  = Color3.fromRGB(32,  24, 56),
    accent    = Color3.fromRGB(100, 55, 240),
    accent2   = Color3.fromRGB(65,  35, 180),
    accentHi  = Color3.fromRGB(150, 100,255),
    stroke    = Color3.fromRGB(70,  45, 150),
    tabActive = Color3.fromRGB(100, 55, 240),
    tabIdle   = Color3.fromRGB(18,  13, 35),
    text      = Color3.fromRGB(220, 215,245),
    textDim   = Color3.fromRGB(120, 105,160),
    section   = Color3.fromRGB(30,  20, 55),
    toggleOn  = Color3.fromRGB(100, 55, 240),
    toggleOff = Color3.fromRGB(25,  18, 50),
    white     = Color3.fromRGB(255, 255,255),
    red       = Color3.fromRGB(220, 50,  80),
    redLo     = Color3.fromRGB(140, 20,  45),
    darkPurple = Color3.fromRGB(80, 20, 80),
    cyan      = Color3.fromRGB(70, 200, 255),
    pink      = Color3.fromRGB(235, 80, 200),
    green     = Color3.fromRGB(80, 255, 130),
}

-- ── UI CORE (single render loop drives every ambient animation) ──
local UI = { t = 0, tasks = {} }
shared.KZMUI = UI
UI.conn = RunService.RenderStepped:Connect(function(dt)
    UI.t = UI.t + dt
    for _, fn in pairs(UI.tasks) do pcall(fn, dt, UI.t) end
end)

local function tween(obj, time, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end
UI.tween = tween
UI.locks = { lockOn = false, fly = false, toggle = false, orbit = false }  -- "freeze position" flags (set from Configs tab)

-- ── SCREEN GUI ───────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "KZM"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder    = 200
screenGui.Parent          = LocalPlayer.PlayerGui

-- ── HELPERS ──────────────────────────────────────────────────
local function makeCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function makeStroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or C.stroke
    s.Thickness = th or 1.5
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function makeGradStroke(p, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = C.white
    s.Thickness = th or 2
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    C.accent),
        ColorSequenceKeypoint.new(0.33, C.cyan),
        ColorSequenceKeypoint.new(0.66, C.pink),
        ColorSequenceKeypoint.new(1,    C.accent),
    })
    g.Parent = s
    return s, g
end

-- ── TOAST NOTIFICATIONS ──────────────────────────────────────
do
    local holder = Instance.new("Frame")
    holder.Name = "Toasts"
    holder.AnchorPoint = Vector2.new(1, 1)
    holder.Position = UDim2.new(1, -14, 1, -14)
    holder.Size = UDim2.new(0, 260, 0, 320)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 300
    holder.Parent = screenGui

    local lay = Instance.new("UIListLayout")
    lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 6)
    lay.Parent = holder

    local order = 0
    function UI.notify(title, text, color, dur)
        dur = dur or 3.5
        color = color or C.accent
        order = order + 1

        local slot = Instance.new("Frame")
        slot.Size = UDim2.new(1, 0, 0, 56)
        slot.BackgroundTransparency = 1
        slot.LayoutOrder = order
        slot.ZIndex = 300
        slot.Parent = holder

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 1, 0)
        card.Position = UDim2.new(1.3, 0, 0, 0)
        card.BackgroundColor3 = C.panel
        card.BorderSizePixel = 0
        card.ZIndex = 301
        card.Parent = slot
        makeCorner(card, 9)
        makeStroke(card, color, 1.2, 0.35)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 0.64, 0)
        bar.Position = UDim2.new(0, 0, 0.18, 0)
        bar.BackgroundColor3 = color
        bar.BorderSizePixel = 0
        bar.ZIndex = 302
        bar.Parent = card
        makeCorner(bar, 2)

        local t1 = Instance.new("TextLabel")
        t1.Size = UDim2.new(1, -22, 0, 16)
        t1.Position = UDim2.new(0, 14, 0, 7)
        t1.BackgroundTransparency = 1
        t1.Text = title
        t1.TextColor3 = C.white
        t1.Font = Enum.Font.GothamBold
        t1.TextSize = 12
        t1.TextXAlignment = Enum.TextXAlignment.Left
        t1.ZIndex = 302
        t1.Parent = card

        local t2 = Instance.new("TextLabel")
        t2.Size = UDim2.new(1, -22, 0, 22)
        t2.Position = UDim2.new(0, 14, 0, 24)
        t2.BackgroundTransparency = 1
        t2.Text = text or ""
        t2.TextColor3 = C.textDim
        t2.Font = Enum.Font.Gotham
        t2.TextSize = 11
        t2.TextWrapped = true
        t2.TextXAlignment = Enum.TextXAlignment.Left
        t2.TextYAlignment = Enum.TextYAlignment.Top
        t2.ZIndex = 302
        t2.Parent = card

        local timer = Instance.new("Frame")
        timer.Size = UDim2.new(1, -16, 0, 2)
        timer.Position = UDim2.new(0, 8, 1, -5)
        timer.BackgroundColor3 = color
        timer.BackgroundTransparency = 0.3
        timer.BorderSizePixel = 0
        timer.ZIndex = 302
        timer.Parent = card
        makeCorner(timer, 1)

        tween(card, 0.45, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
        tween(timer, dur, {Size = UDim2.new(0, 0, 0, 2)}, Enum.EasingStyle.Linear)
        task.delay(dur, function()
            tween(card, 0.3, {Position = UDim2.new(1.3, 0, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.wait(0.32)
            slot:Destroy()
        end)
    end
end

-- ── EXECUTE INTRO ANIMATION ──────────────────────────────────
do
    local Lighting = game:GetService("Lighting")
    local waiters, done = {}, false

    local function release()
        if done then return end
        done = true
        for _, fn in ipairs(waiters) do task.spawn(fn) end
        waiters = {}
    end
    function UI.afterIntro(fn)
        if done then task.spawn(fn) else table.insert(waiters, fn) end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "KZMIntro"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer.PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(5, 3, 12)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = gui

    -- floating particles
    local particles, palette = {}, {C.accentHi, C.cyan, C.pink, C.white}
    for i = 1, 36 do
        local f = Instance.new("Frame")
        local s = math.random(2, 4)
        f.Size = UDim2.fromOffset(s, s)
        f.BackgroundColor3 = palette[math.random(#palette)]
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.ZIndex = 2
        f.Parent = bg
        makeCorner(f, 2)
        particles[i] = {f = f, x = math.random(), y = math.random(), v = 0.03 + math.random() * 0.09, ph = math.random() * 6.28}
    end
    local pAlpha, fading = 0, false
    UI.tasks.introParticles = function(dt, t)
        pAlpha = fading and math.max(0, pAlpha - dt * 2) or math.min(1, pAlpha + dt * 1.2)
        for _, p in ipairs(particles) do
            p.y = p.y - p.v * dt
            if p.y < -0.02 then p.y = 1.02; p.x = math.random() end
            p.f.Position = UDim2.fromScale(p.x + math.sin(t * 0.8 + p.ph) * 0.01, p.y)
            p.f.BackgroundTransparency = 1 - pAlpha * (0.4 + 0.3 * math.sin(t * 2 + p.ph))
        end
    end

    -- scan line
    local scan = Instance.new("Frame")
    scan.Size = UDim2.new(1, 0, 0, 2)
    scan.Position = UDim2.new(0, 0, -0.02, 0)
    scan.BackgroundColor3 = C.white
    scan.BorderSizePixel = 0
    scan.ZIndex = 2
    scan.Parent = bg
    local scanGrad = Instance.new("UIGradient")
    scanGrad.Color = ColorSequence.new(C.accentHi, C.cyan)
    scanGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1),
    })
    scanGrad.Parent = scan

    -- core group
    local core = Instance.new("Frame")
    core.AnchorPoint = Vector2.new(0.5, 0.5)
    core.Position = UDim2.fromScale(0.5, 0.5)
    core.Size = UDim2.fromOffset(300, 300)
    core.BackgroundTransparency = 1
    core.ZIndex = 3
    core.Parent = bg

    local glowC = Instance.new("Frame")
    glowC.AnchorPoint = Vector2.new(0.5, 0.5)
    glowC.Position = UDim2.fromScale(0.5, 0.5)
    glowC.Size = UDim2.fromOffset(0, 0)
    glowC.BackgroundColor3 = C.accent
    glowC.BackgroundTransparency = 1
    glowC.BorderSizePixel = 0
    glowC.ZIndex = 3
    glowC.Parent = core
    makeCorner(glowC, 1000)

    local rings, ringGrads = {}, {}
    local ringSizes, ringSpeed = {250, 200, 150}, {70, -115, 170}
    for i, sz in ipairs(ringSizes) do
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.Position = UDim2.fromScale(0.5, 0.5)
        r.Size = UDim2.fromOffset(0, 0)
        r.BackgroundTransparency = 1
        r.ZIndex = 4
        r.Parent = core
        makeCorner(r, 1000)
        local s, g = makeGradStroke(r, 3.2 - i * 0.6, 0)
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.1),
            NumberSequenceKeypoint.new(0.56, 1), NumberSequenceKeypoint.new(1, 1),
        })
        rings[i] = {frame = r, stroke = s, size = sz}
        ringGrads[i] = g
    end
    UI.tasks.introRings = function(dt, t)
        for i, g in ipairs(ringGrads) do g.Rotation = (t * ringSpeed[i]) % 360 end
    end

    -- logo letters
    local logo = Instance.new("Frame")
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0.5, 0, 0.5, -6)
    logo.Size = UDim2.fromOffset(220, 70)
    logo.BackgroundTransparency = 1
    logo.ZIndex = 5
    logo.Parent = core
    local logoLay = Instance.new("UIListLayout")
    logoLay.FillDirection = Enum.FillDirection.Horizontal
    logoLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    logoLay.VerticalAlignment = Enum.VerticalAlignment.Center
    logoLay.Padding = UDim.new(0, 2)
    logoLay.Parent = logo

    local finalChars, letters = {"K", "Z", "M"}, {}
    for i = 1, 3 do
        local l = Instance.new("TextLabel")
        l.Size = UDim2.fromOffset(58, 70)
        l.BackgroundTransparency = 1
        l.Text = ""
        l.TextColor3 = C.white
        l.TextTransparency = 1
        l.Font = Enum.Font.GothamBlack
        l.TextSize = 80
        l.LayoutOrder = i
        l.ZIndex = 5
        l.Parent = logo
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Color = ColorSequence.new(C.white, C.accentHi)
        g.Parent = l
        letters[i] = l
    end

    local function mkLabel(text, size, font, color, pos, anchor, align)
        local l = Instance.new("TextLabel")
        l.AnchorPoint = anchor or Vector2.new(0.5, 0.5)
        l.Position = pos
        l.Size = UDim2.fromOffset(240, 16)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color
        l.TextTransparency = 1
        l.Font = font
        l.TextSize = size
        l.TextXAlignment = align or Enum.TextXAlignment.Center
        l.ZIndex = 5
        l.Parent = core
        return l
    end

    local sub = mkLabel("V E R S I O N   3 . 1", 11, Enum.Font.GothamMedium, C.textDim, UDim2.new(0.5, 0, 0.5, 44))
    local status = mkLabel("", 11, Enum.Font.GothamMedium, C.text, UDim2.new(0.5, -120, 0.5, 84), Vector2.new(0, 1), Enum.TextXAlignment.Left)
    local pct = mkLabel("0%", 11, Enum.Font.GothamBold, C.accentHi, UDim2.new(0.5, 120, 0.5, 84), Vector2.new(1, 1), Enum.TextXAlignment.Right)
    pct.Size = UDim2.fromOffset(60, 16)

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.Position = UDim2.new(0.5, 0, 0.5, 92)
    track.Size = UDim2.fromOffset(240, 4)
    track.BackgroundColor3 = Color3.fromRGB(30, 22, 55)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.ZIndex = 5
    track.Parent = core
    makeCorner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.white
    fill.BackgroundTransparency = 1
    fill.BorderSizePixel = 0
    fill.ZIndex = 6
    fill.Parent = track
    makeCorner(fill, 2)
    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent), ColorSequenceKeypoint.new(0.5, C.cyan), ColorSequenceKeypoint.new(1, C.pink),
    })
    fillGrad.Parent = fill

    UI.tasks.introPct = function(dt, t)
        pct.Text = math.floor(fill.Size.X.Scale * 100 + 0.5) .. "%"
        fillGrad.Offset = Vector2.new(math.sin(t * 2) * 0.25, 0)
    end

    local flash = Instance.new("Frame")
    flash.Size = UDim2.fromScale(1, 1)
    flash.BackgroundColor3 = C.white
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel = 0
    flash.ZIndex = 20
    flash.Parent = bg

    local blur
    pcall(function()
        blur = Instance.new("BlurEffect")
        blur.Name = "KZMBlur"
        blur.Size = 0
        blur.Parent = Lighting
    end)

    local function cleanup()
        fading = true
        UI.tasks.introParticles = nil
        UI.tasks.introRings = nil
        UI.tasks.introPct = nil
        if blur then blur:Destroy() end
        gui:Destroy()
    end

    local function setStatus(text)
        status.Text = text
        status.TextTransparency = 0.6
        tween(status, 0.25, {TextTransparency = 0})
    end

    local glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#@%&$"
    local function run()
        tween(bg, 0.5, {BackgroundTransparency = 0.16}, Enum.EasingStyle.Sine)
        if blur then tween(blur, 0.7, {Size = 24}) end
        task.wait(0.15)
        tween(scan, 1.6, {Position = UDim2.new(0, 0, 1.02, 0)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        tween(glowC, 0.9, {Size = UDim2.fromOffset(120, 120), BackgroundTransparency = 0.78})

        for _, r in ipairs(rings) do
            tween(r.frame, 0.9, {Size = UDim2.fromOffset(r.size, r.size)}, Enum.EasingStyle.Back)
            task.wait(0.1)
        end
        task.wait(0.1)

        for i, l in ipairs(letters) do
            task.spawn(function()
                tween(l, 0.25, {TextTransparency = 0})
                tween(l, 0.5, {TextSize = 56}, Enum.EasingStyle.Back)
                for _ = 1, 7 do
                    local k = math.random(#glyphs)
                    l.Text = glyphs:sub(k, k)
                    task.wait(0.04)
                end
                l.Text = finalChars[i]
            end)
            task.wait(0.16)
        end
        task.wait(0.4)

        tween(sub, 0.5, {TextTransparency = 0.2})
        tween(track, 0.4, {BackgroundTransparency = 0})
        tween(fill, 0.4, {BackgroundTransparency = 0})
        tween(pct, 0.4, {TextTransparency = 0})
        local name = LocalPlayer.DisplayName or LocalPlayer.Name
        local stages = {
            {0.20, 0.40, "Loading modules"},
            {0.45, 0.45, "Building interface"},
            {0.70, 0.40, "Syncing settings"},
            {0.92, 0.30, "Finalizing"},
            {1.00, 0.25, "Welcome, " .. name},
        }
        for _, st in ipairs(stages) do
            setStatus(st[3])
            tween(fill, st[2], {Size = UDim2.new(st[1], 0, 1, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            task.wait(st[2] + 0.05)
        end
        task.wait(0.25)

        -- burst
        flash.BackgroundTransparency = 0.55
        tween(flash, 0.55, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
        for _, r in ipairs(rings) do
            tween(r.frame, 0.6, {Size = UDim2.fromOffset(r.size * 2.8, r.size * 2.8)})
            tween(r.stroke, 0.6, {Transparency = 1})
        end
        for _, l in ipairs(letters) do
            tween(l, 0.5, {TextSize = 92, TextTransparency = 1})
        end
        tween(glowC, 0.5, {Size = UDim2.fromOffset(420, 420), BackgroundTransparency = 1})
        tween(sub, 0.3, {TextTransparency = 1})
        tween(status, 0.3, {TextTransparency = 1})
        tween(pct, 0.3, {TextTransparency = 1})
        tween(track, 0.3, {BackgroundTransparency = 1})
        tween(fill, 0.3, {BackgroundTransparency = 1})
        release()
        fading = true
        tween(bg, 0.65, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
        if blur then tween(blur, 0.65, {Size = 0}) end
        task.wait(0.75)
    end

    task.spawn(function()
        local ok, err = pcall(run)
        if not ok then warn("[KZM intro] " .. tostring(err)) end
        release()
        cleanup()
    end)
end

-- ── WINDOW SIZES ─────────────────────────────────────────────
local WIN_W  = 700
local WIN_H  = 420
local TITLE_H = 42
local TAB_H   = 32
local HEADER_H = TITLE_H + TAB_H + 2

-- ── MAIN WINDOW ──────────────────────────────────────────────
local window = Instance.new("Frame")
window.Name             = "KZMWindow"
window.Size             = UDim2.new(0, WIN_W, 0, WIN_H)
window.AnchorPoint      = Vector2.new(0.5, 0.5)
window.Position         = UDim2.new(0.5, 0, 0.5, 30)
window.BackgroundColor3 = C.bg
window.BorderSizePixel  = 0
window.Active           = true
window.Visible          = false
window.ZIndex           = 100
window.Parent           = screenGui
makeCorner(window, 14)
UI.restPos = window.Position

UI.winScale = Instance.new("UIScale")
UI.winScale.Parent = window

function UI.base()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    return math.clamp(math.min((vp.X - 24) / WIN_W, (vp.Y - 24) / WIN_H), 0.45, 1)
end

-- animated gradient glow border + background gradient
do
    local glowBorder = Instance.new("Frame")
    glowBorder.Size                  = UDim2.new(1, 6, 1, 6)
    glowBorder.Position              = UDim2.new(0, -3, 0, -3)
    glowBorder.BackgroundTransparency = 1
    glowBorder.BorderSizePixel       = 0
    glowBorder.ZIndex                = 99
    glowBorder.Parent                = window
    makeCorner(glowBorder, 17)
    local gs, gg = makeGradStroke(glowBorder, 2.5, 0.15)
    UI.glowStroke = gs
    UI.tasks.windowGlow = function(dt, t)
        if window.Visible then gg.Rotation = (t * 55) % 360 end
    end

    local winGrad = Instance.new("UIGradient")
    winGrad.Rotation = 135
    winGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 8, 28)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8,  5, 16)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(12, 7, 24)),
    })
    winGrad.Parent = window
end

-- ── OPEN/CLOSE ANIMATION ─────────────────────────────────────
local isOpen = false

local function openGUI()
    isOpen = true
    local base = UI.base()
    local p = UI.restPos
    window.Visible = true
    UI.winScale.Scale = base * 0.86
    window.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 28)
    tween(UI.winScale, 0.5, {Scale = base}, Enum.EasingStyle.Back)
    tween(window, 0.42, {Position = p})
    UI.glowStroke.Thickness = 6
    tween(UI.glowStroke, 0.9, {Thickness = 2.5})
end

local function closeGUI()
    isOpen = false
    local base = UI.base()
    local p = UI.restPos
    tween(UI.winScale, 0.22, {Scale = base * 0.88}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    tween(window, 0.22, {Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + 24)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.23, function()
        if not isOpen then window.Visible = false end
    end)
end

do
    local cam = workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if isOpen then UI.winScale.Scale = UI.base() end
        end)
    end
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            if isOpen then closeGUI() else openGUI() end
        end
    end)
end

-- ── FLOATING TOGGLE BUTTON (draggable) ───────────────────────
do
    local btn = Instance.new("TextButton")
    btn.Name              = "KZMToggle"
    btn.Size              = UDim2.new(0, 84, 0, 32)
    btn.Position          = UDim2.new(0, 10, 0, 60)
    btn.BackgroundColor3  = C.accent2
    btn.Text              = "KZM"
    btn.TextColor3        = C.white
    btn.Font              = Enum.Font.GothamBold
    btn.TextSize          = 13
    btn.AutoButtonColor   = false
    btn.BorderSizePixel   = 0
    btn.ZIndex            = 200
    btn.Visible           = false   -- shown after the intro ends
    btn.Parent            = screenGui
    makeCorner(btn, 16)
    local _, bg = makeGradStroke(btn, 1.8, 0.1)
    local sc = Instance.new("UIScale")
    sc.Parent = btn
    sc.Scale = 0
    UI.afterIntro(function()
        btn.Visible = true
        tween(sc, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
    end)

    UI.tasks.toggleBtn = function(dt, t)
        bg.Rotation = (t * 90) % 360
        btn.BackgroundColor3 = C.accent2:Lerp(C.accent, 0.5 + 0.5 * math.sin(t * 2.2))
    end

    local drag, moved, dStart, sPos
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, moved, dStart, sPos = true, false, i.Position, btn.Position
            tween(sc, 0.1, {Scale = 0.93})
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dStart
            if d.Magnitude > 6 and not UI.locks.toggle then moved = true end
            if moved then
                btn.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            drag = false
            tween(sc, 0.2, {Scale = 1}, Enum.EasingStyle.Back)
        end
    end)
    btn.MouseEnter:Connect(function() tween(sc, 0.15, {Scale = 1.07}) end)
    btn.MouseLeave:Connect(function() tween(sc, 0.15, {Scale = 1}) end)
    btn.Activated:Connect(function()
        if moved then return end
        if isOpen then closeGUI() else openGUI() end
    end)
end

-- ── TITLE BAR ────────────────────────────────────────────────
do
    local titleBar = Instance.new("Frame")
    titleBar.Name             = "TitleBar"
    titleBar.Size             = UDim2.new(1, 0, 0, TITLE_H)
    titleBar.BackgroundColor3 = C.panel
    titleBar.BorderSizePixel  = 0
    titleBar.ZIndex           = 110
    titleBar.Parent           = window
    makeCorner(titleBar, 14)

    local tbFill = Instance.new("Frame")
    tbFill.Size             = UDim2.new(1, 0, 0, 14)
    tbFill.Position         = UDim2.new(0, 0, 1, -14)
    tbFill.BackgroundColor3 = C.panel
    tbFill.BorderSizePixel  = 0
    tbFill.ZIndex           = 110
    tbFill.Parent           = titleBar

    -- moving gradient underline
    local line = Instance.new("Frame")
    line.Size             = UDim2.new(1, 0, 0, 2)
    line.Position         = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = C.white
    line.BorderSizePixel  = 0
    line.ZIndex           = 111
    line.Parent           = titleBar
    local lineGrad = Instance.new("UIGradient")
    lineGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.accent2),
        ColorSequenceKeypoint.new(0.3, C.accentHi),
        ColorSequenceKeypoint.new(0.5, C.cyan),
        ColorSequenceKeypoint.new(0.7, C.pink),
        ColorSequenceKeypoint.new(1,   C.accent2),
    })
    lineGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.2),
        NumberSequenceKeypoint.new(0.75, 0.2), NumberSequenceKeypoint.new(1, 1),
    })
    lineGrad.Parent = line

    -- logo mark
    local mark = Instance.new("Frame")
    mark.Size             = UDim2.new(0, 26, 0, 26)
    mark.Position         = UDim2.new(0, 12, 0.5, -13)
    mark.BackgroundColor3 = C.white
    mark.BorderSizePixel  = 0
    mark.ZIndex           = 111
    mark.Parent           = titleBar
    makeCorner(mark, 8)
    local markGrad = Instance.new("UIGradient")
    markGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accentHi), ColorSequenceKeypoint.new(0.5, C.accent), ColorSequenceKeypoint.new(1, C.pink),
    })
    markGrad.Parent = mark
    local markLbl = Instance.new("TextLabel")
    markLbl.Size = UDim2.new(1, 0, 1, 0)
    markLbl.BackgroundTransparency = 1
    markLbl.Text = "K"
    markLbl.TextColor3 = C.white
    markLbl.Font = Enum.Font.GothamBlack
    markLbl.TextSize = 15
    markLbl.ZIndex = 112
    markLbl.Parent = mark

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size               = UDim2.new(0, 48, 1, 0)
    titleLbl.Position           = UDim2.new(0, 46, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text               = "KZM"
    titleLbl.TextColor3         = C.white
    titleLbl.Font               = Enum.Font.GothamBold
    titleLbl.TextSize           = 16
    titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
    titleLbl.ZIndex             = 111
    titleLbl.Parent             = titleBar

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 34, 0, 16)
    badge.Position = UDim2.new(0, 92, 0.5, -8)
    badge.BackgroundColor3 = C.section
    badge.Text = "v3.1"
    badge.TextColor3 = C.accentHi
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 9
    badge.BorderSizePixel = 0
    badge.ZIndex = 111
    badge.Parent = titleBar
    makeCorner(badge, 8)
    makeStroke(badge, C.stroke, 1, 0.5)

    -- search
    local search = Instance.new("TextBox")
    search.Name = "Search"
    search.Size = UDim2.new(0, 220, 0, 26)
    search.Position = UDim2.new(0, 142, 0.5, -13)
    search.BackgroundColor3 = C.row
    search.PlaceholderText = "Search features..."
    search.PlaceholderColor3 = C.textDim
    search.Text = ""
    search.TextColor3 = C.text
    search.Font = Enum.Font.Gotham
    search.TextSize = 12
    search.TextXAlignment = Enum.TextXAlignment.Left
    search.ClearTextOnFocus = false
    search.BorderSizePixel = 0
    search.ZIndex = 112
    search.Parent = titleBar
    makeCorner(search, 8)
    local searchStroke = makeStroke(search, C.stroke, 1, 0.5)
    local sp = Instance.new("UIPadding")
    sp.PaddingLeft = UDim.new(0, 10)
    sp.PaddingRight = UDim.new(0, 8)
    sp.Parent = search
    search.Focused:Connect(function()
        tween(searchStroke, 0.15, {Color = C.accentHi, Transparency = 0})
    end)
    search.FocusLost:Connect(function()
        tween(searchStroke, 0.15, {Color = C.stroke, Transparency = 0.5})
    end)
    UI.search = search

    -- live stats
    local sDot = Instance.new("Frame")
    sDot.Size             = UDim2.new(0, 8, 0, 8)
    sDot.Position         = UDim2.new(1, -190, 0.5, -4)
    sDot.BackgroundColor3 = C.green
    sDot.BorderSizePixel  = 0
    sDot.ZIndex           = 111
    sDot.Parent           = titleBar
    makeCorner(sDot, 4)

    local sLbl = Instance.new("TextLabel")
    sLbl.Size               = UDim2.new(0, 140, 1, 0)
    sLbl.Position           = UDim2.new(1, -178, 0, 0)
    sLbl.BackgroundTransparency = 1
    sLbl.Text               = "-- FPS  |  -- ms"
    sLbl.TextColor3         = C.textDim
    sLbl.Font               = Enum.Font.GothamMedium
    sLbl.TextSize           = 10
    sLbl.TextXAlignment     = Enum.TextXAlignment.Left
    sLbl.ZIndex             = 111
    sLbl.Parent             = titleBar

    local acc, frames, statsItem = 0, 0, nil
    pcall(function() statsItem = game:GetService("Stats").Network.ServerStatsItem["Data Ping"] end)
    UI.tasks.titleBar = function(dt, t)
        if not window.Visible then return end
        lineGrad.Offset = Vector2.new(math.sin(t * 0.9) * 0.5, 0)
        markGrad.Rotation = (t * 60) % 360
        sDot.BackgroundTransparency = 0.35 + 0.35 * math.sin(t * 3)
        acc = acc + dt
        frames = frames + 1
        if acc >= 0.5 then
            local ping = 0
            if statsItem then pcall(function() ping = math.floor(statsItem:GetValue()) end) end
            sLbl.Text = math.floor(frames / acc + 0.5) .. " FPS  |  " .. ping .. " ms"
            acc, frames = 0, 0
        end
    end

    -- close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 26, 0, 26)
    closeBtn.Position         = UDim2.new(1, -34, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 55)
    closeBtn.Text             = "x"
    closeBtn.TextColor3       = Color3.fromRGB(200, 140, 210)
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 12
    closeBtn.AutoButtonColor  = false
    closeBtn.BorderSizePixel  = 0
    closeBtn.ZIndex           = 112
    closeBtn.Parent           = titleBar
    makeCorner(closeBtn, 13)
    closeBtn.MouseButton1Click:Connect(closeGUI)
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, 0.12, {BackgroundColor3 = C.red, TextColor3 = C.white, Rotation = 90})
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, 0.12, {BackgroundColor3 = Color3.fromRGB(50, 20, 55), TextColor3 = Color3.fromRGB(200, 140, 210), Rotation = 0})
    end)

    -- drag (global input so fast drags never drop the window)
    local dragging, dragStart, startPos, dragInput
    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos, dragInput = true, i.Position, window.Position, i
            tween(UI.glowStroke, 0.15, {Thickness = 4})
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = (i.Position - dragStart) / UI.winScale.Scale
            local np = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            window.Position = np
            UI.restPos = np
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            tween(UI.glowStroke, 0.25, {Thickness = 2.5})
        end
    end)
end

-- ── CONTENT AREA ─────────────────────────────────────────────
local contentFrame = Instance.new("Frame")
contentFrame.Name             = "Content"
contentFrame.Size             = UDim2.new(1, 0, 1, -HEADER_H)
contentFrame.Position         = UDim2.new(0, 0, 0, HEADER_H)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel  = 0
contentFrame.ClipsDescendants = true
contentFrame.ZIndex           = 100
contentFrame.Parent           = window


-- ── UI HELPERS ─────────────────────────────────────────────────────

local function makeScrollList(parent)
    local sf = Instance.new("ScrollingFrame")
    sf.Size                    = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency  = 1
    sf.BorderSizePixel         = 0
    sf.ScrollBarThickness      = 4
    sf.ScrollBarImageColor3    = C.accent
    sf.ScrollingDirection      = Enum.ScrollingDirection.Y
    sf.CanvasSize              = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize     = Enum.AutomaticSize.Y
    sf.ZIndex                  = 100
    sf.Parent                  = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding             = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.Parent              = sf

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 24)
    pad.PaddingLeft   = UDim.new(0, 6)
    pad.PaddingRight  = UDim.new(0, 6)
    pad.Parent        = sf

    return sf
end


local KZM_DEFAULTS = {}   -- callbacks of toggles that start ON; fired once at the end of load

local function makeToggle(parent, labelText, default, callback)
    if default and callback then table.insert(KZM_DEFAULTS, { name = labelText, fn = callback }) end
    local row = Instance.new("Frame")
    row.Name             = labelText
    row.Size             = UDim2.new(1, -8, 0, 36)
    row.BackgroundColor3 = C.row
    row.BorderSizePixel  = 0
    row.ZIndex           = 100
    row.Parent           = parent
    makeCorner(row, 8)
    local rowStroke = makeStroke(row, default and C.accent or C.stroke, 1, default and 0.2 or 0.5)

    local bar = Instance.new("Frame")
    bar.Size                    = UDim2.new(0, 3, 0.6, 0)
    bar.Position                = UDim2.new(0, 0, 0.2, 0)
    bar.BackgroundColor3        = C.accentHi
    bar.BackgroundTransparency  = default and 0 or 1
    bar.BorderSizePixel         = 0
    bar.ZIndex                  = 101
    bar.Parent                  = row
    makeCorner(bar, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0.7, 0, 1, 0)
    lbl.Position           = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.TextColor3         = default and C.white or C.text
    lbl.Font               = Enum.Font.GothamMedium
    lbl.TextSize           = 12
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 101
    lbl.Parent             = row

    local tBG = Instance.new("Frame")
    tBG.Size             = UDim2.new(0, 44, 0, 22)
    tBG.Position         = UDim2.new(1, -52, 0.5, -11)
    tBG.BackgroundColor3 = default and C.white or C.toggleOff
    tBG.BorderSizePixel  = 0
    tBG.ZIndex           = 101
    tBG.Parent           = row
    makeCorner(tBG, 11)
    local tGrad = Instance.new("UIGradient")
    tGrad.Color = ColorSequence.new(C.accent2, C.accentHi)
    tGrad.Enabled = default and true or false
    tGrad.Parent = tBG

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 102
    knob.Parent           = tBG
    makeCorner(knob, 8)

    local btn = Instance.new("TextButton")
    btn.Size               = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text               = ""
    btn.ZIndex             = 103
    btn.Parent             = row

    local isOn = default or false
    local function setState(v)
        isOn = v
        tGrad.Enabled = isOn
        tween(knob, 0.28, {Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, Enum.EasingStyle.Back)
        tween(tBG,  0.15, {BackgroundColor3 = isOn and C.white or C.toggleOff})
        tween(bar,  0.15, {BackgroundTransparency = isOn and 0 or 1})
        tween(lbl,  0.15, {TextColor3 = isOn and C.white or C.text})
        tween(rowStroke, 0.2, {Color = isOn and C.accent or C.stroke, Transparency = isOn and 0.2 or 0.5})
    end

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn; setState(isOn)
        -- pulse ring on the switch
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.new(0.5, 0, 0.5, 0)
        ring.Size = UDim2.new(1, 0, 1, 0)
        ring.BackgroundTransparency = 1
        ring.ZIndex = 101
        ring.Parent = tBG
        makeCorner(ring, 11)
        local rs = makeStroke(ring, C.accentHi, 2, 0.1)
        tween(ring, 0.4, {Size = UDim2.new(1.5, 0, 1.9, 0)})
        tween(rs, 0.4, {Transparency = 1})
        task.delay(0.42, function() ring:Destroy() end)
        if callback then callback(isOn) end
    end)
    btn.MouseEnter:Connect(function() tween(row, 0.12, {BackgroundColor3 = C.rowHover}) end)
    btn.MouseLeave:Connect(function() tween(row, 0.12, {BackgroundColor3 = C.row}) end)
    return row, setState, function() return isOn end
end

local function makeButton(parent, labelText, callback, bgColor)
    local base = bgColor or C.accent
    local row = Instance.new("TextButton")
    row.Name             = labelText
    row.Size             = UDim2.new(1, -8, 0, 34)
    row.BackgroundColor3 = base
    row.BorderSizePixel  = 0
    row.AutoButtonColor  = false
    row.ClipsDescendants = true
    row.Text             = labelText
    row.TextColor3       = C.white
    row.Font             = Enum.Font.GothamBold
    row.TextSize         = 12
    row.ZIndex           = 100
    row.Parent           = parent
    makeCorner(row, 8)

    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 140, 185))
    g.Parent = row
    local gs = makeStroke(row, C.accentHi, 1.5, 0.55)

    local sc = Instance.new("UIScale")
    sc.Parent = row

    local shine = Instance.new("Frame")
    shine.AnchorPoint = Vector2.new(0.5, 0.5)
    shine.Size = UDim2.new(0, 26, 2.2, 0)
    shine.Position = UDim2.new(-0.15, 0, 0.5, 0)
    shine.Rotation = 20
    shine.BackgroundColor3 = C.white
    shine.BackgroundTransparency = 0.86
    shine.BorderSizePixel = 0
    shine.ZIndex = 101
    shine.Parent = row

    row.MouseButton1Down:Connect(function() tween(sc, 0.08, {Scale = 0.965}) end)
    row.MouseButton1Up:Connect(function() tween(sc, 0.18, {Scale = 1}, Enum.EasingStyle.Back) end)
    row.MouseButton1Click:Connect(function()
        tween(row, 0.08, {BackgroundColor3 = C.accentHi})
        task.delay(0.15, function() tween(row, 0.2, {BackgroundColor3 = base}) end)
        if callback then callback() end
    end)
    row.MouseEnter:Connect(function()
        tween(gs, 0.12, {Transparency = 0})
        shine.Position = UDim2.new(-0.15, 0, 0.5, 0)
        tween(shine, 0.55, {Position = UDim2.new(1.15, 0, 0.5, 0)}, Enum.EasingStyle.Quad)
    end)
    row.MouseLeave:Connect(function()
        tween(gs, 0.12, {Transparency = 0.55})
        tween(sc, 0.15, {Scale = 1})
    end)
    return row
end


local function makeSlider(parent, labelText, minV, maxV, default, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -8, 0, 50)
    row.BackgroundColor3 = C.row
    row.BorderSizePixel  = 0
    row.ZIndex           = 100
    row.Parent           = parent
    makeCorner(row, 8)
    makeStroke(row, C.stroke, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0.65, 0, 0, 20)
    lbl.Position           = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.TextColor3         = C.text
    lbl.Font               = Enum.Font.GothamMedium
    lbl.TextSize           = 12
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 101
    lbl.Parent             = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size               = UDim2.new(0.3, 0, 0, 20)
    valLbl.Position           = UDim2.new(0.68, 0, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text               = tostring(default)
    valLbl.TextColor3         = C.accentHi
    valLbl.Font               = Enum.Font.GothamBold
    valLbl.TextSize           = 12
    valLbl.TextXAlignment     = Enum.TextXAlignment.Right
    valLbl.ZIndex             = 101
    valLbl.Parent             = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -24, 0, 5)
    track.Position         = UDim2.new(0, 12, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(20, 14, 40)
    track.BorderSizePixel  = 0
    track.ZIndex           = 100
    track.Parent           = row
    makeCorner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((default-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 101
    fill.Parent           = track
    makeCorner(fill, 3)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 15, 0, 15)
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new((default-minV)/(maxV-minV), 0, 0.5, 0)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 102
    knob.Parent           = track
    makeCorner(knob, 8)
    makeStroke(knob, C.accent, 1.5, 0.3)
    row.Name = labelText
    local ks = Instance.new("UIScale")
    ks.Parent = knob
    local fg = Instance.new("UIGradient")
    fg.Color = ColorSequence.new(C.accent, C.accentHi)
    fg.Parent = fill

    local dragSl = false
    local function upd(inp)
        local rx = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + (maxV-minV)*rx)
        valLbl.Text = tostring(v)
        fill.Size = UDim2.new(rx, 0, 1, 0)
        knob.Position = UDim2.new(rx, 0, 0.5, 0)
        if callback then callback(v) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragSl = true; upd(i)
            tween(ks, 0.12, {Scale = 1.3})
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragSl and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if dragSl then tween(ks, 0.18, {Scale = 1}, Enum.EasingStyle.Back) end
            dragSl = false
        end
    end)
    return row
end


local function makeSectionRow(parent, text)
    local f = Instance.new("Frame")
    f.Name             = text
    f.Size             = UDim2.new(1, -8, 0, 24)
    f.BackgroundColor3 = C.section
    f.BorderSizePixel  = 0
    f.ZIndex           = 100
    f.Parent           = parent
    makeCorner(f, 6)

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(60, 50, 90))
    g.Parent = f

    local pip = Instance.new("Frame")
    pip.Size             = UDim2.new(0, 3, 0.6, 0)
    pip.Position         = UDim2.new(0, 0, 0.2, 0)
    pip.BackgroundColor3 = C.accentHi
    pip.BorderSizePixel  = 0
    pip.ZIndex           = 101
    pip.Parent           = f
    makeCorner(pip, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -10, 1, 0)
    lbl.Position           = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = string.upper(text)
    lbl.TextColor3         = C.accentHi
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextSize           = 10
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 101
    lbl.Parent             = f
    return f
end


local function makeDropdown(parent, labelText, items, default, callback)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -8, 0, 38)
    row.Name             = labelText
    row.BackgroundColor3 = C.row
    row.BorderSizePixel  = 0
    row.ClipsDescendants = false
    row.ZIndex           = 100
    row.Parent           = parent
    makeCorner(row, 8)
    makeStroke(row, C.stroke, 1, 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0.5, 0, 0, 18)
    lbl.Position           = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.TextColor3         = C.text
    lbl.Font               = Enum.Font.GothamMedium
    lbl.TextSize           = 12
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 101
    lbl.Parent             = row

    local selLbl = Instance.new("TextLabel")
    selLbl.Size               = UDim2.new(0.42, 0, 0, 18)
    selLbl.Position           = UDim2.new(0.52, 0, 0, 4)
    selLbl.BackgroundTransparency = 1
    selLbl.Text               = default or "Select"
    selLbl.TextColor3         = C.accentHi
    selLbl.Font               = Enum.Font.GothamBold
    selLbl.TextSize           = 11
    selLbl.TextXAlignment     = Enum.TextXAlignment.Right
    selLbl.ZIndex             = 101
    selLbl.Parent             = row

    local chevron = Instance.new("TextLabel")
    chevron.Size               = UDim2.new(0, 14, 0, 18)
    chevron.Position           = UDim2.new(1, -18, 0, 4)
    chevron.BackgroundTransparency = 1
    chevron.Text               = "v"
    chevron.TextColor3         = C.textDim
    chevron.Font               = Enum.Font.GothamBold
    chevron.TextSize           = 10
    chevron.ZIndex             = 101
    chevron.Parent             = row

    local listFrame = Instance.new("Frame")
    listFrame.Size             = UDim2.new(1, -4, 0, 0)
    listFrame.Position         = UDim2.new(0, 2, 0, 24)
    listFrame.BackgroundColor3 = Color3.fromRGB(12, 8, 25)
    listFrame.BorderSizePixel  = 0
    listFrame.ClipsDescendants = true
    listFrame.Visible          = false
    listFrame.ZIndex           = 120
    listFrame.Parent           = row
    makeCorner(listFrame, 6)
    makeStroke(listFrame, C.stroke, 1, 0.3)

    local listScroller = Instance.new("ScrollingFrame")
    listScroller.Size              = UDim2.new(1, 0, 1, 0)
    listScroller.BackgroundTransparency = 1
    listScroller.BorderSizePixel   = 0
    listScroller.CanvasSize        = UDim2.new(0, 0, 0, 0)
    listScroller.ScrollBarThickness = 3
    listScroller.ScrollBarImageColor3 = C.accent
    listScroller.ZIndex            = 121
    listScroller.Parent            = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding             = UDim.new(0, 2)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent              = listScroller

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size               = UDim2.new(1, 0, 0, 22)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text               = ""
    clickBtn.ZIndex             = 101
    clickBtn.Parent             = row

    local selectedItem = default
    local ddOpen = false
    local listH = 0

    local function setOpen(open)
        ddOpen = open
        chevron.Text = open and "^" or "v"
        if open then
            listFrame.Visible = true
            listFrame.Size = UDim2.new(1, -4, 0, 0)
            tween(listFrame, 0.22, {Size = UDim2.new(1, -4, 0, listH)})
            tween(row, 0.22, {Size = UDim2.new(1, -8, 0, 38 + listH + 4)})
        else
            tween(listFrame, 0.16, {Size = UDim2.new(1, -4, 0, 0)})
            tween(row, 0.16, {Size = UDim2.new(1, -8, 0, 38)})
            task.delay(0.17, function()
                if not ddOpen then listFrame.Visible = false end
            end)
        end
    end

    local function updateList(newItems, keepSel)
        for _, child in ipairs(listScroller:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local selExists = false
        for _, itemName in ipairs(newItems) do
            local ib = Instance.new("TextButton")
            ib.Size             = UDim2.new(1, -4, 0, 22)
            ib.BackgroundColor3 = C.row
            ib.BorderSizePixel  = 0
            ib.Text             = itemName
            ib.TextColor3       = C.text
            ib.Font             = Enum.Font.Gotham
            ib.TextSize         = 11
            ib.ZIndex           = 122
            ib.Parent           = listScroller
            makeCorner(ib, 5)
            if itemName == selectedItem then selExists = true end
            ib.MouseEnter:Connect(function()
                TweenService:Create(ib, TweenInfo.new(0.1), {BackgroundColor3 = C.rowHover, TextColor3 = C.white}):Play()
            end)
            ib.MouseLeave:Connect(function()
                TweenService:Create(ib, TweenInfo.new(0.1), {BackgroundColor3 = C.row, TextColor3 = C.text}):Play()
            end)
            ib.MouseButton1Click:Connect(function()
                selectedItem = itemName; selLbl.Text = itemName
                setOpen(false)
                if callback then callback(itemName) end
            end)
        end
        if keepSel and selExists then selLbl.Text = selectedItem
        elseif keepSel and not selExists then selectedItem = newItems[1]; selLbl.Text = selectedItem or "Select" end
        task.wait()
        listScroller.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
        local ch = listLayout.AbsoluteContentSize.Y + 4
        listH = math.min(140, ch)
        if ddOpen then listFrame.Size = UDim2.new(1, -4, 0, listH) end
        if callback and selectedItem then callback(selectedItem) end
    end

    clickBtn.MouseButton1Click:Connect(function() setOpen(not ddOpen) end)
    updateList(items, true)
    row.Size = UDim2.new(1, -8, 0, 38)
    return row, updateList, function() return selectedItem end
end


-- ── TABS ─────────────────────────────────────────────────────
local tabs = {}
local tabFrames = {}
local tabNames = {"Main", "Combat", "Auto", "Target", "Extra", "Configs"}
local TAB_W, TAB_GAP = 88, 3
local currentTab

local function tabX(idx) return 6 + (idx - 1) * (TAB_W + TAB_GAP) end

local function switchTab(name)
    local idx = 1
    for i, n in ipairs(tabNames) do if n == name then idx = i end end
    for _, tData in pairs(tabs) do
        local isActive = tData.name == name
        tData.btn.TextColor3 = isActive and C.white or C.textDim
        tData.btn.Font = isActive and Enum.Font.GothamBold or Enum.Font.Gotham
        local f = tabFrames[tData.name]
        if f then
            if isActive then
                if currentTab ~= name then
                    f.Position = UDim2.new(0, 0, 0, 16)
                    f.Visible = true
                    tween(f, 0.32, {Position = UDim2.new(0, 0, 0, 0)})
                else
                    f.Visible = true
                end
            else
                f.Visible = false
            end
        end
    end
    currentTab = name
    if UI.tabPill then
        tween(UI.tabPill, 0.32, {Position = UDim2.new(0, tabX(idx), 0, 3)}, Enum.EasingStyle.Back)
    end
end

do
    local tabBar = Instance.new("Frame")
    tabBar.Name             = "TabBar"
    tabBar.Size             = UDim2.new(1, 0, 0, TAB_H)
    tabBar.Position         = UDim2.new(0, 0, 0, TITLE_H)
    tabBar.BackgroundColor3 = Color3.fromRGB(12, 8, 24)
    tabBar.BorderSizePixel  = 0
    tabBar.ZIndex           = 109
    tabBar.Parent           = window

    local tabSep = Instance.new("Frame")
    tabSep.Size             = UDim2.new(1, 0, 0, 1)
    tabSep.Position         = UDim2.new(0, 0, 0, TITLE_H + TAB_H)
    tabSep.BackgroundColor3 = C.stroke
    tabSep.BackgroundTransparency = 0.6
    tabSep.BorderSizePixel  = 0
    tabSep.ZIndex           = 108
    tabSep.Parent           = window

    -- sliding highlight pill
    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, TAB_W, 0, TAB_H - 6)
    pill.Position         = UDim2.new(0, tabX(1), 0, 3)
    pill.BackgroundColor3 = C.white
    pill.BorderSizePixel  = 0
    pill.ZIndex           = 109
    pill.Parent           = tabBar
    makeCorner(pill, 7)
    local pg = Instance.new("UIGradient")
    pg.Rotation = 90
    pg.Color = ColorSequence.new(C.accentHi, C.accent2)
    pg.Parent = pill
    makeStroke(pill, C.accentHi, 1, 0.5)
    UI.tabPill = pill

    for i, name in ipairs(tabNames) do
        local btn = Instance.new("TextButton")
        btn.Name             = name
        btn.Size             = UDim2.new(0, TAB_W, 0, TAB_H - 6)
        btn.Position         = UDim2.new(0, tabX(i), 0, 3)
        btn.BackgroundTransparency = 1
        btn.AutoButtonColor  = false
        btn.Text             = name
        btn.TextColor3       = C.textDim
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 12
        btn.BorderSizePixel  = 0
        btn.ZIndex           = 110
        btn.Parent           = tabBar

        local tabFrame = Instance.new("Frame")
        tabFrame.Size                   = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible                = false
        tabFrame.ZIndex                 = 100
        tabFrame.Parent                 = contentFrame

        tabFrames[name] = tabFrame
        tabs[name] = {name = name, btn = btn, frame = tabFrame}

        btn.MouseButton1Click:Connect(function() switchTab(name) end)
        btn.MouseEnter:Connect(function()
            if currentTab ~= name then tween(btn, 0.12, {TextColor3 = C.text}) end
        end)
        btn.MouseLeave:Connect(function()
            if currentTab ~= name then tween(btn, 0.12, {TextColor3 = C.textDim}) end
        end)
    end
end

local scrolls = {}
for _, name in ipairs(tabNames) do
    scrolls[name] = makeScrollList(tabFrames[name])
end

-- ── SEARCH FILTER (rows are named after their labels) ────────
do
    local function applySearch()
        local q = string.lower(UI.search.Text)
        local firstMatch, currentHas
        for _, tname in ipairs(tabNames) do
            local any = false
            for _, ch in ipairs(scrolls[tname]:GetChildren()) do
                if ch:IsA("GuiObject") then
                    if q == "" then
                        if ch:GetAttribute("kzmHid") then
                            ch.Visible = true
                            ch:SetAttribute("kzmHid", nil)
                        end
                    else
                        local match = string.find(string.lower(ch.Name), q, 1, true) ~= nil
                        if match then
                            any = true
                            if ch:GetAttribute("kzmHid") then
                                ch.Visible = true
                                ch:SetAttribute("kzmHid", nil)
                            end
                        elseif ch.Visible then
                            ch.Visible = false
                            ch:SetAttribute("kzmHid", true)
                        end
                    end
                end
            end
            if any and not firstMatch then firstMatch = tname end
            if any and tname == currentTab then currentHas = true end
        end
        if q ~= "" and firstMatch and not currentHas then switchTab(firstMatch) end
    end
    UI.search:GetPropertyChangedSignal("Text"):Connect(applySearch)
end


-- ── FLOATING ACTION BUTTONS (Lock-On + Fly share this factory) ─────
shared.KZMBtnPos = shared.KZMBtnPos or {}

local function createFloatingButton(cfg)
    local SIZE, PILL_H = 96, 24
    local B = { active = false, shown = false, _click = nil }

    local function screenSize()
        local s = screenGui.AbsoluteSize
        if s.X < 50 then
            local cam = workspace.CurrentCamera
            s = cam and cam.ViewportSize or Vector2.new(1280, 720)
        end
        return s
    end

    local function clampPos(x, y)
        local s = screenSize()
        x = math.clamp(x, SIZE / 2 + 8, s.X - SIZE / 2 - 8)
        y = math.clamp(y, 8, s.Y - (SIZE + PILL_H + 14) - 8)
        return x, y
    end

    local saved = shared.KZMBtnPos[cfg.name]
    local px, py
    if saved then
        px, py = saved[1], saved[2]
    else
        local s = screenSize()
        px, py = s.X * cfg.startFrac[1], s.Y * cfg.startFrac[2]
    end
    px, py = clampPos(px, py)

    -- root (top-centre anchored, holds disc + pill)
    local root = Instance.new("Frame")
    root.Name = cfg.name
    root.AnchorPoint = Vector2.new(0.5, 0)
    root.Position = UDim2.fromOffset(px, py)
    root.Size = UDim2.new(0, SIZE + 24, 0, SIZE + PILL_H + 10)
    root.BackgroundTransparency = 1
    root.Visible = false
    root.ZIndex = 201
    root.Parent = screenGui

    local showScale = Instance.new("UIScale")
    showScale.Scale = 0
    showScale.Parent = root

    -- soft glow behind the disc
    local glow = Instance.new("Frame")
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.new(0.5, 0, 0, SIZE / 2)
    glow.Size = UDim2.new(0, SIZE + 22, 0, SIZE + 22)
    glow.BackgroundColor3 = C.accent
    glow.BackgroundTransparency = 0.88
    glow.BorderSizePixel = 0
    glow.ZIndex = 199
    glow.Parent = root
    makeCorner(glow, 100)

    -- expanding pulse ring (only visible while active)
    local pulse = Instance.new("Frame")
    pulse.AnchorPoint = Vector2.new(0.5, 0.5)
    pulse.Position = UDim2.new(0.5, 0, 0, SIZE / 2)
    pulse.Size = UDim2.new(0, SIZE, 0, SIZE)
    pulse.BackgroundTransparency = 1
    pulse.BorderSizePixel = 0
    pulse.Visible = false
    pulse.ZIndex = 200
    pulse.Parent = root
    makeCorner(pulse, 100)
    local pulseStroke = makeStroke(pulse, C.accent, 2.5, 0.4)

    -- main disc
    local disc = Instance.new("Frame")
    disc.AnchorPoint = Vector2.new(0.5, 0)
    disc.Position = UDim2.new(0.5, 0, 0, 0)
    disc.Size = UDim2.new(0, SIZE, 0, SIZE)
    disc.BackgroundColor3 = Color3.fromRGB(9, 6, 20)
    disc.BackgroundTransparency = 0.08
    disc.BorderSizePixel = 0
    disc.ZIndex = 202
    disc.Parent = root
    makeCorner(disc, 100)

    local discGrad = Instance.new("UIGradient")
    discGrad.Rotation = 90
    discGrad.Color = ColorSequence.new(Color3.fromRGB(34, 24, 66), Color3.fromRGB(8, 5, 18))
    discGrad.Parent = disc

    local pressScale = Instance.new("UIScale")
    pressScale.Parent = disc

    -- animated gradient rim
    local rim = Instance.new("UIStroke")
    rim.Color = C.white
    rim.Thickness = 3
    rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    rim.Parent = disc
    local rimGrad = Instance.new("UIGradient")
    local function idleSeq()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.accent),
            ColorSequenceKeypoint.new(0.33, C.cyan),
            ColorSequenceKeypoint.new(0.66, C.pink),
            ColorSequenceKeypoint.new(1, C.accent),
        })
    end
    local function activeSeq()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, cfg.accent),
            ColorSequenceKeypoint.new(0.5, C.white),
            ColorSequenceKeypoint.new(1, cfg.accent),
        })
    end
    rimGrad.Color = idleSeq()
    rimGrad.Parent = rim

    -- inner decorative ring
    local inner = Instance.new("Frame")
    inner.AnchorPoint = Vector2.new(0.5, 0.5)
    inner.Position = UDim2.new(0.5, 0, 0.5, 0)
    inner.Size = UDim2.new(0.8, 0, 0.8, 0)
    inner.BackgroundTransparency = 1
    inner.ZIndex = 203
    inner.Parent = disc
    makeCorner(inner, 100)
    local innerStroke = makeStroke(inner, C.accentHi, 1.5, 0.65)

    -- icon holder (animated while active)
    local iconHolder = Instance.new("Frame")
    iconHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    iconHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    iconHolder.Size = UDim2.new(1, 0, 1, 0)
    iconHolder.BackgroundTransparency = 1
    iconHolder.ZIndex = 204
    iconHolder.Parent = disc
    local iconParts, iconStrokes = cfg.icon(iconHolder)

    -- status pill under the disc
    local pill = Instance.new("Frame")
    pill.AnchorPoint = Vector2.new(0.5, 0)
    pill.Position = UDim2.new(0.5, 0, 0, SIZE + 8)
    pill.Size = UDim2.new(1, 0, 0, PILL_H)
    pill.BackgroundColor3 = Color3.fromRGB(9, 6, 20)
    pill.BackgroundTransparency = 0.1
    pill.BorderSizePixel = 0
    pill.ZIndex = 202
    pill.Parent = root
    makeCorner(pill, 12)
    local pillStroke = makeStroke(pill, C.stroke, 1.2, 0.3)

    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0, 0.5)
    dot.Position = UDim2.new(0, 9, 0.5, 0)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.BackgroundColor3 = C.textDim
    dot.BorderSizePixel = 0
    dot.ZIndex = 203
    dot.Parent = pill
    makeCorner(dot, 4)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 22, 0, 0)
    titleLbl.Size = UDim2.new(0, 34, 1, 0)
    titleLbl.Text = cfg.title
    titleLbl.TextColor3 = C.white
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 203
    titleLbl.Parent = pill

    local statusLbl = Instance.new("TextLabel")
    statusLbl.BackgroundTransparency = 1
    statusLbl.Position = UDim2.new(0, 54, 0, 0)
    statusLbl.Size = UDim2.new(1, -62, 1, 0)
    statusLbl.Text = cfg.idleText
    statusLbl.TextColor3 = C.textDim
    statusLbl.Font = Enum.Font.GothamMedium
    statusLbl.TextSize = 10
    statusLbl.TextXAlignment = Enum.TextXAlignment.Right
    statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
    statusLbl.ZIndex = 203
    statusLbl.Parent = pill

    -- hit area
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.ZIndex = 210
    hit.Parent = disc

    -- ── state / visuals ──
    local function applyColors()
        local col = B.active and cfg.accent or C.accentHi
        for _, p in ipairs(iconParts) do tween(p, 0.25, { BackgroundColor3 = col }) end
        for _, s in ipairs(iconStrokes) do tween(s, 0.25, { Color = col }) end
        tween(glow, 0.3, { BackgroundColor3 = B.active and cfg.accent or C.accent })
        tween(innerStroke, 0.3, { Color = col, Transparency = B.active and 0.3 or 0.65 })
        tween(pillStroke, 0.3, { Color = B.active and cfg.accent or C.stroke })
        tween(dot, 0.3, { BackgroundColor3 = B.active and cfg.accent or C.textDim })
        tween(statusLbl, 0.3, { TextColor3 = B.active and C.white or C.textDim })
        tween(disc, 0.3, { BackgroundColor3 = B.active and cfg.bgActive or Color3.fromRGB(9, 6, 20) })
        pulseStroke.Color = cfg.accent
        rimGrad.Color = B.active and activeSeq() or idleSeq()
        pulse.Visible = B.active
    end

    function B.setActive(a, text)
        local changed = (B.active ~= a)
        B.active = a and true or false
        statusLbl.Text = text or (B.active and cfg.activeText or cfg.idleText)
        applyColors()
        if changed then
            -- little pop so the state change is obvious
            tween(pressScale, 0.1, { Scale = 1.12 })
            task.delay(0.1, function() tween(pressScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back) end)
        end
    end

    function B.setStatus(text) statusLbl.Text = text end

    function B.setVisible(v)
        B.shown = v and true or false
        if v then
            root.Visible = true
            showScale.Scale = 0.4
            tween(showScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
        else
            tween(showScale, 0.2, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.22, function()
                if not B.shown then root.Visible = false end
            end)
        end
    end

    function B.onClick(fn) B._click = fn end
    B.root = root

    -- ── drag + tap (tap only fires if the finger barely moved) ──
    local dragging, moved, dragInput, dragStart, startX, startY = false, false, nil, nil, 0, 0

    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, dragInput, dragStart = true, false, i, i.Position
            startX, startY = px, py
            tween(pressScale, 0.08, { Scale = 0.9 })
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        local isMouse = i.UserInputType == Enum.UserInputType.MouseMovement
        local isTouch = i.UserInputType == Enum.UserInputType.Touch and i == dragInput
        if not (isMouse or isTouch) then return end
        local d = i.Position - dragStart
        if not moved and d.Magnitude > 10 and not UI.locks[cfg.lockKey] then
            moved = true
            tween(pressScale, 0.12, { Scale = 1.06 })
        end
        if moved then
            px, py = clampPos(startX + d.X, startY + d.Y)
            root.Position = UDim2.fromOffset(px, py)
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if not dragging then return end
        local isMouse = i.UserInputType == Enum.UserInputType.MouseButton1
        local isTouch = i.UserInputType == Enum.UserInputType.Touch and i == dragInput
        if not (isMouse or isTouch) then return end
        dragging = false
        tween(pressScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
        if moved then
            shared.KZMBtnPos[cfg.name] = { px, py }
        elseif B._click then
            -- ripple
            local rip = Instance.new("Frame")
            rip.AnchorPoint = Vector2.new(0.5, 0.5)
            rip.Position = UDim2.new(0.5, 0, 0.5, 0)
            rip.Size = UDim2.new(0.4, 0, 0.4, 0)
            rip.BackgroundTransparency = 1
            rip.ZIndex = 205
            rip.Parent = disc
            makeCorner(rip, 100)
            local rs = makeStroke(rip, C.white, 3, 0.2)
            tween(rip, 0.45, { Size = UDim2.new(1.5, 0, 1.5, 0) })
            tween(rs, 0.45, { Transparency = 1 })
            task.delay(0.5, function() rip:Destroy() end)
            task.spawn(function()
                local ok, err = pcall(B._click)
                if not ok then warn("[KZM] " .. cfg.name .. ": " .. tostring(err)) end
            end)
        end
    end)

    -- keep on screen if the viewport changes (rotation, resize)
    local cam = workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            px, py = clampPos(px, py)
            root.Position = UDim2.fromOffset(px, py)
        end)
    end

    -- ── ambient animation (driven by the shared UI render loop) ──
    UI.tasks["btn_" .. cfg.name] = function(dt, t)
        if not root.Visible then return end
        rimGrad.Rotation = (t * (B.active and 200 or 60)) % 360
        glow.BackgroundTransparency = 0.86 + 0.06 * math.sin(t * 2.2)
        if B.active then
            local ph = (t % 1.4) / 1.4
            pulse.Size = UDim2.new(0, SIZE * (1 + 0.55 * ph), 0, SIZE * (1 + 0.55 * ph))
            pulseStroke.Transparency = 0.3 + 0.7 * ph
            if cfg.activeAnim == "spin" then
                iconHolder.Rotation = (t * 45) % 360
            elseif cfg.activeAnim == "bob" then
                iconHolder.Position = UDim2.new(0.5, 0, 0.5, math.sin(t * 5) * 3)
            end
        else
            iconHolder.Rotation = 0
            iconHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
        end
    end

    B.setActive(false)
    return B
end

-- icon: crosshair
local function crosshairIcon(parent)
    local parts, strokes = {}, {}
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring.Size = UDim2.new(0, 34, 0, 34)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 204
    ring.Parent = parent
    makeCorner(ring, 100)
    table.insert(strokes, makeStroke(ring, C.accentHi, 2.5, 0))
    local function tick(ox, oy, w, h)
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.new(0.5, ox, 0.5, oy)
        f.Size = UDim2.new(0, w, 0, h)
        f.BackgroundColor3 = C.accentHi
        f.BorderSizePixel = 0
        f.ZIndex = 205
        f.Parent = parent
        makeCorner(f, 2)
        table.insert(parts, f)
    end
    tick(0, -17, 3, 13); tick(0, 17, 3, 13)
    tick(-17, 0, 13, 3); tick(17, 0, 13, 3)
    local dotF = Instance.new("Frame")
    dotF.AnchorPoint = Vector2.new(0.5, 0.5)
    dotF.Position = UDim2.new(0.5, 0, 0.5, 0)
    dotF.Size = UDim2.new(0, 7, 0, 7)
    dotF.BackgroundColor3 = C.accentHi
    dotF.BorderSizePixel = 0
    dotF.ZIndex = 205
    dotF.Parent = parent
    makeCorner(dotF, 4)
    table.insert(parts, dotF)
    return parts, strokes
end

-- icon: double up-chevron (wings)
local function wingsIcon(parent)
    local parts, strokes = {}, {}
    local function arm(ox, oy, rot)
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.new(0.5, ox, 0.5, oy)
        f.Size = UDim2.new(0, 22, 0, 5)
        f.Rotation = rot
        f.BackgroundColor3 = C.accentHi
        f.BorderSizePixel = 0
        f.ZIndex = 205
        f.Parent = parent
        makeCorner(f, 3)
        table.insert(parts, f)
    end
    arm(-8, -9, -42); arm(8, -9, 42)
    arm(-8, 7, -42);  arm(8, 7, 42)
    return parts, strokes
end

local LockBtn = createFloatingButton({
    name = "LockOnBtn", lockKey = "lockOn", title = "LOCK", idleText = "IDLE", activeText = "LOCKED",
    accent = C.red, bgActive = Color3.fromRGB(28, 6, 14),
    startFrac = { 0.82, 0.38 }, icon = crosshairIcon, activeAnim = "spin",
})
local LOFrame = LockBtn.root

local FlyBtn = createFloatingButton({
    name = "FlyBtn", lockKey = "fly", title = "FLY", idleText = "OFF", activeText = "FLYING",
    accent = C.cyan, bgActive = Color3.fromRGB(6, 22, 32),
    startFrac = { 0.82, 0.12 }, icon = wingsIcon, activeAnim = "bob",
})

local function setLockedTheme(name)
    local txt = name and tostring(name) or "LOCKED"
    LockBtn.setActive(true, txt)
end

local function setIdleTheme()
    LockBtn.setActive(false, "IDLE")
end

switchTab("Main")
UI.afterIntro(function()
    openGUI()
    UI.notify("KZM loaded", "Press RightShift to show or hide the menu.", C.accent, 4)
end)

-- ==========================================
-- TARGETING: Crosshair-based (Players + Dummy NPC only)
-- ==========================================
local function getNearestTarget()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local cam = workspace.CurrentCamera
    if not cam then return nil end

    local bestResult = nil
    local bestDot    = -math.huge

    local function score(char)
        if char == myChar then return end
        local tHRP = char:FindFirstChild("HumanoidRootPart")
        local tHum = char:FindFirstChildOfClass("Humanoid")
        if not tHRP or not tHum or tHum.Health <= 0 then return end
        local toTarget = (tHRP.Position - cam.CFrame.Position)
        if toTarget.Magnitude == 0 then return end
        local dot = cam.CFrame.LookVector:Dot(toTarget.Unit)
        if dot > bestDot and dot > 0 then
            bestDot    = dot
            bestResult = { character = char, root = tHRP, humanoid = tHum }
        end
    end

    -- 1) Score all player characters
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            score(p.Character)
        end
    end

    -- 2) Score ONLY Models named exactly "Dummy"
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Dummy" and obj ~= myChar then
            score(obj)
        end
    end

    return bestResult
end

-- ==========================================
-- INSTANT RESPAWN LOGIC (from standalone)
-- ==========================================
local hasHookMetamethod = type(hookmetamethod) == "function"
local hasCheckcaller = type(checkcaller) == "function"
local hasNewcclosure = type(newcclosure) == "function"
local hasReplicatesignal = type(replicatesignal) == "function"

local instantRespawnEnabled = false
local spState = { enabled = false, loc = CFrame.new() }
local svColls = {}
local ncConn = nil
local bpHb = nil
local oldIdx = nil
local oldNc = nil

local function applyNoCollide(dur)
    if ncConn then pcall(function() ncConn:Disconnect() end) end
    table.clear(svColls)
    local function disableCollisions()
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                if svColls[p] == nil then svColls[p] = p.CanCollide end
                p.CanCollide = false
            end
        end
    end
    disableCollisions()
    ncConn = RunService.Stepped:Connect(disableCollisions)
    task.delay(dur, function()
        if ncConn then pcall(function() ncConn:Disconnect() end) end
        local char = LocalPlayer.Character
        if char then
            for p, can in pairs(svColls) do
                if p and p.Parent then p.CanCollide = can end
            end
        end
        table.clear(svColls)
    end)
end

local function triggerRespawnBypass()
    if not hasHookMetamethod or not hasCheckcaller or not hasNewcclosure then return end
    if not instantRespawnEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then return end

    applyNoCollide(5)
    spState.enabled = true
    pcall(function()
        if hasReplicatesignal then replicatesignal(hum.ServerBreakJoints) end
    end)
    if bpHb then pcall(function() bpHb:Disconnect() end) end
    bpHb = RunService.Heartbeat:Connect(function()
        if not spState.enabled then
            if bpHb then pcall(function() bpHb:Disconnect() end) end
            return
        end
        local c = LocalPlayer.Character
        local root = c and c:FindFirstChild("HumanoidRootPart")
        if root then
            spState.loc = root.CFrame
            root.CFrame = CFrame.new(0, 10000, 0)
            task.wait()
            if root and root.Parent then root.CFrame = spState.loc end
        end
    end)
    task.delay(0.5, function()
        spState.enabled = false
        if bpHb then pcall(function() bpHb:Disconnect() end) end
    end)
end

-- Set up hooks once
if hasHookMetamethod and hasCheckcaller and hasNewcclosure then
    oldIdx = hookmetamethod(game, "__index", newcclosure(function(self, idx)
        if not instantRespawnEnabled then return oldIdx(self, idx) end
        if spState.enabled and not checkcaller() and idx == "CFrame" then
            local char = LocalPlayer.Character
            if char and self == char:FindFirstChild("HumanoidRootPart") then
                return spState.loc
            end
        end
        return oldIdx(self, idx)
    end))
end

local resetRem = nil
pcall(function()
    resetRem = ReplicatedStorage:WaitForChild("Knit", 5)
            :WaitForChild("Knit", 5)
            :WaitForChild("Services", 5)
            :WaitForChild("JoinService", 5)
            :WaitForChild("RE", 5)
            :WaitForChild("Reset", 5)
end)

if resetRem and hasHookMetamethod and hasNewcclosure then
    oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not instantRespawnEnabled then return oldNc(self, ...) end
        if self == resetRem and getnamecallmethod() == "FireServer" then
            if bpHb then pcall(function() bpHb:Disconnect() end) end
            spState.enabled = false
            task.spawn(triggerRespawnBypass)
        end
        return oldNc(self, ...)
    end))
end

-- One‑shot instant respawn function (now silent – no notification)
local function instantRespawnNow()
    if not (hasHookMetamethod and hasCheckcaller and hasNewcclosure) then
        pcall(function() LocalPlayer:LoadCharacter() end)
        return
    end
    instantRespawnEnabled = true
    task.spawn(function()
        triggerRespawnBypass()
        task.wait(0.6)
        instantRespawnEnabled = false
        spState.enabled = false
        if bpHb then pcall(function() bpHb:Disconnect() end); bpHb = nil end
        if ncConn then pcall(function() ncConn:Disconnect() end); ncConn = nil end
    end)
end

-- ==========================================
-- MAIN TAB
-- ==========================================
local mainS = scrolls["Main"]

makeSectionRow(mainS, "Movement")

-- No Parkour Cooldown — enabled by default
makeToggle(mainS, "No Parkour Cooldown", true, function(state)
    if state then
        local ok, MC = pcall(function()
            return require(LocalPlayer.PlayerScripts.Controllers.Character.MovementController)
        end)
        if ok and MC then
            RunService:BindToRenderStep("Parkour-Inf", 0, function()
                debug.setupvalue(MC.Parkour, 2, 0)
            end)
        end
    else
        RunService:UnbindFromRenderStep("Parkour-Inf")
    end
end)

-- ==========================================
-- FLY FEATURE (ported from yes build: BodyVelocity + BodyGyro, camera-driven,
-- Rush/hover anims, wind trail, loop + sonic boom sfx, FOV kick)
-- Boost = LeftControl, Slow = LeftAlt (PC). Mobile thumbstick via PlayerModule controls.
-- ==========================================
do
local Debris = game:GetService("Debris")

local FlyCfg = { FlySpeed = 180, FlyBoost = 400, FlySlow = 80, FlyFov = 35 }

local function flyPick(root, ...)
    local n = root
    for _, k in ipairs({ ... }) do
        n = n and n:FindFirstChild(k)
    end
    return n
end

local flyRush = flyPick(RS, "Animations", "Itadori", "Rush")
local flyWind = flyPick(RS, "Utils", "Naoya", "FlyWind")
local flyLoop = flyPick(RS, "Sounds", "Megumi", "Serpent", "Fly")
local flyBoom = flyPick(RS, "Sounds", "Naoya", "TopSpeed", "SonicBoom")

local flyHover = Instance.new("Animation")
flyHover.AnimationId = "rbxassetid://96310332498648"

local flyCtrl
task.spawn(function()
    pcall(function()
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        local pm = ps and ps:WaitForChild("PlayerModule", 5)
        flyCtrl = pm and require(pm):GetControls()
    end)
end)

local FLY_KB, FLY_KS = Enum.KeyCode.LeftControl, Enum.KeyCode.LeftAlt
local FLY_PRIO = Enum.AnimationPriority.Action4
local FLY_HUGE = Vector3.one * math.huge

local function flyLerp(a, b, t) return a + (b - a) * t end

local function flyMoveVec()
    if flyCtrl then return flyCtrl:GetMoveVector() end
    local x, z = 0, 0
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then z = z - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then z = z + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then x = x - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then x = x + 1 end
    return Vector3.new(x, 0, z)
end

local flyActive, flyWant = false, false
local flyBoost, flySlow = false, false
local flyBV, flyBG, flyWindClone, flySfx, flyTrack, flyIdle, flyConn, flyDiedConn
local flyWindFx, flyWindOn, flyBoomed = nil, false, false
local flyFov0 = 70

local function stopFly()
    if not flyActive then return end
    flyActive = false
    flyBoost, flySlow = false, false
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyDiedConn then flyDiedConn:Disconnect(); flyDiedConn = nil end
    if flyTrack then flyTrack:Stop(0.3); flyTrack = nil end
    if flyIdle then flyIdle:Stop(0.3); flyIdle = nil end
    if flyBV then
        local rt = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rt then rt.AssemblyLinearVelocity = flyBV.Velocity end
        flyBV:Destroy(); flyBV = nil
    end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    if flyWindClone then flyWindClone:Destroy(); flyWindClone = nil end
    if flySfx then flySfx:Stop(); flySfx:Destroy(); flySfx = nil end
    flyWindFx, flyWindOn, flyBoomed = nil, false, false
    workspace.CurrentCamera.FieldOfView = flyFov0
    local ch = LocalPlayer.Character
    if not ch then return end
    local h = ch:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand = false end
    local a = ch:FindFirstChild("Animate")
    if a then a.Disabled = false end
end

local function startFly()
    if flyActive then return true end
    local ch = LocalPlayer.Character
    local rt = ch and ch:FindFirstChild("HumanoidRootPart")
    local h = ch and ch:FindFirstChildOfClass("Humanoid")
    if not (rt and h and h.Health > 0) then return false end
    flyActive = true
    flyBoomed, flyWindOn = false, false

    local a = ch:FindFirstChild("Animate")
    if a then a.Disabled = true end
    h.PlatformStand = true
    for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:Stop(0.1) end

    local anm = h:FindFirstChildOfClass("Animator")
    if flyRush then
        flyTrack = anm and anm:LoadAnimation(flyRush) or h:LoadAnimation(flyRush)
        flyTrack.Priority = FLY_PRIO
    end
    flyIdle = anm and anm:LoadAnimation(flyHover) or h:LoadAnimation(flyHover)
    flyIdle.Priority = FLY_PRIO

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = FLY_HUGE
    flyBV.Velocity = rt.AssemblyLinearVelocity
    flyBV.Parent = rt

    flyBG = Instance.new("BodyGyro")
    flyBG.P, flyBG.D = 35000, 1200
    flyBG.MaxTorque = FLY_HUGE
    flyBG.CFrame = rt.CFrame
    flyBG.Parent = rt

    local cam = workspace.CurrentCamera
    flyFov0 = cam.FieldOfView

    if flyWind then
        flyWindClone = flyWind:Clone()
        flyWindFx = {}
        for _, v in ipairs(flyWindClone:GetDescendants()) do
            if v:IsA("Trail") or v:IsA("ParticleEmitter") then
                v.Enabled = false
                flyWindFx[#flyWindFx + 1] = v
            end
        end
        flyWindClone.Parent = cam
    end

    if flyLoop then
        flySfx = flyLoop:Clone()
        flySfx.Looped = true
        flySfx.Volume = 0
        flySfx.Parent = rt
        flySfx:Play()
    end

    flyDiedConn = h.Died:Once(stopFly)

    flyConn = RunService.RenderStepped:Connect(function()
        if not (flyActive and rt.Parent and h.Parent) then return stopFly() end
        local cf = cam.CFrame
        local mv = flyMoveVec()
        local dir = cf.LookVector * -mv.Z + cf.RightVector * mv.X
        local mag = dir.Magnitude
        local fast = flyBoost or UserInputService:IsKeyDown(FLY_KB)
        local slow = not fast and (flySlow or UserInputService:IsKeyDown(FLY_KS))
        local spd = fast and FlyCfg.FlyBoost or (slow and FlyCfg.FlySlow or FlyCfg.FlySpeed)

        if fast and mag > 0 then
            if not flyBoomed and flyBoom then
                local b = flyBoom:Clone()
                b.Volume = 0.5
                b.Parent = rt
                b:Play()
                Debris:AddItem(b, 3)
            end
            flyBoomed = true
        elseif not fast then
            flyBoomed = false
        end

        if mag > 0 then
            local u = dir / mag
            flyBV.Velocity = flyBV.Velocity:Lerp(u * spd, 0.12)
            flyBG.CFrame = flyBG.CFrame:Lerp(CFrame.lookAt(Vector3.zero, u) * CFrame.Angles(0, 0, math.rad(-cf.RightVector:Dot(u) * 35)), 0.1)
            if flyIdle.IsPlaying then flyIdle:Stop(0.3) end
            if flyTrack then
                if not flyTrack.IsPlaying then flyTrack:Play(0.3) end
                flyTrack.TimePosition = 0.67
                flyTrack:AdjustSpeed(0)
            end
            if flyWindClone then
                flyWindClone.CFrame = CFrame.lookAlong(rt.Position, flyBV.Velocity)
                if not flyWindOn then
                    for _, v in ipairs(flyWindFx) do v.Enabled = true end
                    flyWindOn = true
                end
            end
            if flySfx then
                flySfx.Volume = flyLerp(flySfx.Volume, fast and 1.5 or 0.8, 0.1)
                flySfx.PlaybackSpeed = flyLerp(flySfx.PlaybackSpeed, fast and 1.2 or 0.9, 0.1)
            end
        else
            flyBV.Velocity = flyBV.Velocity:Lerp(Vector3.zero, 0.1)
            local lv = cf.LookVector
            flyBG.CFrame = flyBG.CFrame:Lerp(CFrame.lookAt(Vector3.zero, Vector3.new(lv.X, 0, lv.Z)), 0.06)
            if flyTrack and flyTrack.IsPlaying then flyTrack:Stop(0.3) end
            if not flyIdle.IsPlaying then flyIdle:Play(0.3) end
            if flySfx then flySfx.Volume = flyLerp(flySfx.Volume, 0, 0.1) end
            if flyWindClone and flyWindOn then
                for _, v in ipairs(flyWindFx) do v.Enabled = false end
                flyWindOn = false
            end
        end

        cam.FieldOfView = flyLerp(cam.FieldOfView, flyFov0 + FlyCfg.FlyFov * (flyBV.Velocity.Magnitude / 400), 0.08)
    end)
    return true
end

local function syncFlyBtn()
    FlyBtn.setActive(flyActive, flyActive and "FLYING" or "OFF")
end

LocalPlayer.CharacterRemoving:Connect(function()
    stopFly()
    syncFlyBtn()
end)

LocalPlayer.CharacterAdded:Connect(function(ch)
    if flyWant then
        ch:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.5)
        if flyWant then startFly() end
    end
    syncFlyBtn()
end)

FlyBtn.onClick(function()
    flyWant = not flyActive
    if flyWant then
        if not startFly() then flyWant = false end
    else
        stopFly()
    end
    syncFlyBtn()
end)

makeToggle(mainS, "Fly", false, function(state)
    FlyBtn.setVisible(state)
    flyWant = state
    if state then
        if not startFly() then flyWant = false end
    else
        stopFly()
    end
    syncFlyBtn()
end)

makeSlider(mainS, "Fly Speed", 10, 500, 180, function(v) FlyCfg.FlySpeed = v end)
makeSlider(mainS, "Fly Boost Speed", 100, 1000, 400, function(v) FlyCfg.FlyBoost = v end)
makeSlider(mainS, "Fly Slow Speed", 10, 200, 80, function(v) FlyCfg.FlySlow = v end)
makeSlider(mainS, "Fly FOV Boost", 0, 80, 35, function(v) FlyCfg.FlyFov = v end)
end

makeToggle(mainS, "Fullbright", false, function(state)
    game:GetService("Lighting").Brightness = state and 5 or 1
end)

makeSectionRow(mainS, "Prediction Lock")

-- ===== PREDICTION SETTINGS =====
local PREDICTION_FACTOR = 0.22
local LERP_ALPHA = 0.3
local targetData = {}

local lockOnActive = false
local lockedTarget = nil
local lockMethod = {}

local function doUnlockOn()
    lockOnActive = false
    lockedTarget = nil
    targetData   = {}
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end
    RunService:UnbindFromRenderStep("LockOnCam")
    setIdleTheme()
end

local function doLockOn()
    local targetInfo = getNearestTarget()
    if not targetInfo then return end
    lockedTarget = targetInfo.character
    lockOnActive = true

    setLockedTheme(lockedTarget and lockedTarget.Name)

    RunService:BindToRenderStep("LockOnCam", Enum.RenderPriority.Camera.Value + 1, function(delta)
        if not lockedTarget or not lockedTarget.Parent or
           not lockedTarget:FindFirstChild("HumanoidRootPart") or
           lockedTarget:GetAttribute("Dead") then
            doUnlockOn()
            return
        end
        local hum = lockedTarget:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then
            doUnlockOn()
            return
        end
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local tHRP = lockedTarget:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end

        -- Predict and move character
        if table.find(lockMethod, "Camera") then
            workspace.CurrentCamera.CameraType = Enum.CameraType.Track
            local camPos = workspace.CurrentCamera.CFrame.Position
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(
                CFrame.new(camPos, tHRP.Position + workspace.CurrentCamera.CFrame.RightVector * 1.75), 0.9
            ) - workspace.CurrentCamera.CFrame.Position + camPos
        end

        if table.find(lockMethod, "Character") then
            local hrp = myChar:FindFirstChild("HumanoidRootPart")
            local myHum = myChar:FindFirstChildOfClass("Humanoid")
            if hrp and myHum then
                myHum.AutoRotate = false

                local currentPos = tHRP.Position
                local data = targetData[tHRP] or {}
                local lastPos = data.lastPos
                local predictedPos = currentPos

                if lastPos and delta > 0.001 then
                    local velocity = (currentPos - lastPos) / delta
                    predictedPos = currentPos + velocity * PREDICTION_FACTOR
                end

                if data.smoothed then
                    predictedPos = data.smoothed:Lerp(predictedPos, LERP_ALPHA)
                end

                data.lastPos = currentPos
                data.smoothed = predictedPos
                targetData[tHRP] = data

                local offset = Vector3.new(
                    predictedPos.X - hrp.Position.X,
                    0,
                    predictedPos.Z - hrp.Position.Z
                )
                if offset.Magnitude > 0.001 then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + offset.Unit)
                end
            end
        end
    end)
end

LockBtn.onClick(function()
    if lockOnActive then doUnlockOn() else doLockOn() end
end)

local lockToggleRow, setLockToggle, getLockToggle = makeToggle(mainS, "Prediction Lock", false, function(state)
    LockBtn.setVisible(state)
    if state then doLockOn() else doUnlockOn() end
end)

makeSlider(mainS, "Prediction Factor", 1, 100, 22, function(v)
    PREDICTION_FACTOR = v / 100
end)

makeSlider(mainS, "Prediction Smoothing", 0, 100, 30, function(v)
    LERP_ALPHA = v / 100
end)

makeToggle(mainS, "Lock Mode: Camera", false, function(state)
    if state then table.insert(lockMethod, "Camera")
    else local i = table.find(lockMethod, "Camera"); if i then table.remove(lockMethod, i) end end
end)

makeToggle(mainS, "Lock Mode: Character", false, function(state)
    if state then table.insert(lockMethod, "Character")
    else local i = table.find(lockMethod, "Character"); if i then table.remove(lockMethod, i) end end
end)

makeSectionRow(mainS, "Hitbox")

makeSlider(mainS, "Hitbox Size", 1, 20, 4, function(v)
    _G.HitboxSize = v
end)

makeToggle(mainS, "Expand Hitbox", false, function(state)
    _G.ExpandHitbox = state
    if state then
        RunService:BindToRenderStep("HitboxExpand", 0, function()
            if not _G.ExpandHitbox then
                RunService:UnbindFromRenderStep("HitboxExpand")
                return
            end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(_G.HitboxSize or 4, _G.HitboxSize or 4, _G.HitboxSize or 4)
                    end
                end
            end
        end)
    else
        RunService:UnbindFromRenderStep("HitboxExpand")
    end
end)

-- ==========================================
-- COMBAT TAB
-- ==========================================
local combatS = scrolls["Combat"]

makeSectionRow(combatS, "Blackflash")

local bfConn = nil
makeToggle(combatS, "Yuji 100% Blackflash", true, function(state)
    if state then
        if bfConn then bfConn:Disconnect(); bfConn = nil end
        local service = RS.Knit.Knit.Services:WaitForChild("DivergentFistService")
        if service and service.RE and service.RE.Effects then
            bfConn = service.RE.Effects.OnClientEvent:Connect(function(...)
                local args = {...}
                local eventType = args[#args - 1]
                local eventChar = args[#args]
                if eventType == "CurseBuild" and eventChar == LocalPlayer.Character then
                    task.wait(0.07)
                    pcall(function()
                        service.RE.Activated:FireServer(
                            LocalPlayer.Character.Moveset:FindFirstChild("Divergent Fist")
                        )
                    end)
                end
            end)
        end
    else
        if bfConn then
            bfConn:Disconnect()
            bfConn = nil
        end
    end
end)

-- ── M1 CATCH (only fires M1s) ──
makeSectionRow(combatS, "M1 Catch")

do
    local M1C = { en = false, range = 30, last = 0, conns = {}, hooked = setmetatable({}, { __mode = "k" }), dash = {} }

    local function digits(id)
        return id and tostring(id):match("%d+") or nil
    end

    local function loadDashIds()
        table.clear(M1C.dash)
        pcall(function()
            local mv = RS.Animations.Misc.Movement
            for _, a in ipairs(mv:GetChildren()) do
                if a:IsA("Animation") and (a.Name == "DashRight" or a.Name == "DashLeft") then
                    local n = digits(a.AnimationId)
                    if n then M1C.dash[n] = true end
                end
            end
        end)
    end

    local function nearestEnemy(range)
        local me = LocalPlayer.Character
        local mh = me and me:FindFirstChild("HumanoidRootPart")
        local folder = workspace:FindFirstChild("Characters")
        if not (mh and folder) then return nil end
        local best, bd = nil, range * range
        for _, c in ipairs(folder:GetChildren()) do
            if c ~= me then
                local h = c:FindFirstChild("HumanoidRootPart")
                if h then
                    local d = h.Position - mh.Position
                    local dsq = d:Dot(d)
                    if dsq <= bd then best, bd = c, dsq end
                end
            end
        end
        return best
    end

    -- fires ONLY an M1, nothing else (no block release, no other moves)
    local function fireM1()
        local me = LocalPlayer.Character
        local mvset = me and me:GetAttribute("Moveset")
        if not mvset then return end
        pcall(function()
            RS.Knit.Knit.Services[mvset .. "Service"].RE.Activated:FireServer(false)
        end)
    end

    local function onEnemyDash(char)
        if not M1C.en then return end
        if nearestEnemy(M1C.range) ~= char then return end
        local now = os.clock()
        if now - M1C.last < 0.3 then return end
        M1C.last = now
        fireM1()
    end

    local function hookChar(char)
        if char == LocalPlayer.Character or M1C.hooked[char] then return end
        M1C.hooked[char] = true
        task.spawn(function()
            local hum = char:WaitForChild("Humanoid", 5)
            local an = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5))
            if not an or not M1C.en then M1C.hooked[char] = nil return end
            table.insert(M1C.conns, an.AnimationPlayed:Connect(function(track)
                local a = track.Animation
                local n = a and digits(a.AnimationId)
                if n and M1C.dash[n] then onEnemyDash(char) end
            end))
        end)
    end

    local function stopM1Catch()
        M1C.en = false
        for _, c in ipairs(M1C.conns) do pcall(function() c:Disconnect() end) end
        table.clear(M1C.conns)
        table.clear(M1C.hooked)
    end

    local function startM1Catch()
        stopM1Catch()
        M1C.en = true
        loadDashIds()
        local folder = workspace:FindFirstChild("Characters")
        if not folder then return end
        for _, c in ipairs(folder:GetChildren()) do hookChar(c) end
        table.insert(M1C.conns, folder.ChildAdded:Connect(hookChar))
    end

    makeToggle(combatS, "M1 Catch", false, function(state)
        if state then startM1Catch() else stopM1Catch() end
    end)
    makeSlider(combatS, "M1 Catch Range (studs)", 5, 100, 30, function(v) M1C.range = v end)
end

-- ── RESPAWN SECTION ──
makeSectionRow(combatS, "Hiromi")

-- helper: fire every connection of a GUI button (works for mobile taps)
local function pressGuiButton(btn)
    if not btn then return end
    for _, sig in ipairs({ "MouseButton1Down", "Activated", "MouseButton1Click", "MouseButton1Up" }) do
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(btn[sig])) do
                    pcall(function() c:Fire() end)
                end
            end
        end)
    end
end

-- Auto QTE
local qteDelay = 0   -- slider value, each step = 0.01s between presses
local qteLast  = 0

makeToggle(combatS, "Auto Hiromi QTE", false, function(state)
    RunService:UnbindFromRenderStep("KZM-Hiromi-QTE")
    if not state then return end
    RunService:BindToRenderStep("KZM-Hiromi-QTE", 0, function()
        if tick() - qteLast < qteDelay * 0.01 then return end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local qte = pg and pg:FindFirstChild("QTE")
        if not qte then return end
        qteLast = tick()
        if UserInputService.TouchEnabled then
            pressGuiButton(qte:FindFirstChild("QTE_MOBILE"))
        else
            local pcLbl = qte:FindFirstChild("QTE_PC")
            local ok, key = pcall(function() return Enum.KeyCode[pcLbl.Text] end)
            if ok and key then
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end
    end)
end)

makeSlider(combatS, "QTE Delay (x0.01s)", 0, 50, 0, function(v)
    qteDelay = v
end)

-- Domain Guess (Confess / Denial / Silence picker)
local domainGuessMode = "Most Used"
local domainGuessConn = nil
local domainLastPick  = nil

local function findChooseButton(chooseGui, word)
    word = string.lower(word)
    for _, d in ipairs(chooseGui:GetDescendants()) do
        if d:IsA("GuiButton") then
            local n = string.lower(d.Name)
            local t = d:IsA("TextButton") and string.lower(d.Text) or ""
            if string.find(n, word, 1, true) or string.find(t, word, 1, true) then
                return d
            end
        end
    end
    -- some UIs name a Frame and put the button inside it
    for _, d in ipairs(chooseGui:GetDescendants()) do
        if string.find(string.lower(d.Name), word, 1, true) then
            local b = d:IsA("GuiButton") and d or d:FindFirstChildWhichIsA("GuiButton", true)
            if b then return b end
        end
    end
end

makeDropdown(combatS, "Domain Guess Mode", { "Most Used", "Least Used" }, "Most Used", function(v)
    domainGuessMode = v
end)

makeToggle(combatS, "Domain Guess", false, function(state)
    if domainGuessConn then domainGuessConn:Disconnect(); domainGuessConn = nil end
    domainLastPick = nil
    if not state then return end
    domainGuessConn = RunService.Heartbeat:Connect(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local choose = pg and pg:FindFirstChild("Choose")
        if not choose then domainLastPick = nil return end
        local timer = choose:FindFirstChild("Timer")
        if not timer or timer.Text ~= "1" then domainLastPick = nil return end
        if domainLastPick then return end

        local domains = workspace:FindFirstChild("Domains")
        local domain = domains and domains:FindFirstChild("Domain")
        if not domain or domain:GetAttribute("UI2") == true then return end

        local counts = {
            Confess = domain:GetAttribute("ConfessCount") or 0,
            Denial  = domain:GetAttribute("DenialCount")  or 0,
            Silence = domain:GetAttribute("SilenceCount") or 0,
        }
        local pick, pickVal
        for name, n in pairs(counts) do
            if n >= 1 then
                if pickVal == nil
                   or (domainGuessMode == "Most Used" and n > pickVal)
                   or (domainGuessMode == "Least Used" and n < pickVal) then
                    pick, pickVal = name, n
                end
            end
        end
        if not pick then return end

        local btn = findChooseButton(choose, pick) or (pick == "Denial" and findChooseButton(choose, "deny"))
        if btn then
            domainLastPick = pick
            pressGuiButton(btn)
            UI.notify("Domain Guess", "Picked " .. pick .. " (" .. pickVal .. ")", C.accent, 2)
        end
    end)
end)

makeSectionRow(combatS, "Respawn")

-- Force Reset: now silent (no notification)
makeButton(combatS, "Force Reset", function()
    instantRespawnNow()
end)

-- 1HP button (one‑shot kill)
makeButton(combatS, "1HP", function()
    pcall(function()
        replicatesignal(game.Players.LocalPlayer.Kill)
    end)
end, C.red)

-- ==========================================
-- TARGET TAB (TBO-style TP system, no emojis)
-- ==========================================
local targetTab = scrolls["Target"]

-- Shared functions
local function resetChar()
    workspace.FallenPartsDestroyHeight = -150
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

local function isAlive(player)
    if not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function getSortedPlayers()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local alive, dead = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if isAlive(p) then table.insert(alive, p)
            else table.insert(dead, p) end
        end
    end
    if hrp then
        table.sort(alive, function(a, b)
            local aH = a.Character and a.Character:FindFirstChild("HumanoidRootPart")
            local bH = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
            if not aH then return false end
            if not bH then return true end
            return (hrp.Position - aH.Position).Magnitude < (hrp.Position - bH.Position).Magnitude
        end)
    end
    return alive, dead
end

-- TP Bypass
local bodyVelocity, bodyGyro, antistuffConn = nil, nil, nil
local tpBypassOn = false

local function antistuff()
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    if antistuffConn then antistuffConn:Disconnect() end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(9e9, 0, 9e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.P = 0
    bodyGyro.D = 50
    bodyGyro.Parent = hrp
    antistuffConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and bodyVelocity then
            local md = hum.MoveDirection
            bodyVelocity.Velocity = md.Magnitude > 0
                and Vector3.new(md.X, 0, md.Z) * 22
                or Vector3.new(0, 0, 0)
        end
    end)
end

local function unantistuff()
    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    if antistuffConn then antistuffConn:Disconnect(); antistuffConn = nil end
end

makeToggle(targetTab, "TP Bypass", false, function(state)
    tpBypassOn = state
    if state then antistuff() else unantistuff() end
end)

-- ── Player Selection Panel ──
local panelOpen = false
local selectedPlayer = nil
local playerPanel = Instance.new("Frame")
playerPanel.Size = UDim2.new(0, 190, 0, 280)
playerPanel.Position = UDim2.new(0.5, 70, 0.5, -140)
playerPanel.BackgroundColor3 = C.bg
playerPanel.BorderSizePixel = 0
playerPanel.Visible = false
playerPanel.ZIndex = 300
playerPanel.Parent = screenGui
makeCorner(playerPanel, 14)
makeStroke(playerPanel, C.accent, 1.5, 0.3)

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.new(1, -36, 0, 36)
panelTitle.Position = UDim2.new(0, 5, 0, 0)
panelTitle.BackgroundColor3 = C.panel
panelTitle.BorderSizePixel = 0
panelTitle.Text = "Pick Player"
panelTitle.TextColor3 = C.accentHi
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 13
panelTitle.ZIndex = 301
panelTitle.Parent = playerPanel
makeCorner(panelTitle, 14)

local panelClose = Instance.new("TextButton")
panelClose.Size = UDim2.new(0, 30, 0, 30)
panelClose.Position = UDim2.new(1, -34, 0, 3)
panelClose.BackgroundColor3 = C.redLo
panelClose.Text = "X"
panelClose.TextColor3 = C.white
panelClose.Font = Enum.Font.GothamBold
panelClose.TextSize = 13
panelClose.BorderSizePixel = 0
panelClose.ZIndex = 302
panelClose.Parent = playerPanel
makeCorner(panelClose, 8)

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, -10, 1, -44)
playerScroll.Position = UDim2.new(0, 5, 0, 40)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 3
playerScroll.ScrollBarImageColor3 = C.accent
playerScroll.ZIndex = 301
playerScroll.Parent = playerPanel

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.SortOrder = Enum.SortOrder.Name
playerListLayout.Padding = UDim.new(0, 4)
playerListLayout.Parent = playerScroll

local function updatePlayerList()
    for _, c in ipairs(playerScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local alive, dead = getSortedPlayers()
    local all = {}
    for _, p in ipairs(alive) do table.insert(all, {p, true}) end
    for _, p in ipairs(dead) do table.insert(all, {p, false}) end
    for _, data in ipairs(all) do
        local p = data[1]
        local aliveFlag = data[2]
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = C.row
        btn.BorderSizePixel = 0
        btn.Text = (aliveFlag and "[A] " or "[D] ") .. p.Name
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = aliveFlag and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        btn.ZIndex = 302
        btn.Parent = playerScroll
        makeCorner(btn, 8)
        btn.MouseButton1Click:Connect(function()
            selectedPlayer = p
            panelOpen = false
            playerPanel.Visible = false
            setTargetStatus("Selected: " .. p.Name, Color3.fromRGB(200, 180, 80))
        end)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.rowHover}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.row}):Play()
        end)
    end
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, #all * 42)
end

panelClose.MouseButton1Click:Connect(function()
    panelOpen = false
    playerPanel.Visible = false
end)

-- ── TP functions ──
local function setTeleportStatus(msg, color)
    local statusRow = targetTab:FindFirstChild("StatusRow")
    if statusRow then
        local lbl = statusRow:FindFirstChild("StatusLabel")
        if lbl then
            lbl.Text = msg
            lbl.TextColor3 = color or C.textDim
        end
    end
end

local function teleportTo(targetHRP, targetHum)
    if not targetHRP then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local predicted = targetHRP.Position
    if targetHum and targetHum.MoveDirection then
        predicted = predicted + (targetHum.MoveDirection * 0.8 * targetHum.WalkSpeed)
    end
    local dest = CFrame.new(predicted.X, predicted.Y - 4.5, predicted.Z) * CFrame.Angles(math.rad(90), 0, 0)
    if tpBypassOn then unantistuff() end
    hrp.CFrame = dest
    hrp.AssemblyLinearVelocity = Vector3.zero
    if tpBypassOn then antistuff() end
end

-- Closest living player by real distance to me (not camera direction)
local function getClosestPlayer()
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and not p.Character:GetAttribute("Dead") then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = { character = p.Character, root = hrp, humanoid = hum, player = p, distance = d }
                end
            end
        end
    end
    return best
end

-- TP Nearest (button)
makeButton(targetTab, "TP Nearest", function()
    local targetInfo = getClosestPlayer()
    if not targetInfo then
        setTeleportStatus("No players found", Color3.fromRGB(255, 100, 100))
        return
    end
    teleportTo(targetInfo.root, targetInfo.humanoid)
    setTeleportStatus(string.format("TP to closest: %s (%d studs)", targetInfo.player.Name, math.floor(targetInfo.distance)), Color3.fromRGB(100, 255, 100))
end)

-- ==========================================
-- ORBIT (TP Loop / Smooth Spin) + floating button
-- Wrapped in do...end so it adds no top-level locals.
-- ==========================================
do
    makeSectionRow(targetTab, "Orbit")

    local orbitRange, orbitSpeed, orbitStyle = 6, 180, "TP Loop"
    local orbitConn, orbitDeathConn, orbitTarget, orbitAngle = nil, nil, nil, 0
    local orbitCamProxy, orbitCamSubject, orbitMyHum = nil, nil, nil
    local OrbitBtn = nil

    local function charParts(ch)
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        local r = ch and ch:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health > 0 then return h, r end
    end

    -- Same priority as everything else: current lock-on target, then the
    -- player nearest your crosshair, then simply the closest player.
    local function pickOrbitTarget()
        if lockOnActive and lockedTarget and charParts(lockedTarget) then return lockedTarget end
        local info = getNearestTarget()
        if info and info.character then return info.character end
        local c = getClosestPlayer()
        if c then return c.character end
    end

    local function stopOrbit()
        if orbitConn then orbitConn:Disconnect(); orbitConn = nil end
        if orbitDeathConn then orbitDeathConn:Disconnect(); orbitDeathConn = nil end
        if orbitMyHum and orbitMyHum.Parent then orbitMyHum.AutoRotate = true end
        orbitMyHum = nil
        local cam = workspace.CurrentCamera
        if orbitCamProxy then
            if cam then
                cam.CameraType = Enum.CameraType.Custom
                if orbitCamSubject and orbitCamSubject.Parent then cam.CameraSubject = orbitCamSubject end
            end
            pcall(function() orbitCamProxy:Destroy() end)
            orbitCamProxy = nil
        end
        orbitCamSubject = nil
        orbitTarget = nil
        if OrbitBtn then OrbitBtn.setActive(false, "IDLE") end
    end

    local function startOrbit()
        if orbitConn then return true end
        local tgt = pickOrbitTarget()
        if not tgt then
            UI.notify("Orbit", "No target found", C.red, 2)
            return false
        end
        local myHum, myHRP = charParts(LocalPlayer.Character)
        local _, tHRP = charParts(tgt)
        if not (myHum and myHRP and tHRP) then return false end

        orbitTarget = tgt
        orbitMyHum  = myHum
        orbitDeathConn = myHum.Died:Connect(stopOrbit)

        local cam = workspace.CurrentCamera
        if orbitStyle == "TP Loop" then
            -- invisible, smoothed camera subject so the random teleports don't shake the camera
            orbitCamSubject = cam and cam.CameraSubject
            local proxy = Instance.new("Part")
            proxy.Name = "KZM_OrbitCamProxy"
            proxy.Size = Vector3.new(1, 1, 1)
            proxy.Transparency = 1
            proxy.Anchored = true
            proxy.CanCollide = false
            proxy.CanTouch = false
            proxy.CanQuery = false
            proxy.CastShadow = false
            proxy.CFrame = CFrame.new(myHRP.Position)
            proxy.Parent = workspace
            orbitCamProxy = proxy
            if cam then
                cam.CameraType = Enum.CameraType.Custom
                cam.CameraSubject = proxy
            end
        else
            myHum.AutoRotate = false
            local p, t = myHRP.Position, tHRP.Position
            orbitAngle = math.atan2(p.Z - t.Z, p.X - t.X)
        end

        orbitConn = RunService.Heartbeat:Connect(function(dt)
            local mh, mr = charParts(LocalPlayer.Character)
            local _, tr = charParts(orbitTarget)
            if not tr then
                UI.notify("Orbit", "Target is gone", C.accent, 2)
                stopOrbit()
                return
            end
            if not mr then return end
            local t = tr.Position
            if orbitStyle == "TP Loop" then
                local a = math.random() * math.pi * 2
                mr.AssemblyLinearVelocity = Vector3.zero
                mr.CFrame = CFrame.new(Vector3.new(t.X + math.cos(a) * orbitRange, t.Y, t.Z + math.sin(a) * orbitRange), t)
                if orbitCamProxy then
                    local alpha = 1 - math.pow(1 - 0.06, math.clamp(dt * 60, 0, 3))
                    orbitCamProxy.Position = orbitCamProxy.Position:Lerp(mr.Position, alpha)
                end
            else
                orbitAngle += math.rad(orbitSpeed) * dt
                mr.AssemblyLinearVelocity = Vector3.zero
                mr.CFrame = CFrame.new(Vector3.new(t.X + math.cos(orbitAngle) * orbitRange, t.Y, t.Z + math.sin(orbitAngle) * orbitRange), t)
            end
        end)
        return true
    end

    -- icon: ring with a satellite dot (the holder spins while active)
    local function orbitIcon(parent)
        local parts, strokes = {}, {}
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.new(0.5, 0, 0.5, 0)
        ring.Size = UDim2.new(0, 40, 0, 40)
        ring.BackgroundTransparency = 1
        ring.ZIndex = 204
        ring.Parent = parent
        makeCorner(ring, 100)
        table.insert(strokes, makeStroke(ring, C.accentHi, 2, 0.15))
        local function dotAt(ox, oy, size)
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.new(0.5, ox, 0.5, oy)
            f.Size = UDim2.new(0, size, 0, size)
            f.BackgroundColor3 = C.accentHi
            f.BorderSizePixel = 0
            f.ZIndex = 205
            f.Parent = parent
            makeCorner(f, 100)
            table.insert(parts, f)
        end
        dotAt(0, 0, 9)      -- target
        dotAt(0, -20, 8)    -- satellite on the ring
        return parts, strokes
    end

    local TEAL = Color3.fromRGB(0, 230, 200)
    OrbitBtn = createFloatingButton({
        name = "OrbitBtn", lockKey = "orbit", title = "ORBIT", idleText = "IDLE", activeText = "ON",
        accent = TEAL, bgActive = Color3.fromRGB(4, 26, 24),
        startFrac = { 0.82, 0.64 }, icon = orbitIcon, activeAnim = "spin",
    })

    OrbitBtn.onClick(function()
        if orbitConn then
            stopOrbit()
        elseif startOrbit() then
            local nm = orbitTarget and orbitTarget.Name or "ON"
            OrbitBtn.setActive(true, nm)
        end
    end)

    makeToggle(targetTab, "Orbit Button", false, function(state)
        OrbitBtn.setVisible(state)
        if not state then stopOrbit() end
    end)

    makeDropdown(targetTab, "Orbit Style", { "TP Loop", "Smooth Spin" }, "TP Loop", function(v)
        orbitStyle = v
        if orbitConn then
            -- restart so the new style takes effect on the same target
            stopOrbit()
            if startOrbit() then
                OrbitBtn.setActive(true, orbitTarget and orbitTarget.Name or "ON")
            end
        end
    end)

    makeSlider(targetTab, "Orbit Range (studs)", 2, 30, 6, function(v) orbitRange = v end)
    makeSlider(targetTab, "Orbit Speed (Spin)", 30, 720, 180, function(v) orbitSpeed = v end)

    LocalPlayer.CharacterAdded:Connect(function() stopOrbit() end)
end


-- TP Selected
local tpSelOn = false
local tpSelConn = nil

local function stopSelLoop()
    tpSelOn = false
    if tpSelConn then tpSelConn:Disconnect(); tpSelConn = nil end
    setTPSelToggle(false)
    selectedPlayer = nil
    resetChar()
    setTeleportStatus("TP Selected OFF", Color3.fromRGB(150, 150, 150))
end

local function toggleTPSelected(state)
    if state then
        if not selectedPlayer then
            panelOpen = true
            playerPanel.Visible = true
            updatePlayerList()
            setTeleportStatus("Pick a player first", Color3.fromRGB(255, 200, 100))
            setTPSelToggle(false)
            return
        end
        tpSelOn = true
        setTeleportStatus("TP -> " .. selectedPlayer.Name, Color3.fromRGB(255, 180, 80))
        if tpSelConn then tpSelConn:Disconnect(); tpSelConn = nil end
        tpSelConn = RunService.Heartbeat:Connect(function()
            if not tpSelOn then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local tChar = selectedPlayer and selectedPlayer.Character
            if not tChar then return end
            local tHRP = tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar:FindFirstChildOfClass("Humanoid")
            if not tHRP or not tHum then return end
            teleportTo(tHRP, tHum)
        end)
    else
        stopSelLoop()
    end
end

local tpSelRow, setTPSelToggle, getTPSelToggle = makeToggle(targetTab, "TP Selected", false, toggleTPSelected)

-- TP All Loop (instant, random alive, stops when no alive)
local tpLoopOn = false
local tpLoopConn = nil
local aliveCache = {}
local refreshTimer = 0

local function stopLoop()
    tpLoopOn = false
    if tpLoopConn then tpLoopConn:Disconnect(); tpLoopConn = nil end
    setTPLoopToggle(false)
    resetChar()
    setTeleportStatus("TP Loop OFF", Color3.fromRGB(150, 150, 150))
end

local function toggleTPLoop(state)
    if state then
        tpLoopOn = true
        aliveCache = {}
        refreshTimer = 0
        setTeleportStatus("TP Loop ON", Color3.fromRGB(255, 80, 80))
        if tpLoopConn then tpLoopConn:Disconnect(); tpLoopConn = nil end
        tpLoopConn = RunService.Heartbeat:Connect(function(dt)
            if not tpLoopOn then return end

            refreshTimer = refreshTimer + dt
            if refreshTimer >= 0.5 then
                refreshTimer = 0
                aliveCache = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and isAlive(p) then
                        table.insert(aliveCache, p)
                    end
                end
            end

            if #aliveCache == 0 then
                setTeleportStatus("No alive targets", Color3.fromRGB(255, 200, 100))
                return
            end

            local target = aliveCache[math.random(1, #aliveCache)]
            if target then
                local tChar = target.Character
                if tChar then
                    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
                    local tHum = tChar:FindFirstChildOfClass("Humanoid")
                    if tHRP and tHum then
                        teleportTo(tHRP, tHum)
                        setTeleportStatus("TP " .. target.Name, Color3.fromRGB(255, 180, 100))
                    end
                end
            end
        end)
    else
        stopLoop()
    end
end

local tpLoopRow, setTPLoopToggle, getTPLoopToggle = makeToggle(targetTab, "TP All Loop", false, toggleTPLoop)

-- Status label
local statusRowTp = Instance.new("Frame")
statusRowTp.Name = "StatusRow"
statusRowTp.Size = UDim2.new(1, -4, 0, 20)
statusRowTp.BackgroundColor3 = C.row
statusRowTp.BorderSizePixel = 0
statusRowTp.ZIndex = 100
statusRowTp.Parent = targetTab
makeCorner(statusRowTp, 5)
makeStroke(statusRowTp, C.stroke, 1, 0.5)
local statusLblTp = Instance.new("TextLabel")
statusLblTp.Name = "StatusLabel"
statusLblTp.Size = UDim2.new(1, 0, 1, 0)
statusLblTp.BackgroundTransparency = 1
statusLblTp.Text = "Ready"
statusLblTp.TextColor3 = C.textDim
statusLblTp.Font = Enum.Font.Gotham
statusLblTp.TextSize = 10
statusLblTp.TextXAlignment = Enum.TextXAlignment.Center
statusLblTp.ZIndex = 101
statusLblTp.Parent = statusRowTp

-- Select Target button
makeButton(targetTab, "Select Target", function()
    panelOpen = not panelOpen
    playerPanel.Visible = panelOpen
    if panelOpen then updatePlayerList() end
end)

-- ── SPECTATE FEATURE ──
makeSectionRow(targetTab, "Spectate")

local spectatePlayer = nil
local spectateActive = false
local spectateConnection = nil
local playerNames = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then table.insert(playerNames, p.Name) end
end
local spectateDropdown, updateSpectateDropdown, getSpectatePlayer = makeDropdown(targetTab, "Spectate Target", playerNames, playerNames[1], function(value)
    spectatePlayer = Players:FindFirstChild(value)
end)
local spectateToggleRow, setSpectateToggle, getSpectateToggle = makeToggle(targetTab, "Spectate", false, function(state)
    spectateActive = state
    if state then
        if not spectatePlayer then
            Notify({Title="Spectate", Description="No player selected", Duration=2})
            spectateActive = false
            setSpectateToggle(false)
            return
        end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        local char = spectatePlayer.Character
        if char then
            workspace.CurrentCamera.CameraSubject = char
        else
            Notify({Title="Spectate", Description="Target character not found", Duration=2})
            spectateActive = false
            setSpectateToggle(false)
            return
        end
        if spectateConnection then spectateConnection:Disconnect() end
        spectateConnection = RunService.RenderStepped:Connect(function()
            if not spectateActive then
                spectateConnection:Disconnect()
                spectateConnection = nil
                workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                workspace.CurrentCamera.CameraSubject = LocalPlayer.Character or workspace
                return
            end
            local char = spectatePlayer and spectatePlayer.Character
            if char then
                workspace.CurrentCamera.CameraSubject = char
            end
        end)
    else
        if spectateConnection then
            spectateConnection:Disconnect()
            spectateConnection = nil
        end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character or workspace
        spectatePlayer = nil
    end
end)

-- ==========================================
-- AUTO TAB (unchanged)
-- ==========================================
local autoS = scrolls["Auto"]

makeSectionRow(autoS, "M1 Assist")

local M1Method = "UpperCut"
local autoM1Active = false
local autoM1Hook   = nil
local autoM1Connections = {}
local comboCount = 0
local lastHitTime = 0

local function startM1Assist()
    if autoM1Active then return end
    autoM1Active = true
    comboCount = 0
    lastHitTime = 0

    if not autoM1Hook then
        autoM1Hook = hookmetamethod(game, "__namecall", function(self, ...)
            local m = getnamecallmethod()
            local a = {...}
            if autoM1Active and m == "FireServer" and self.Name == "Activated" then
                if a[1] == false then
                    a[1] = (M1Method == "UpperCut") and "Up" or "Down"
                end
                return autoM1Hook(self, unpack(a))
            end
            return autoM1Hook(self, ...)
        end)
    end

    local function onSwing2(...)
        local args = {...}
        if args[1] == "Swing2" and args[2] == LocalPlayer.Character and args[3] == 3 then
            local now = tick()
            if now - lastHitTime > 2 then comboCount = 0 end
            lastHitTime = now
            comboCount = comboCount + 1
            if comboCount >= 4 then
                comboCount = 0
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum:Move(Vector3.new(0,0,0), false) end
                end
            end
        end
    end

    for _, service in ipairs(RS.Knit.Knit.Services:GetChildren()) do
        if service:FindFirstChild("RE") and service.RE:FindFirstChild("Effects") then
            local conn = service.RE.Effects.OnClientEvent:Connect(onSwing2)
            table.insert(autoM1Connections, conn)
        end
    end
end

local function stopM1Assist()
    autoM1Active = false
    for _, conn in ipairs(autoM1Connections) do
        pcall(conn.Disconnect, conn)
    end
    table.clear(autoM1Connections)
    comboCount = 0
end

local m1MethodItems = {"UpperCut", "DownSlam"}
local m1Dropdown, updateM1Dropdown, getM1Method = makeDropdown(autoS, "M1 Method", m1MethodItems, "UpperCut", function(value)
    M1Method = value
    if autoM1Active then
        stopM1Assist()
        startM1Assist()
    end
end)

makeToggle(autoS, "M1 Assist", true, function(state)
    if state then startM1Assist() else stopM1Assist() end
end)

makeSectionRow(autoS, "Auto Burst")

local autoBurstActive = false
local autoBurstRenderStep = nil

local function startAutoBurst()
    if autoBurstActive then return end
    autoBurstActive = true
    autoBurstRenderStep = RunService:BindToRenderStep("Auto-Burst", 0, function()
        if not autoBurstActive then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local burstFound = false
        for _, child in ipairs(hrp:GetChildren()) do
            if child.Name == "BurstIcon" or child.Name == "Evade" then
                burstFound = true
                break
            end
        end
        if not burstFound then return end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            local dir = "Left"
            if math.abs(moveDir.X) > math.abs(moveDir.Z) then
                dir = moveDir.X > 0 and "Right" or "Left"
            else
                dir = moveDir.Z < 0 and "Back" or "Left"
            end
            local movementService = RS.Knit.Knit.Services.MovementService
            if movementService and movementService.RE and movementService.RE.Dash then
                pcall(function()
                    movementService.RE.Dash:FireServer(dir, true)
                end)
            end
        end
    end)
end

local function stopAutoBurst()
    autoBurstActive = false
    if autoBurstRenderStep then
        RunService:UnbindFromRenderStep("Auto-Burst")
        autoBurstRenderStep = nil
    end
end

makeToggle(autoS, "Auto Burst", true, function(state)
    if state then startAutoBurst() else stopAutoBurst() end
end)

-- ── BLACK FLASH CHAIN ──
makeSectionRow(autoS, "Black Flash Chain")

do
    local DebrisSvc = game:GetService("Debris")
    local BFC = { en = false, active = false, rtok = 0, animlast = 0, conns = {} }
    local Cfg = { range = 30, radius = 5, duration = 0.4, noStick = false }
    local IDS = {
        ["100962226150441"] = true, ["95852624447551"] = true,
        ["74145636023952"] = true,  ["123171106092050"] = true,
    }
    local DIRS = {
        Back = Vector3.new(0, 0, 1), Front = Vector3.new(0, 0, -1),
        Left = Vector3.new(-1, 0, 0), Right = Vector3.new(1, 0, 0),
    }

    local function isBfId(id)
        local n = id and tostring(id):match("%d+")
        return n ~= nil and IDS[n] == true
    end
    local function hrpOf(c) return c and c:FindFirstChild("HumanoidRootPart") end
    local function flat(v) return Vector3.new(v.X, 0, v.Z) end

    local function svcRemote(svc, name)
        local s = RS.Knit.Knit.Services:FindFirstChild(svc)
        local re = s and s:FindFirstChild("RE")
        return re and re:FindFirstChild(name)
    end

    local function fireBlackFlash()
        local ch = LocalPlayer.Character
        local ms = ch and ch:FindFirstChild("Moveset")
        local tool = ms and ms:FindFirstChild("Divergent Fist")
        local re = svcRemote("DivergentFistService", "Activated")
        if tool and re then re:FireServer(tool, nil) end
    end

    local function closest(maxd)
        local ch = LocalPlayer.Character
        local hrp = hrpOf(ch)
        local folder = workspace:FindFirstChild("Characters")
        if not (hrp and folder) then return nil end
        local best, bd = nil, maxd * maxd
        for _, c in ipairs(folder:GetChildren()) do
            if c ~= ch then
                local hum = c:FindFirstChildOfClass("Humanoid")
                local h = hrpOf(c)
                if hum and hum.Health > 0 and h then
                    local d = hrp.Position - h.Position
                    local dsq = d:Dot(d)
                    if dsq < bd then bd, best = dsq, c end
                end
            end
        end
        return best
    end

    local movectrl
    pcall(function()
        local m = require(LocalPlayer.PlayerScripts.Controllers.Character.MovementController)
        if type(m) == "table" and m.Dash then movectrl = m end
    end)

    local function dashForce(ch, dir)
        local torso = ch:FindFirstChild("Torso")
        local hrp = hrpOf(ch)
        if not (torso and hrp) then return end
        for _, i in ipairs(torso:GetChildren()) do
            if i.Name == "MovementForce" then pcall(i.Destroy, i) end
        end
        local info = ch:FindFirstChild("Info")
        local dm = info and info:FindFirstChild("DashMultiplier")
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(40000, 0, 40000)
        bv.P = 400000
        bv.Name = "MovementForce"
        bv.Velocity = hrp.CFrame:VectorToWorldSpace(DIRS[dir] or DIRS.Right) * (200 * (dm and dm.Value or 1))
        bv.Parent = torso
        DebrisSvc:AddItem(bv, 0.4)
    end

    local function doDash(ch, dir)
        if movectrl and pcall(movectrl.Dash, movectrl, LocalPlayer, ch, dir) then return end
        dashForce(ch, dir)
    end

    local function backPos(tgt)
        local thrp = hrpOf(tgt)
        if not thrp then return nil end
        local l = flat(thrp.CFrame.LookVector)
        if l.Magnitude < 0.01 then return nil end
        l = l.Unit
        return thrp.Position - l * Cfg.radius, l
    end

    local function getDir(tgt)
        local hrp, thrp = hrpOf(LocalPlayer.Character), hrpOf(tgt)
        if not (hrp and thrp) then return "Right" end
        local back = backPos(tgt)
        if not back then return "Right" end
        local toback = flat(back - hrp.Position)
        local rv = flat(hrp.CFrame.RightVector)
        if toback.Magnitude < 0.01 or rv.Magnitude < 0.01 then return "Right" end
        return toback.Unit:Dot(rv.Unit) >= 0 and "Right" or "Left"
    end

    local function calcDM(tgt)
        local hrp, thrp = hrpOf(LocalPlayer.Character), hrpOf(tgt)
        if not (hrp and thrp) then return 1 end
        local _, l = backPos(tgt)
        if not l then return 1 end
        local tr = Cfg.radius
        local d = flat(hrp.Position - thrp.Position)
        local sr = math.max(d.Magnitude, 0.01)
        local sa = math.atan2(d.X, d.Z)
        local ta = math.atan2(-l.X, -l.Z)
        local da = (ta - sa + math.pi) % (2 * math.pi) - math.pi
        local arc = math.abs(da) * (sr + tr) * 0.5
        local rad = math.abs(sr - tr)
        local total = math.sqrt(arc * arc + rad * rad)
        return math.clamp(total / 20 * 1.15, 0.15, 1.5)
    end

    local function setDM(ch, mult)
        local info = ch:FindFirstChild("Info")
        if not info then return end
        local dm = info:FindFirstChild("DashMultiplier")
        local had, old = dm ~= nil, dm and dm.Value or nil
        if not dm then
            dm = Instance.new("NumberValue")
            dm.Name = "DashMultiplier"
            dm.Parent = info
        end
        dm.Value = mult
        task.delay(0.42, function()
            if not dm.Parent then return end
            if had then dm.Value = old or 1 else pcall(dm.Destroy, dm) end
        end)
    end

    -- arc around the target to their back
    local function redirect(tgt)
        BFC.rtok += 1
        local tok = BFC.rtok
        task.spawn(function()
            local ch = LocalPlayer.Character
            local torso = ch and ch:FindFirstChild("Torso")
            local hrp, thrp = hrpOf(ch), hrpOf(tgt)
            if not (torso and hrp and thrp) then return end
            local bv, w = nil, 0
            repeat
                bv = torso:FindFirstChild("MovementForce")
                if bv then break end
                w += task.wait()
            until w >= 0.08
            if not (bv and bv:IsA("BodyVelocity")) or BFC.rtok ~= tok then return end

            local tr, totalT = Cfg.radius, Cfg.duration
            local ogmf = bv.MaxForce
            bv.MaxForce = Vector3.new(math.huge, ogmf.Y, math.huge)
            local nv = bv:FindFirstChildWhichIsA("NumberValue")
            if nv then pcall(nv.Destroy, nv) end
            bv.Velocity = Vector3.zero

            local d0 = flat(hrp.Position - thrp.Position)
            local sr = math.max(d0.Magnitude, 3)
            local sa = math.atan2(d0.X, d0.Z)
            local _, l0 = backPos(tgt)
            if not l0 then bv.MaxForce = ogmf return end
            local ta = math.atan2(-l0.X, -l0.Z)
            local da0 = (ta - sa + math.pi) % (2 * math.pi) - math.pi
            local sweep = da0 >= 0 and 1 or -1
            local arcl = math.abs(da0) * math.max(sr, tr)
            local maxspd = math.clamp(arcl / totalT * 2.5, 20, 120)
            local t0 = os.clock()
            local conn, nvconn
            nvconn = bv.ChildAdded:Connect(function(c)
                if c:IsA("NumberValue") then pcall(c.Destroy, c) end
            end)
            conn = RunService.Stepped:Connect(function()
                if BFC.rtok ~= tok or not bv.Parent or not thrp.Parent then return end
                local el = os.clock() - t0
                local t = math.clamp(el / totalT, 0, 1)
                local cda = da0
                local lc = flat(thrp.CFrame.LookVector)
                if lc.Magnitude > 0.01 then
                    lc = lc.Unit
                    local ca = math.atan2(-lc.X, -lc.Z)
                    cda = (ca - sa + math.pi) % (2 * math.pi) - math.pi
                    if cda * sweep < 0 then cda += sweep * 2 * math.pi end
                end
                local st = 1 - (1 - t) ^ 3
                local fec = thrp.Position + flat(thrp.AssemblyLinearVelocity) * (math.max(totalT - el, 0.01) * 0.4)
                local ang = sa + cda * st
                local r = math.max(sr + (tr - sr) * st, tr)
                local arcpos = Vector3.new(fec.X, hrp.Position.Y, fec.Z) + Vector3.new(math.sin(ang), 0, math.cos(ang)) * r
                local toarc = arcpos - hrp.Position
                local dist = toarc.Magnitude
                if dist < 0.2 and st > 0.9 then bv.Velocity = Vector3.zero return end
                if dist < 0.01 then return end
                local vel = toarc * 20
                bv.Velocity = vel.Unit * math.min(vel.Magnitude, maxspd)
            end)

            task.delay(totalT + 0.03, function()
                if conn then conn:Disconnect() conn = nil end
                if nvconn then nvconn:Disconnect() nvconn = nil end
                if bv and bv.Parent then bv.MaxForce = ogmf end
                if BFC.rtok ~= tok then return end
                local h2, t2 = hrpOf(LocalPlayer.Character), hrpOf(tgt)
                if not (h2 and t2) then return end
                local _, l2 = backPos(tgt)
                if not l2 then return end
                local want = t2.Position - l2 * tr
                local cd = flat(want - h2.Position)
                local m = cd.Magnitude
                if m > 0.3 and m <= 12 then
                    local cbv = Instance.new("BodyVelocity")
                    cbv.Name = "DFCorr"
                    cbv.MaxForce = Vector3.new(80000, 0, 80000)
                    cbv.P = 80000
                    cbv.Velocity = cd.Unit * math.min(m / 0.12, 150)
                    cbv.Parent = h2
                    DebrisSvc:AddItem(cbv, 0.12)
                end
                local look = flat(t2.Position - h2.Position)
                if look.Magnitude > 0.01 then
                    h2.CFrame = CFrame.new(h2.Position, h2.Position + look)
                end
            end)
        end)
    end

    local function chainDash(tgt)
        if BFC.active then return end
        local ch = LocalPlayer.Character
        if not (ch and ch:FindFirstChild("Info")) then return end
        BFC.active = true
        local dir = getDir(tgt)
        setDM(ch, calcDM(tgt))
        local dashRe = svcRemote("MovementService", "Dash")
        if dashRe then dashRe:FireServer(dir) end
        doDash(ch, dir)
        if not Cfg.noStick then redirect(tgt) end
        task.delay(0.3, function()
            fireBlackFlash()
            local h, t = hrpOf(LocalPlayer.Character), hrpOf(tgt)
            if h and t then
                local d = flat(t.Position - h.Position)
                if d.Magnitude > 0.01 then h.CFrame = CFrame.new(h.Position, h.Position + d) end
            end
            task.wait(0.15)
            BFC.active = false
        end)
    end

    local function trigger()
        if not BFC.en or BFC.active then return end
        local n = os.clock()
        if n - BFC.animlast < 0.12 then return end
        local tgt = closest(Cfg.range)
        BFC.animlast = n
        if not tgt then
            task.delay(0.3, fireBlackFlash)
            return
        end
        task.spawn(chainDash, tgt)
    end

    local function hook()
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local an = hum and hum:WaitForChild("Animator", 5)
        if not an then return end
        table.insert(BFC.conns, an.AnimationPlayed:Connect(function(tr)
            if not BFC.en or BFC.active then return end
            local a = tr.Animation
            if a and isBfId(a.AnimationId) then trigger() end
        end))
    end

    local function stopBFC()
        BFC.en, BFC.active = false, false
        BFC.rtok += 1
        for i = #BFC.conns, 1, -1 do
            pcall(function() BFC.conns[i]:Disconnect() end)
            BFC.conns[i] = nil
        end
    end

    local function startBFC()
        stopBFC()
        BFC.en = true
        task.spawn(hook)
        table.insert(BFC.conns, LocalPlayer.CharacterAdded:Connect(function()
            BFC.active = false
            task.wait(1)
            if BFC.en then hook() end
        end))
    end

    makeToggle(autoS, "Black Flash Chain", false, function(state)
        if state then startBFC() else stopBFC() end
    end)
    makeToggle(autoS, "BFC No Stick", false, function(state) Cfg.noStick = state end)
    makeSlider(autoS, "BFC Range (studs)", 5, 60, 30, function(v) Cfg.range = v end)
    makeSlider(autoS, "BFC Arc Radius (studs)", 2, 15, 5, function(v) Cfg.radius = v end)
    makeSlider(autoS, "BFC Arc Duration (x0.01s)", 15, 100, 40, function(v) Cfg.duration = v * 0.01 end)
end

-- AUTO RATIO (Nanami)
makeSectionRow(autoS, "Nanami")

local autoRatioConn = nil
local autoRatioTable = {}

makeToggle(autoS, "Auto Ratio", false, function(state)
    if state then
        if autoRatioConn then autoRatioConn:Disconnect(); autoRatioConn = nil end
        local nanamiService = game.ReplicatedStorage.Knit.Knit.Services:FindFirstChild("NanamiService")
        if nanamiService and nanamiService.RE and nanamiService.RE.Effects then
            autoRatioConn = nanamiService.RE.Effects.OnClientEvent:Connect(function(...)
                local args = {...}
                if args[1] == "SpawnRatio" and args[2] == LocalPlayer then
                    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                    local delay = args[6] * math.clamp(0.56 - (math.floor(ping) - 100) / 1000 * 0.9, 0.25, 0.85)
                    task.wait(delay)
                    if nanamiService and nanamiService.RE and nanamiService.RE.RightActivated then
                        pcall(function()
                            nanamiService.RE.RightActivated:FireServer()
                        end)
                    end
                end
            end)
            autoRatioTable.AutoRatio1 = autoRatioConn
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Auto Ratio",
                Text = "NanamiService not found!",
                Duration = 2
            })
        end
    else
        if autoRatioConn then
            autoRatioConn:Disconnect()
            autoRatioConn = nil
            autoRatioTable.AutoRatio1 = nil
        end
    end
end)

-- PERFECT SWAP (Todo)
makeSectionRow(autoS, "Todo")

local perfectSwapActive = false
local perfectSwapCharConn = nil
local perfectSwapEventConn = nil
local perfectSwapConnections = {}
local function setupPerfectSwap(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    local animConn = animator.AnimationPlayed:Connect(function(track)
        if not perfectSwapActive then return end
        if track.Animation then
            local id = track.Animation.AnimationId
            if id == "rbxassetid://91074768993486" or
               id == "rbxassetid://131358603583212" or
               id == "rbxassetid://116040503139675" then
                if not perfectSwapEventConn then
                    local todoService = RS.Knit.Knit.Services:FindFirstChild("TodoService")
                    if todoService and todoService.RE and todoService.RE.Effects then
                        perfectSwapEventConn = todoService.RE.Effects.OnClientEvent:Connect(function(...)
                            if not perfectSwapActive then return end
                            local args = {...}
                            if args[1] == "Swap" or args[1] == "Swap2" or args[1] == "Fakeout" then
                                local todoSvc = RS.Knit.Knit.Services:FindFirstChild("TodoService")
                                if todoSvc and todoSvc.RE and todoSvc.RE.Activated then
                                    pcall(function()
                                        todoSvc.RE.Activated:FireServer(false)
                                    end)
                                    if perfectSwapEventConn then
                                        perfectSwapEventConn:Disconnect()
                                        perfectSwapEventConn = nil
                                    end
                                end
                            end
                        end)
                        table.insert(perfectSwapConnections, perfectSwapEventConn)
                    end
                end
            end
        end
    end)
    table.insert(perfectSwapConnections, animConn)
end
makeToggle(autoS, "Perfect Swap", true, function(state)
    if state then
        if perfectSwapActive then return end
        perfectSwapActive = true
        perfectSwapConnections = {}
        perfectSwapEventConn = nil
        local char = LocalPlayer.Character
        if char then setupPerfectSwap(char) end
        perfectSwapCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            if perfectSwapActive then setupPerfectSwap(newChar) end
        end)
        table.insert(perfectSwapConnections, perfectSwapCharConn)
    else
        perfectSwapActive = false
        for _, conn in ipairs(perfectSwapConnections) do
            pcall(conn.Disconnect, conn)
        end
        table.clear(perfectSwapConnections)
        perfectSwapEventConn = nil
        perfectSwapCharConn = nil
    end
end)

-- AUTO GARUDA REBOUND
makeSectionRow(autoS, "Garuda")

local autoGarudaConn = nil
local autoGarudaTable = {}
makeToggle(autoS, "Auto Garuda Rebound", false, function(state)
    if state then
        if autoGarudaConn then autoGarudaConn:Disconnect(); autoGarudaConn = nil end
        local garudaService = game.ReplicatedStorage.Knit.Knit.Services:FindFirstChild("GarudaReboundService")
        if garudaService and garudaService.RE and garudaService.RE.Effects then
            autoGarudaConn = garudaService.RE.Effects.OnClientEvent:Connect(function(...)
                local args = {...}
                if args[1] == "Recall" and args[2] == LocalPlayer.Character then
                    if args[5] == 0.1 then return end
                    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                    local delay = math.max(args[5] - math.clamp(0.1 + math.floor(ping) / 1000 * 0.6, 0.12, 0.35), 0)
                    task.wait(delay)
                    if garudaService and garudaService.RE and garudaService.RE.Activated then
                        pcall(function()
                            garudaService.RE.Activated:FireServer(LocalPlayer.Character.Moveset:FindFirstChild("Garuda Rebound"))
                        end)
                    end
                end
            end)
            autoGarudaTable.AutoGarudaRebound = autoGarudaConn
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Auto Garuda Rebound",
                Text = "GarudaReboundService not found!",
                Duration = 2
            })
        end
    else
        if autoGarudaConn then
            autoGarudaConn:Disconnect()
            autoGarudaConn = nil
            autoGarudaTable.AutoGarudaRebound = nil
        end
    end
end)

-- ==========================================
-- EXTRA TAB (Emote Unlocker + Item Grabber + Misc)
-- ==========================================
local extraS = scrolls["Extra"]

makeSectionRow(extraS, "Emotes")

-- Silent emote unlocker – no notifications, no UI refreshes
local function runEmoteUnlocker()
    local gp = LocalPlayer:WaitForChild("Gamepasses")
    gp:SetAttribute("742180133", true)
    gp:SetAttribute("1151174294", true)

    pcall(function()
        local Menus = LocalPlayer.PlayerGui:WaitForChild("Menus")
        for _, obj in ipairs(Menus:GetDescendants()) do
            if obj:IsA("Frame") or obj:IsA("ImageButton") or obj:IsA("TextButton") then
                local n = tonumber(obj.Name)
                if n and n >= 5 and n <= 9 then obj.Visible = true end
                if obj.Name == "Switch" then obj.Visible = true end
            end
        end
        local ok, Equipped = pcall(function()
            return Menus:WaitForChild("Group", 3).Inventory.Items.Emotes.Equipped
        end)
        if ok and Equipped then
            for _, v in ipairs(Equipped:GetChildren()) do
                local n = tonumber(v.Name)
                if n and n >= 5 then v.Visible = true end
            end
            local sw = Equipped:FindFirstChild("Switch")
            if sw then sw.Visible = true end
        end
    end)
end

task.spawn(runEmoteUnlocker)
makeButton(extraS, "Emote Unlocker", runEmoteUnlocker)

-- Item Grabber (unchanged)
makeSectionRow(extraS, "Item Grabber")

local KNOWN_ITEMS = {
    "Soda", "Coin", "Jet Black", "Gun", "Playful Cloud", "Transfigured Flesh",
    "Voice Recorder", "Hazenoki's Eye", "Sniper", "Transfigured Human",
    "Tinted Glasses", "TNT", "Banana Peel", "Naginata", "Bowling Ball",
    "Crowbar", "Broom", "Flashlight", "Snowball", "Tiantui Star's Blade",
    "Arayashiki", "Nepcard", "Pen"
}

local MIN_Y = -50
local MAX_Y = 1000

local function scanItems()
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
        if not prompt then
            for _, child in ipairs(obj:GetChildren()) do
                prompt = child:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then break end
            end
        end
        if prompt and prompt.Enabled then
            local container = prompt.Parent
            local name = container.Name
            if table.find(KNOWN_ITEMS, name) then
                local valid = true
                if container:IsA("BasePart") then
                    local pos = container.Position
                    if pos.Y < MIN_Y or pos.Y > MAX_Y then valid = false end
                else
                    local part = container:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local pos = part.Position
                        if pos.Y < MIN_Y or pos.Y > MAX_Y then valid = false end
                    else
                        valid = false
                    end
                end
                if valid and not table.find(found, name) then
                    table.insert(found, name)
                end
            end
        end
    end
    return found
end

local function findItem(itemName)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == itemName then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt and prompt.Enabled then
                local targetPart = nil
                if prompt.Parent:IsA("BasePart") then
                    targetPart = prompt.Parent
                else
                    for _, part in ipairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            targetPart = part
                            break
                        end
                    end
                end
                if targetPart then
                    local pos = targetPart.Position
                    if pos.Y >= MIN_Y and pos.Y <= MAX_Y then
                        return obj, prompt, targetPart
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function instantGrab(targetPart, prompt)
    if not targetPart or not targetPart:IsA("BasePart") then return false end
    if not prompt or not prompt.Enabled then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return false end
    local originalCF = rootPart.CFrame
    local originalCamOffset = humanoid.CameraOffset
    local targetCF = targetPart.CFrame + Vector3.new(0, 0.2, 0)
    local success = false
    local startTime = tick()
    local maxTime = 1.5
    while tick() - startTime < maxTime do
        if not targetPart.Parent or not prompt.Enabled then
            success = true; break
        end
        humanoid.CameraOffset = targetCF:ToObjectSpace(CFrame.new(originalCF.Position)).Position
        rootPart.CFrame = targetCF
        RunService.RenderStepped:Wait()
        fireproximityprompt(prompt)
        task.wait()
    end
    rootPart.CFrame = originalCF
    humanoid.CameraOffset = originalCamOffset
    return success
end

local itemList = scanItems()
local selectedItemName = itemList[1] or ""
local dropdownRow, updateDropdown, getSelected = makeDropdown(extraS, "Select Item", itemList, selectedItemName, function(value)
    selectedItemName = value
end)

makeButton(extraS, "Refresh Item List", function()
    local newList = scanItems()
    updateDropdown(newList, true)
    selectedItemName = #newList > 0 and newList[1] or ""
end)

local statusRowExtra = Instance.new("Frame")
statusRowExtra.Size = UDim2.new(1, -4, 0, 20)
statusRowExtra.BackgroundColor3 = C.row
statusRowExtra.BorderSizePixel = 0
statusRowExtra.ZIndex = 100
statusRowExtra.Parent = extraS
makeCorner(statusRowExtra, 5)
makeStroke(statusRowExtra, C.stroke, 1, 0.5)
local statusLblExtra = Instance.new("TextLabel")
statusLblExtra.Size = UDim2.new(1, 0, 1, 0)
statusLblExtra.BackgroundTransparency = 1
statusLblExtra.Text = "Ready"
statusLblExtra.TextColor3 = C.textDim
statusLblExtra.Font = Enum.Font.Gotham
statusLblExtra.TextSize = 10
statusLblExtra.TextXAlignment = Enum.TextXAlignment.Center
statusLblExtra.ZIndex = 101
statusLblExtra.Parent = statusRowExtra

makeButton(extraS, "Pick Up Selected Item", function()
    if selectedItemName == "" then
        statusLblExtra.Text = "No item selected"
        statusLblExtra.TextColor3 = Color3.fromRGB(255, 200, 100)
        return
    end
    local container, prompt, targetPart = findItem(selectedItemName)
    if not targetPart or not prompt then
        statusLblExtra.Text = "Item not available"
        statusLblExtra.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    statusLblExtra.Text = "Grabbing..."
    statusLblExtra.TextColor3 = Color3.fromRGB(255, 200, 50)
    local success = instantGrab(targetPart, prompt)
    if success then
        statusLblExtra.Text = "Picked up!"
        statusLblExtra.TextColor3 = Color3.fromRGB(100, 255, 100)
        task.delay(0.5, function()
            local newList = scanItems()
            updateDropdown(newList, true)
            selectedItemName = #newList > 0 and newList[1] or ""
            statusLblExtra.Text = "Ready"
            statusLblExtra.TextColor3 = C.textDim
        end)
    else
        statusLblExtra.Text = "Failed"
        statusLblExtra.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(1.5, function()
            statusLblExtra.Text = "Ready"
            statusLblExtra.TextColor3 = C.textDim
        end)
    end
end)

-- Walk into Domains
makeSectionRow(extraS, "Domain")
makeToggle(extraS, "Walk into Domains", false, function(state)
    if state then
        RunService:BindToRenderStep("Walk-Domain", 0, function()
            local domains = workspace:FindFirstChild("Domains")
            if domains then
                local domain = domains:FindFirstChild("Domain")
                if domain and domain:IsA("BasePart") then
                    domain.CanCollide = false
                end
            end
        end)
    else
        RunService:UnbindFromRenderStep("Walk-Domain")
    end
end)

-- Misc
makeSectionRow(extraS, "Misc")
makeToggle(extraS, "Anti AFK", false, function(state)
    _G.AntiAFK = state
    if state then
        local vrs = game:GetService("VirtualInputManager")
        task.spawn(function()
            while _G.AntiAFK do
                vrs:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                task.wait(0.1)
                vrs:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                task.wait(15)
            end
        end)
    end
end)
makeButton(extraS, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)
makeButton(extraS, "Copy Server ID", function()
    setclipboard(game.JobId)
end)

-- -- INVISIBILITY (from JJS) --
makeSectionRow(extraS, "Invisibility")

do
    local OFF = 100
    local iv = { on = false }
    local fake, rconn, trk, apc, cadd, crem, cconn, oc0, rj
    local parts, occ = {}, setmetatable({}, {__mode = "k"})

    if shared.KZMInvis then pcall(shared.KZMInvis.stop) end
    shared.KZMInvis = iv

    local function getRootJoint(c)
        local h = c and c:FindFirstChild("HumanoidRootPart")
        local j = h and h:FindFirstChild("RootJoint")
        if j then return j end
        local lt = c and c:FindFirstChild("LowerTorso")
        return lt and lt:FindFirstChild("Root") or nil
    end

    local function keep(p)
        if occ[p] == nil then occ[p] = p.CanCollide end
        parts[#parts + 1] = p
    end

    local function rebuild(c)
        table.clear(parts)
        if not c then return end
        for _, v in c:GetDescendants() do
            if v:IsA("BasePart") then keep(v) end
        end
    end

    local function getMeditationAnim()
        local a = RS:FindFirstChild("Modules")
        a = a and a:FindFirstChild("MVP")
        a = a and a:FindFirstChild("Meditation")
        return a and a:FindFirstChild("Character") or nil
    end

    local function killFallback()
        if rconn then rconn:Disconnect() rconn = nil end
        if apc then apc:Disconnect() apc = nil end
        if fake then pcall(fake.Destroy, fake) fake = nil end
        if trk then
            pcall(function() trk:Stop() end)
            trk = nil
        end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            h.AutoRotate = true
            workspace.CurrentCamera.CameraSubject = h
        end
    end

    local function step()
        local c = LocalPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        if rj and rj.Parent and oc0 then
            local t = oc0 - Vector3.new(0, OFF, 0)
            if rj.C0 ~= t then rj.C0 = t end
        end
        for i = 1, #parts do
            local p = parts[i]
            if p.Parent and p.CanCollide then p.CanCollide = false end
        end
        local lv = workspace.CurrentCamera.CFrame.LookVector
        local look = Vector3.new(lv.X, 0, lv.Z)
        if look.Magnitude > 0 then
            r.CFrame = CFrame.new(r.Position, r.Position + look.Unit)
        end
        if fake then fake.CFrame = r.CFrame * CFrame.new(0, 1.5, 0) end
    end

    local function pin(hum)
        local a = getMeditationAnim()
        if not a then return end
        local anm = hum:FindFirstChildOfClass("Animator") or hum
        local ok, t = pcall(anm.LoadAnimation, anm, a)
        if not (ok and t) then return end
        trk = t
        t.Priority = Enum.AnimationPriority.Action4
        t:Play()
        task.wait(0.1)
        if trk ~= t or not iv.on then return end
        t.TimePosition = 0.1
        t:AdjustSpeed(0)
        local playing = anm:IsA("Animator") and anm:GetPlayingAnimationTracks() or hum:GetPlayingAnimationTracks()
        for _, o in playing do
            if o ~= t then o:Stop(0) end
        end
        if apc then apc:Disconnect() end
        apc = hum.AnimationPlayed:Connect(function(nt)
            if iv.on and nt ~= trk then nt:Stop(0) end
        end)
    end

    local function start(c)
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not (hum and hrp) then return false end
        killFallback()
        rj = getRootJoint(c)
        if rj then
            oc0 = rj.C0
            rj.C0 = oc0 - Vector3.new(0, OFF, 0)
        end
        rebuild(c)
        if cadd then cadd:Disconnect() end
        if crem then crem:Disconnect() end
        cadd = c.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then keep(d) end
        end)
        crem = c.DescendantRemoving:Connect(function(d)
            if not d:IsA("BasePart") then return end
            for i = 1, #parts do
                if parts[i] == d then
                    parts[i] = parts[#parts]
                    parts[#parts] = nil
                    return
                end
            end
        end)
        pcall(function() LocalPlayer.DevEnableMouseLock = true end)
        hum.AutoRotate = false
        local f = Instance.new("Part")
        f.Name = "KZMFakeTorso"
        f.Size = Vector3.new(2, 2, 1)
        f.Transparency = 1
        f.CanCollide = false
        f.Anchored = true
        f.Parent = workspace
        fake = f
        local cm = workspace.CurrentCamera
        cm.CameraType = Enum.CameraType.Custom
        cm.CameraSubject = f
        rconn = RunService.RenderStepped:Connect(function()
            if iv.on then step() end
        end)
        task.spawn(pin, hum)
        return true
    end

    local function undo()
        iv.on = false
        if cadd then cadd:Disconnect() cadd = nil end
        if crem then crem:Disconnect() crem = nil end
        killFallback()
        local c = LocalPlayer.Character
        if c then
            local j = (rj and rj.Parent) and rj or getRootJoint(c)
            if j and oc0 then j.C0 = oc0 end
            for _, v in c:GetDescendants() do
                if v:IsA("BasePart") then
                    local o = occ[v]
                    v.CanCollide = o == nil or o
                end
            end
        end
        oc0, rj = nil, nil
        table.clear(parts)
    end

    function iv.stop()
        if cconn then cconn:Disconnect() cconn = nil end
        undo()
    end

    function iv.set(v)
        if v ~= true then
            iv.stop()
            return true
        end
        if iv.on then return true end
        iv.on = true
        if not start(LocalPlayer.Character) then
            iv.on = false
            return false
        end
        if not cconn then
            cconn = LocalPlayer.CharacterAdded:Connect(function(c)
                if not iv.on then return end
                oc0, rj = nil, nil
                c:WaitForChild("HumanoidRootPart", 5)
                c:WaitForChild("Humanoid", 5)
                if iv.on then start(c) end
            end)
        end
        return true
    end

    local _, setInvisState
    _, setInvisState = makeToggle(extraS, "Invisibility", false, function(state)
        if iv.set(state) == false then
            setInvisState(false)
        end
    end)
end

-- -- DEFENSE (Anti Stun / No Block Slow / Anti Ragdoll) --
makeSectionRow(extraS, "Defense")

do
    local antiStun, noBlockSlow, antiRagdoll = false, false, false
    local blockSpeed = 16

    local loopConn, hookedChar, attrConn, hrpConn
    local grace, ragUntil, lastRepair = 0, 0, 0
    local base = { ws = 16, jp = 50, jh = 7.2 }

    local STUN_NAMES = { stun = true, stunned = true, hitstun = true }
    local function isStunName(n) return STUN_NAMES[string.lower(n)] == true end
    local function isRagName(n) return string.find(string.lower(n), "ragdoll", 1, true) ~= nil end

    local function falsy(v)
        local t = typeof(v)
        if t == "number" then return v <= 0 end
        if t == "boolean" then return not v end
        if t == "string" then return v == "" end
        return v == nil
    end

    -- clears every truthy attribute whose name matches; returns true if anything was active
    local function clearAttrs(inst, match)
        local hit = false
        for name, v in pairs(inst:GetAttributes()) do
            if match(name) and not falsy(v) then
                hit = true
                local t = typeof(v)
                if t == "number" then inst:SetAttribute(name, 0)
                elseif t == "boolean" then inst:SetAttribute(name, false)
                elseif t == "string" then inst:SetAttribute(name, "")
                else inst:SetAttribute(name, nil) end
            end
        end
        return hit
    end

    -- destroys children (of any depth 1) whose name matches; returns true if any existed
    local function killChildren(parent, match)
        local hit = false
        for _, ch in ipairs(parent:GetChildren()) do
            if match(ch.Name) then
                hit = true
                pcall(ch.Destroy, ch)
            end
        end
        return hit
    end

    local BAD_STATES = {
        [Enum.HumanoidStateType.Physics] = true,
        [Enum.HumanoidStateType.Ragdoll] = true,
        [Enum.HumanoidStateType.FallingDown] = true,
        [Enum.HumanoidStateType.PlatformStanding] = true,
    }
    local FIX_STATES = {
        Enum.HumanoidStateType.GettingUp,
        Enum.HumanoidStateType.Running,
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.Jumping,
    }

    -- undo the physical side of a ragdoll (motors, constraints, humanoid state)
    local function repairRagdoll(char, hum)
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("Motor6D") then
                if not d.Enabled then d.Enabled = true end
            elseif d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint") then
                pcall(d.Destroy, d)
            end
        end
        for _, st in ipairs(FIX_STATES) do
            pcall(hum.SetStateEnabled, hum, st, true)
        end
        hum.PlatformStand = false
        hum.AutoRotate = true
        if BAD_STATES[hum:GetState()] then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    -- NO KNOCKBACK: the game pushes you with a BodyVelocity named "KnockbackForce" on the root part
    local function killKnockback(hrp)
        local hit = false
        for _, ch in ipairs(hrp:GetChildren()) do
            if ch.Name == "KnockbackForce" then
                hit = true
                pcall(ch.Destroy, ch)
            end
        end
        if hit then
            local v = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0) -- drop the sideways shove, keep gravity
        end
        return hit
    end

    local function onAttr(char, name)
        if antiRagdoll and isRagName(name) then
            if clearAttrs(char, isRagName) then ragUntil = os.clock() + 0.8 end
        end
        if antiStun and isStunName(name) then
            if clearAttrs(char, isStunName) then grace = os.clock() + 0.4 end
        end
    end

    local function hook(char)
        if attrConn then attrConn:Disconnect() attrConn = nil end
        if hrpConn then hrpConn:Disconnect() hrpConn = nil end
        hookedChar = char
        if char then
            attrConn = char.AttributeChanged:Connect(function(name) onAttr(char, name) end)
            task.spawn(function()
                local root = char:WaitForChild("HumanoidRootPart", 5)
                if root and hookedChar == char then
                    hrpConn = root.ChildAdded:Connect(function(ch)
                        if antiRagdoll and ch.Name == "KnockbackForce" then
                            killKnockback(root)
                        end
                    end)
                end
            end)
        end
    end

    local function tick()
        local char = LocalPlayer.Character
        if not char then return end
        if char ~= hookedChar then hook(char) end   -- self-heals after every respawn

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local info = char:FindFirstChild("Info")  -- re-fetched every frame, never stale
        local now = os.clock()
        local blocking = info and info:FindFirstChild("Block") ~= nil

        -- ANTI STUN
        if antiStun then
            local hit = clearAttrs(char, isStunName)
            if info then
                if killChildren(info, isStunName) then hit = true end
                if clearAttrs(info, isStunName) then hit = true end
            end
            if hit then grace = now + 0.4 end

            if now < grace then
                if not (noBlockSlow and blocking) then
                    if hum.WalkSpeed < base.ws then hum.WalkSpeed = base.ws end
                    if hum.UseJumpPower then
                        if hum.JumpPower < base.jp then hum.JumpPower = base.jp end
                    else
                        if hum.JumpHeight < base.jh then hum.JumpHeight = base.jh end
                    end
                end
                if hum.PlatformStand and now >= ragUntil then hum.PlatformStand = false end
                hum.AutoRotate = true
                if hrp and hrp.Anchored then hrp.Anchored = false end
            end
        end

        -- remember the "normal" movement values (never while stunned/blocking/just-stunned)
        if not blocking and now > grace + 0.3 and now > ragUntil + 0.3 then
            if hum.WalkSpeed > 0 then base.ws = hum.WalkSpeed end
            if hum.UseJumpPower then
                if hum.JumpPower > 0 then base.jp = hum.JumpPower end
            else
                if hum.JumpHeight > 0 then base.jh = hum.JumpHeight end
            end
        end

        -- NO BLOCK SLOW
        if noBlockSlow and blocking then
            if hum.WalkSpeed ~= blockSpeed then hum.WalkSpeed = blockSpeed end
            if hum.JumpPower ~= 50 then hum.JumpPower = 50 end
        end

        -- ANTI RAGDOLL
        if antiRagdoll then
            local hit = clearAttrs(char, isRagName)
            if clearAttrs(hum, isRagName) then hit = true end
            if info then
                if clearAttrs(info, isRagName) then hit = true end
                if killChildren(info, isRagName) then hit = true end
            end
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                hit = true
            end
            if hit then ragUntil = now + 0.8 end
            if hrp then killKnockback(hrp) end
            if now < ragUntil and now - lastRepair > 0.08 then
                lastRepair = now
                repairRagdoll(char, hum)
            end
        end
    end

    local function sync()
        if antiStun or noBlockSlow or antiRagdoll then
            if not loopConn then
                -- Stepped runs before physics, so fixes land the same frame
                loopConn = RunService.Stepped:Connect(function()
                    local ok, err = pcall(tick)
                    if not ok then warn("[KZM Defense] " .. tostring(err)) end
                end)
            end
        else
            if loopConn then loopConn:Disconnect() loopConn = nil end
            if attrConn then attrConn:Disconnect() attrConn = nil end
            if hrpConn then hrpConn:Disconnect() hrpConn = nil end
            hookedChar = nil
        end
    end

    makeToggle(extraS, "Anti Stun", false, function(state)
        antiStun = state
        grace = 0
        sync()
    end)

    makeToggle(extraS, "No Block Slow", false, function(state)
        noBlockSlow = state
        sync()
    end)

    makeSlider(extraS, "Block Walk Speed", 8, 50, 16, function(v)
        blockSpeed = v
    end)

    makeToggle(extraS, "Anti Ragdoll + No Knockback", false, function(state)
        antiRagdoll = state
        ragUntil = 0
        RunService:UnbindFromRenderStep("KZM-AntiRagdoll") -- remove the old binding if present
        sync()
    end)
end

-- ── DOOR ESP ──
makeSectionRow(extraS, "Door ESP")

do
    local effects = nil
    local tracked = {}
    local conns = {}
    local espOn = false

    local function getPart(obj)
        if obj:IsA("BasePart") then return obj end
        return obj:FindFirstChildWhichIsA("BasePart", true)
    end

    local function removeESP(door)
        local d = tracked[door]
        if d then
            pcall(function() d.hl:Destroy() end)
            pcall(function() d.bb:Destroy() end)
            tracked[door] = nil
        end
    end

    local function addESP(door)
        if not espOn or tracked[door] then return end
        local part = getPart(door)
        if not part then
            task.delay(0.5, function()
                if espOn and door.Parent then addESP(door) end
            end)
            return
        end

        local hl = Instance.new("Highlight")
        hl.Name = "DoorESP"
        hl.Adornee = door
        hl.FillColor = Color3.fromRGB(0, 255, 120)
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.FillTransparency = 0.5
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = door

        local bb = Instance.new("BillboardGui")
        bb.Name = "DoorLabel"
        bb.Adornee = part
        bb.Size = UDim2.fromOffset(100, 24)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = door

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.fromScale(1, 1)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.fromRGB(0, 255, 120)
        txt.TextStrokeTransparency = 0
        txt.TextScaled = true
        txt.Font = Enum.Font.GothamBold
        txt.Parent = bb

        tracked[door] = { hl = hl, bb = bb, txt = txt, part = part }
    end

    local function stopDoorESP()
        espOn = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        table.clear(conns)
        for door in pairs(tracked) do removeESP(door) end
    end

    local function startDoorESP()
        stopDoorESP()
        espOn = true
        task.spawn(function()
            effects = workspace:WaitForChild("Effects", 10)
            if not effects or not espOn then return end
            for _, v in ipairs(effects:GetDescendants()) do
                if v.Name == "Door" then addESP(v) end
            end
            table.insert(conns, effects.DescendantAdded:Connect(function(v)
                if v.Name == "Door" then addESP(v) end
            end))
            table.insert(conns, effects.DescendantRemoving:Connect(function(v)
                if tracked[v] then removeESP(v) end
            end))
            table.insert(conns, RunService.RenderStepped:Connect(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                for _, d in pairs(tracked) do
                    if d.part and d.part.Parent then
                        local dist = math.floor((d.part.Position - root.Position).Magnitude)
                        d.txt.Text = "Door [" .. dist .. "m]"
                    end
                end
            end))
        end)
    end

    makeToggle(extraS, "Door ESP", false, function(state)
        if state then startDoorESP() else stopDoorESP() end
    end)
end

-- ── INSTA PROMPT ──
makeSectionRow(extraS, "Insta Prompt")

do
    local instaOn = false
    local promptConn = nil

    makeToggle(extraS, "Insta Prompt", false, function(state)
        instaOn = state
        if promptConn then promptConn:Disconnect() promptConn = nil end
        if not state then return end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then v.HoldDuration = 0 end
        end
        promptConn = game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(v)
            if instaOn then v.HoldDuration = 0 end
        end)
    end)
end

-- ==========================================
-- CONFIGS TAB
-- ==========================================
local configS = scrolls["Configs"]

makeSectionRow(configS, "UI Settings")
makeSlider(configS, "UI Transparency", 0, 90, 0, function(v)
    window.BackgroundTransparency = v / 100
end)
makeButton(configS, "Reset Position", function()
    window.Position = UDim2.new(0.5, 0, 0.5, 0)
    UI.restPos = window.Position
end)

makeSectionRow(configS, "Button Positions")
makeToggle(configS, "Lock Lock-On Button Position", false, function(state)
    UI.locks.lockOn = state
end)
makeToggle(configS, "Lock Fly Button Position", false, function(state)
    UI.locks.fly = state
end)
makeToggle(configS, "Lock KZM Open Button Position", false, function(state)
    UI.locks.toggle = state
end)
makeToggle(configS, "Lock Orbit Button Position", false, function(state)
    UI.locks.orbit = state
end)

makeSectionRow(configS, "Credits")
local credLbl = Instance.new("Frame")
credLbl.Size = UDim2.new(1, -4, 0, 36)
credLbl.BackgroundColor3 = C.row
credLbl.BorderSizePixel = 0
credLbl.ZIndex = 100
credLbl.Parent = configS
makeCorner(credLbl, 6)
local credText = Instance.new("TextLabel")
credText.Size = UDim2.new(1, 0, 1, 0)
credText.BackgroundTransparency = 1
credText.Text = "KZM - Made for JJS\nBuilt by KZM"
credText.TextColor3 = C.textDim
credText.Font = Enum.Font.Gotham
credText.TextSize = 10
credText.TextXAlignment = Enum.TextXAlignment.Center
credText.ZIndex = 101
credText.Parent = credLbl

-- ==========================================
-- RESET ON RESPAWN
-- ==========================================
LocalPlayer.CharacterAdded:Connect(function()
    tpBypassOn = false
    unantistuff()
    tpSelOn = false
    if tpSelConn then tpSelConn:Disconnect(); tpSelConn = nil end
    tpLoopOn = false
    if tpLoopConn then tpLoopConn:Disconnect(); tpLoopConn = nil end
    selectedPlayer = nil
    setTeleportStatus("Respawned", Color3.fromRGB(100, 200, 100))
    if spectateConnection then spectateConnection:Disconnect(); spectateConnection = nil end
    spectateActive = false
    setSpectateToggle(false)
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character or workspace
end)

-- Fire every default-ON toggle's callback so the feature really starts
-- (previously only the visual state was ON until you toggled it twice).
task.defer(function()
    for _, d in ipairs(KZM_DEFAULTS) do
        task.spawn(function()
            for attempt = 1, 3 do
                local ok, err = pcall(d.fn, true)
                if ok then return end
                warn("[KZM] default '" .. d.name .. "' failed (try " .. attempt .. "): " .. tostring(err))
                task.wait(1.5)
            end
        end)
    end
end)

print("KZM v3.2 loaded — Force Reset silent, Emote Unlocker silent, Fly animation improved with dynamic pose and effects.")