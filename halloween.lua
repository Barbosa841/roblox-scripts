--[[
  Anime Dice - Halloween Auto Trick-or-Treat
  Runtime: Xeno (Luau) - single-file, sem key
  Uso: loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USER/SEU_REPO/main/halloween.lua"))()
  Autor: Zyon
]]

local Players = game:GetService("Players")
local VIM     = game:GetService("VirtualInputManager")
local LP      = Players.LocalPlayer

local CFG = {
    DoorKeywords = {"trick or treat","trickortreat","trick-or-treat","trick_or_treat"},
    PromptWords  = {"trick","treat","enter","open","use","interact"},
    ArriveDist   = 6,
    ActionDelay  = 0.25,
    PostWait     = 0.5,
    AntiAFKDelay = 60,
    SmoothTP     = true,
}

local state = { run = true, afk = true, tot = true, log = {} }

local function log(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    local msg = table.concat(parts, " ")
    table.insert(state.log, 1, msg)
    if #state.log > 6 then table.remove(state.log) end
    print("[Zyon|ToT]", msg)
end

local function lower(s) return string.lower(tostring(s)) end
local function hit(name, kws)
    local n = lower(name)
    for _, k in ipairs(kws) do
        if string.find(n, lower(k), 1, true) then return true end
    end
    return false
end

-- ================= ANTI-AFK =================
task.spawn(function()
    while state.run do
        task.wait(CFG.AntiAFKDelay)
        if state.afk then
            pcall(function()
                VIM:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
        end
    end
end)

-- ================= DETECÇÃO =================
local function isDoor(p)
    if not p or not p:IsA("BasePart") then return false end
    if LP.Character and p:IsDescendantOf(LP.Character) then return false end
    return hit(p.Name, CFG.DoorKeywords)
end

local function nearestDoor()
    local c = LP.Character; if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
    local best, bd = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if isDoor(v) then
            local d = (v.Position - r.Position).Magnitude
            if d < bd then best, bd = v, d end
        end
    end
    return best, bd
end

local function findPrompt(part)
    if not part then return end
    for _, d in ipairs(part:GetDescendants()) do
        if d:IsA("ProximityPrompt") then return d end
    end
    if part.Parent then
        for _, d in ipairs(part.Parent:GetDescendants()) do
            if d:IsA("ProximityPrompt") then return d end
        end
    end
end

-- ================= AÇÃO =================
local function tp(part)
    local c = LP.Character; if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
    local t = part.CFrame * CFrame.new(0, 3, 0)
    if CFG.SmoothTP then r.CFrame = t else r.Position = t.Position end
end

local function firePrompt(p)
    if not p then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(p)
        else
            p:InputHoldBegin(); task.wait(p.HoldDuration or 0.1); p:InputHoldEnd()
        end
    end)
end

-- ================= LOOP PRINCIPAL =================
task.spawn(function()
    local lastDoor, lastT = nil, 0
    while state.run do
        if state.tot then
            pcall(function()
                local door, dist = nearestDoor()
                if door then
                    if dist > CFG.ArriveDist then
                        tp(door)
                        task.wait(CFG.ActionDelay)
                    end
                    local now = tick()
                    if door ~= lastDoor or (now - lastT) > 1.0 then
                        local pr = findPrompt(door)
                        if pr then
                            firePrompt(pr)
                            log("prompt:", pr.Name)
                        end
                        lastDoor, lastT = door, now
                        task.wait(CFG.PostWait)
                    end
                end
            end)
        end
        task.wait(CFG.ActionDelay)
    end
end)

-- ================= HUD =================
local gui = Instance.new("ScreenGui")
gui.Name = "ZyonToT"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 250)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(255, 130, 40)
title.BorderSizePixel = 0
title.Text = "Zyon | Halloween ToT"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local function makeBtn(text, y, cb)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 230, 230)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(cb)
    return b
end

local btnTot = makeBtn("Auto ToT: ON", 40, function()
    state.tot = not state.tot
    btnTot.Text = "Auto ToT: " .. (state.tot and "ON" or "OFF")
    btnTot.BackgroundColor3 = state.tot and Color3.fromRGB(40, 40, 48) or Color3.fromRGB(80, 30, 30)
end)

local btnAfk = makeBtn("Anti-AFK: ON", 76, function()
    state.afk = not state.afk
    btnAfk.Text = "Anti-AFK: " .. (state.afk and "ON" or "OFF")
    btnAfk.BackgroundColor3 = state.afk and Color3.fromRGB(40, 40, 48) or Color3.fromRGB(80, 30, 30)
end)

local logBox = Instance.new("TextLabel", frame)
logBox.Size = UDim2.new(1, -20, 0, 55)
logBox.Position = UDim2.new(0, 10, 0, 112)
logBox.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
logBox.BorderSizePixel = 0
logBox.Text = ""
logBox.TextColor3 = Color3.fromRGB(180, 
