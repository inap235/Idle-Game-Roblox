--[[
	Idle Gem-Tree Game – Client
	Primary gameplay: see 3D trees in world, walk up & interact.
	HUD: coins + resources always visible.
	Menu: toggleable overlay for Shop, Market, Progression.
]]

----------------------------------------------------------------------
-- Services
----------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

----------------------------------------------------------------------
-- References
----------------------------------------------------------------------
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = Workspace.CurrentCamera
local TreeConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TreeConfig"))
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")

local PlantTreeRemote    = Remotes:WaitForChild("PlantTree")
local WaterTreeRemote    = Remotes:WaitForChild("WaterTree")
local SellResourceRemote = Remotes:WaitForChild("SellResource")
local ReviveTreeRemote   = Remotes:WaitForChild("ReviveTree")
local CollectAllRemote   = Remotes:WaitForChild("CollectAll")
local GetDataFunc        = Remotes:WaitForChild("GetPlayerData")
local GetMarketFunc      = Remotes:WaitForChild("GetMarketPrices")
local UpdateDataEvent    = Remotes:WaitForChild("UpdateData")
local FeedbackEvent      = Remotes:WaitForChild("Feedback")
local NotificationEvent  = Remotes:WaitForChild("Notification")
local TierUnlockEvent    = Remotes:WaitForChild("TierUnlock")
local FloatingTextEvent  = Remotes:WaitForChild("FloatingText")

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------
local cachedData   = nil
local menuOpen     = false
local currentTab   = "shop"

----------------------------------------------------------------------
-- Color palette
----------------------------------------------------------------------
local C = {
	bg          = Color3.fromRGB(18, 18, 28),
	panel       = Color3.fromRGB(28, 28, 42),
	panelLight  = Color3.fromRGB(38, 38, 55),
	accent      = Color3.fromRGB(80, 200, 120),
	gold        = Color3.fromRGB(255, 215, 0),
	red         = Color3.fromRGB(220, 50, 50),
	orange      = Color3.fromRGB(255, 165, 0),
	blue        = Color3.fromRGB(70, 130, 230),
	white       = Color3.fromRGB(240, 240, 245),
	gray        = Color3.fromRGB(140, 140, 160),
	darkGray    = Color3.fromRGB(60, 60, 80),
	success     = Color3.fromRGB(80, 200, 120),
	error       = Color3.fromRGB(220, 50, 50),
	warn        = Color3.fromRGB(255, 165, 0),
	info        = Color3.fromRGB(70, 130, 230),
}

----------------------------------------------------------------------
-- UI Helpers
----------------------------------------------------------------------
local function create(className: string, props: { [string]: any }): Instance
	local inst = Instance.new(className)
	for k, v in props do
		if k == "Parent" then continue end
		(inst :: any)[k] = v
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function addCorner(parent: Instance, radius: number?)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function addPadding(parent: Instance, px: number?)
	local p = px or 8
	create("UIPadding", {
		PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
		PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
		Parent = parent,
	})
end

local function addStroke(parent: Instance, color: Color3?, thickness: number?)
	create("UIStroke", { Color = color or C.darkGray, Thickness = thickness or 1, Parent = parent })
end

----------------------------------------------------------------------
-- ScreenGui
----------------------------------------------------------------------
local screenGui = create("ScreenGui", {
	Name = "IdleGameUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	Parent = playerGui,
})

----------------------------------------------------------------------
-- ============  HUD (always visible)  ============
----------------------------------------------------------------------
local hudFrame = create("Frame", {
	Name = "HUD",
	Size = UDim2.new(1, 0, 0, 56),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
	Parent = screenGui,
	ZIndex = 50,
})
addStroke(hudFrame, C.darkGray, 1)

-- Coins
local coinsLabel = create("TextLabel", {
	Size = UDim2.new(0, 220, 0, 28),
	Position = UDim2.new(0, 16, 0, 4),
	BackgroundTransparency = 1,
	Text = "Coins: 50",
	TextColor3 = C.gold,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = hudFrame,
	ZIndex = 51,
})

-- Tier
local tierLabel = create("TextLabel", {
	Size = UDim2.new(0, 300, 0, 18),
	Position = UDim2.new(0, 16, 0, 34),
	BackgroundTransparency = 1,
	Text = "Tier 0 - Beginner  |  Slots: 1/3",
	TextColor3 = C.gray,
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = hudFrame,
	ZIndex = 51,
})

-- Resources (right side)
local resFrame = create("Frame", {
	Size = UDim2.new(0, 520, 0, 44),
	Position = UDim2.new(1, -530, 0, 6),
	BackgroundTransparency = 1,
	Parent = hudFrame,
	ZIndex = 51,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Parent = resFrame,
})

local resourceLabels = {}
for i, res in TreeConfig.ResourceOrder do
	local box = create("Frame", {
		Size = UDim2.new(0, 80, 0, 40),
		BackgroundColor3 = C.panelLight,
		BackgroundTransparency = 0.3,
		LayoutOrder = i,
		Parent = resFrame,
		ZIndex = 52,
	})
	addCorner(box, 5)

	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 13),
		Position = UDim2.new(0, 0, 0, 3),
		BackgroundTransparency = 1,
		Text = res,
		TextColor3 = C.gray,
		TextSize = 9,
		Font = Enum.Font.Gotham,
		Parent = box,
		ZIndex = 53,
	})

	local valLabel = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 17),
		BackgroundTransparency = 1,
		Text = "0",
		TextColor3 = C.white,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		Parent = box,
		ZIndex = 53,
	})
	resourceLabels[res] = valLabel
end

----------------------------------------------------------------------
-- ============  BOTTOM ACTION BAR  ============
----------------------------------------------------------------------
-- Collect All button (bottom center)
local collectBtn = create("TextButton", {
	Size = UDim2.new(0, 170, 0, 44),
	Position = UDim2.new(0.5, -85, 1, -60),
	BackgroundColor3 = C.accent,
	Text = "Collect All",
	TextColor3 = C.bg,
	TextSize = 17,
	Font = Enum.Font.GothamBold,
	Parent = screenGui,
	ZIndex = 50,
})
addCorner(collectBtn, 10)
addStroke(collectBtn, Color3.fromRGB(60, 160, 90), 2)
collectBtn.MouseButton1Click:Connect(function()
	CollectAllRemote:FireServer()
end)

-- Menu toggle button (bottom right)
local menuBtn = create("TextButton", {
	Size = UDim2.new(0, 120, 0, 44),
	Position = UDim2.new(1, -135, 1, -60),
	BackgroundColor3 = C.panel,
	Text = "Menu",
	TextColor3 = C.white,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Parent = screenGui,
	ZIndex = 50,
})
addCorner(menuBtn, 10)
addStroke(menuBtn, C.accent, 2)

----------------------------------------------------------------------
-- ============  3D FLOATING TEXT (resource gain above trees)  ============
----------------------------------------------------------------------
local function showFloating3D(text: string, worldPos: Vector3, color: { number }?)
	local col = if color then Color3.fromRGB(color[1], color[2], color[3]) else C.gold

	-- Create a BillboardGui at that world position
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Position = worldPos
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 150, 0, 40)
	bb.StudsOffset = Vector3.new(0, 0, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = part
	bb.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = col
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.2
	label.TextSize = 20
	label.Font = Enum.Font.GothamBold
	label.Parent = bb

	-- Animate: rise up + fade
	local startY = worldPos.Y
	local startTime = os.clock()
	local duration = 1.8
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = (os.clock() - startTime) / duration
		if t >= 1 then
			conn:Disconnect()
			part:Destroy()
			return
		end
		part.Position = Vector3.new(worldPos.X, startY + t * 5, worldPos.Z)
		label.TextTransparency = t
		label.TextStrokeTransparency = 0.2 + t * 0.8
	end)
end

FloatingTextEvent.OnClientEvent:Connect(showFloating3D)

----------------------------------------------------------------------
-- ============  FEEDBACK SYSTEM (screen text + notifications)  ============
----------------------------------------------------------------------
local feedbackContainer = create("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = screenGui,
	ZIndex = 80,
})

local notifContainer = create("Frame", {
	Size = UDim2.new(0, 360, 0, 300),
	Position = UDim2.new(1, -370, 0, 65),
	BackgroundTransparency = 1,
	Parent = screenGui,
	ZIndex = 70,
})
create("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 4),
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Parent = notifContainer,
})

local function showFloatingText(message: string, feedbackType: string?)
	local color = C.white
	if feedbackType == "success" then color = C.success
	elseif feedbackType == "error" then color = C.error
	elseif feedbackType == "coins" then color = C.gold
	elseif feedbackType == "resource" then color = C.accent
	elseif feedbackType == "warn" then color = C.warn
	elseif feedbackType == "info" then color = C.blue end

	local label = create("TextLabel", {
		Size = UDim2.new(0, 400, 0, 40),
		Position = UDim2.new(0.5, -200, 0.4, 0),
		BackgroundTransparency = 1,
		Text = message,
		TextColor3 = color,
		TextSize = 24,
		Font = Enum.Font.GothamBold,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0.2,
		Parent = feedbackContainer,
		ZIndex = 81,
	})

	local tween = TweenService:Create(label, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0.25, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function() label:Destroy() end)
end

local function showNotification(message: string, notifType: string?)
	local color = C.white
	local bgColor = C.panelLight
	if notifType == "success" then color = C.success; bgColor = Color3.fromRGB(20, 50, 30)
	elseif notifType == "error" then color = C.error; bgColor = Color3.fromRGB(50, 20, 20)
	elseif notifType == "warn" then color = C.warn; bgColor = Color3.fromRGB(50, 40, 15)
	elseif notifType == "info" then color = C.info; bgColor = Color3.fromRGB(20, 30, 50)
	end

	local frame = create("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = bgColor,
		BackgroundTransparency = 0.1,
		Parent = notifContainer,
		ZIndex = 71,
	})
	addCorner(frame, 6)
	addStroke(frame, color, 1)

	create("TextLabel", {
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		Text = message,
		TextColor3 = color,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
		ZIndex = 72,
	})

	task.delay(4, function()
		if frame and frame.Parent then
			local tw = TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
			tw:Play()
			tw.Completed:Connect(function() frame:Destroy() end)
		end
	end)
end

-- Tier unlock celebration
local function showTierUnlock(tier: number, tierName: string, unlocks: string)
	local overlay = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Parent = screenGui,
		ZIndex = 200,
	})
	local box = create("Frame", {
		Size = UDim2.new(0, 380, 0, 180),
		Position = UDim2.new(0.5, -190, 0.5, -90),
		BackgroundColor3 = C.panel,
		Parent = overlay,
		ZIndex = 201,
	})
	addCorner(box, 12)
	addStroke(box, C.gold, 2)

	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 12),
		BackgroundTransparency = 1, Text = "TIER " .. tier .. " UNLOCKED!",
		TextColor3 = C.gold, TextSize = 26, Font = Enum.Font.GothamBold,
		Parent = box, ZIndex = 202,
	})
	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 52),
		BackgroundTransparency = 1, Text = tierName,
		TextColor3 = C.white, TextSize = 20, Font = Enum.Font.GothamMedium,
		Parent = box, ZIndex = 202,
	})
	create("TextLabel", {
		Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 80),
		BackgroundTransparency = 1, Text = "Unlocked: " .. unlocks,
		TextColor3 = C.accent, TextSize = 14, Font = Enum.Font.Gotham,
		TextWrapped = true, Parent = box, ZIndex = 202,
	})
	local closeBtn = create("TextButton", {
		Size = UDim2.new(0, 100, 0, 32), Position = UDim2.new(0.5, -50, 1, -44),
		BackgroundColor3 = C.accent, Text = "Nice!",
		TextColor3 = C.bg, TextSize = 15, Font = Enum.Font.GothamBold,
		Parent = box, ZIndex = 203,
	})
	addCorner(closeBtn, 6)
	closeBtn.MouseButton1Click:Connect(function() overlay:Destroy() end)
	task.delay(6, function() if overlay and overlay.Parent then overlay:Destroy() end end)
end

FeedbackEvent.OnClientEvent:Connect(showFloatingText)
NotificationEvent.OnClientEvent:Connect(showNotification)
TierUnlockEvent.OnClientEvent:Connect(showTierUnlock)

----------------------------------------------------------------------
-- ============  MENU OVERLAY (Shop / Market / Progression)  ============
----------------------------------------------------------------------
local menuOverlay = create("Frame", {
	Name = "MenuOverlay",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Visible = false,
	Parent = screenGui,
	ZIndex = 90,
})

-- Menu panel (centered)
local menuPanel = create("Frame", {
	Size = UDim2.new(0, 620, 0, 500),
	Position = UDim2.new(0.5, -310, 0.5, -250),
	BackgroundColor3 = C.panel,
	Parent = menuOverlay,
	ZIndex = 91,
})
addCorner(menuPanel, 12)
addStroke(menuPanel, C.accent, 2)

-- Close button
local closeMenuBtn = create("TextButton", {
	Size = UDim2.new(0, 36, 0, 36),
	Position = UDim2.new(1, -42, 0, 6),
	BackgroundColor3 = C.red,
	Text = "X",
	TextColor3 = C.white,
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	Parent = menuPanel,
	ZIndex = 99,
})
addCorner(closeMenuBtn, 18)

-- Tab bar inside menu
local menuTabBar = create("Frame", {
	Size = UDim2.new(1, -16, 0, 38),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1,
	Parent = menuPanel,
	ZIndex = 92,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 4),
	Parent = menuTabBar,
})

local menuTabs = {
	{ id = "shop",        label = "Shop",        order = 1 },
	{ id = "market",      label = "Market",       order = 2 },
	{ id = "progression", label = "Progression",  order = 3 },
}

local menuTabBtns = {}
local menuTabPanels = {}

for _, tab in menuTabs do
	local btn = create("TextButton", {
		Size = UDim2.new(0, 190, 1, 0),
		BackgroundColor3 = if tab.id == currentTab then C.panelLight else C.bg,
		Text = tab.label,
		TextColor3 = if tab.id == currentTab then C.accent else C.gray,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		LayoutOrder = tab.order,
		BorderSizePixel = 0,
		Parent = menuTabBar,
		ZIndex = 93,
	})
	addCorner(btn, 6)
	menuTabBtns[tab.id] = btn
end

-- Menu content area
local menuContent = create("Frame", {
	Size = UDim2.new(1, -16, 1, -56),
	Position = UDim2.new(0, 8, 0, 50),
	BackgroundColor3 = C.bg,
	ClipsDescendants = true,
	Parent = menuPanel,
	ZIndex = 92,
})
addCorner(menuContent, 8)

----------------------------------------------------------------------
--  SHOP PANEL
----------------------------------------------------------------------
local shopPanel = create("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = C.gray,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = menuContent,
	ZIndex = 93,
})
addPadding(shopPanel, 10)
create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = shopPanel })

create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundTransparency = 1,
	Text = "Seed Shop  -  Buy seeds to grow new trees",
	TextColor3 = C.white, TextSize = 17, Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0,
	Parent = shopPanel, ZIndex = 94,
})

local shopCards = {}
for i, treeId in TreeConfig.TreeOrder do
	local treeCfg = TreeConfig.Trees[treeId]

	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 78),
		BackgroundColor3 = C.panelLight,
		LayoutOrder = i, Parent = shopPanel, ZIndex = 94,
	})
	addCorner(card, 8)
	addStroke(card, C.darkGray)

	create("TextLabel", {
		Size = UDim2.new(0, 220, 0, 22), Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1, Text = treeCfg.icon .. "  " .. treeCfg.name,
		TextColor3 = C.white, TextSize = 16, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})
	create("TextLabel", {
		Size = UDim2.new(0.55, 0, 0, 16), Position = UDim2.new(0, 10, 0, 28),
		BackgroundTransparency = 1, Text = treeCfg.description,
		TextColor3 = C.gray, TextSize = 11, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})
	create("TextLabel", {
		Size = UDim2.new(0.55, 0, 0, 14), Position = UDim2.new(0, 10, 0, 46),
		BackgroundTransparency = 1,
		Text = string.format("+%d %s / %ds  |  Tier %d", treeCfg.yieldPerCycle, treeCfg.resourceType, treeCfg.cycleTime, treeCfg.unlockTier),
		TextColor3 = C.gray, TextSize = 10, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})

	local costText = if treeCfg.cost == 0 then "FREE" else treeCfg.cost .. " coins"
	local buyBtn = create("TextButton", {
		Size = UDim2.new(0, 110, 0, 32), Position = UDim2.new(1, -120, 0.5, -16),
		BackgroundColor3 = C.accent, Text = costText,
		TextColor3 = C.bg, TextSize = 14, Font = Enum.Font.GothamBold,
		Parent = card, ZIndex = 96,
	})
	addCorner(buyBtn, 6)

	local lockOverlay = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6,
		Visible = false, Parent = card, ZIndex = 97,
	})
	addCorner(lockOverlay, 8)
	create("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		Text = "Tier " .. treeCfg.unlockTier .. " required",
		TextColor3 = C.gray, TextSize = 14, Font = Enum.Font.GothamBold,
		Parent = lockOverlay, ZIndex = 98,
	})

	buyBtn.MouseButton1Click:Connect(function()
		PlantTreeRemote:FireServer(treeId)
	end)

	shopCards[treeId] = { card = card, buyBtn = buyBtn, lockOverlay = lockOverlay }
end

menuTabPanels["shop"] = shopPanel

----------------------------------------------------------------------
--  MARKET PANEL
----------------------------------------------------------------------
local marketPanel = create("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4, ScrollBarImageColor3 = C.gray,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Visible = false, Parent = menuContent, ZIndex = 93,
})
addPadding(marketPanel, 10)
create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = marketPanel })

create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
	Text = "Market  -  Sell resources (prices fluctuate!)",
	TextColor3 = C.white, TextSize = 17, Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0,
	Parent = marketPanel, ZIndex = 94,
})
create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
	Text = "Selling large amounts crashes prices. They recover over time.",
	TextColor3 = C.orange, TextSize = 11, Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
	LayoutOrder = 1, Parent = marketPanel, ZIndex = 94,
})

local marketCards = {}
for i, res in TreeConfig.ResourceOrder do
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = C.panelLight, LayoutOrder = i + 1,
		Parent = marketPanel, ZIndex = 94,
	})
	addCorner(card, 8)
	addStroke(card, C.darkGray)

	create("TextLabel", {
		Size = UDim2.new(0, 100, 0, 22), Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1, Text = res,
		TextColor3 = C.white, TextSize = 16, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})

	local stockLabel = create("TextLabel", {
		Size = UDim2.new(0, 100, 0, 16), Position = UDim2.new(0, 10, 0, 30),
		BackgroundTransparency = 1, Text = "Stock: 0",
		TextColor3 = C.gray, TextSize = 11, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})

	local priceLabel = create("TextLabel", {
		Size = UDim2.new(0, 130, 0, 22), Position = UDim2.new(0, 120, 0, 6),
		BackgroundTransparency = 1, Text = "Price: 1 coin",
		TextColor3 = C.gold, TextSize = 13, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})

	local multLabel = create("TextLabel", {
		Size = UDim2.new(0, 130, 0, 16), Position = UDim2.new(0, 120, 0, 30),
		BackgroundTransparency = 1, Text = "Market: 100%",
		TextColor3 = C.accent, TextSize = 11, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})

	local sellAllBtn = create("TextButton", {
		Size = UDim2.new(0, 80, 0, 28), Position = UDim2.new(1, -95, 0.5, -14),
		BackgroundColor3 = C.gold, Text = "Sell All",
		TextColor3 = C.bg, TextSize = 13, Font = Enum.Font.GothamBold,
		Parent = card, ZIndex = 96,
	})
	addCorner(sellAllBtn, 6)

	local sell10Btn = create("TextButton", {
		Size = UDim2.new(0, 60, 0, 28), Position = UDim2.new(1, -165, 0.5, -14),
		BackgroundColor3 = C.panelLight, Text = "Sell 10",
		TextColor3 = C.gold, TextSize = 11, Font = Enum.Font.GothamMedium,
		Parent = card, ZIndex = 96,
	})
	addCorner(sell10Btn, 6)
	addStroke(sell10Btn, C.gold, 1)

	sellAllBtn.MouseButton1Click:Connect(function() SellResourceRemote:FireServer(res) end)
	sell10Btn.MouseButton1Click:Connect(function() SellResourceRemote:FireServer(res, 10) end)

	marketCards[res] = { stockLabel = stockLabel, priceLabel = priceLabel, multLabel = multLabel }
end

menuTabPanels["market"] = marketPanel

----------------------------------------------------------------------
--  PROGRESSION PANEL
----------------------------------------------------------------------
local progPanel = create("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4, ScrollBarImageColor3 = C.gray,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Visible = false, Parent = menuContent, ZIndex = 93,
})
addPadding(progPanel, 10)
create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = progPanel })

create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
	Text = "Progression Tree  -  Earn coins to unlock tiers",
	TextColor3 = C.white, TextSize = 17, Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0,
	Parent = progPanel, ZIndex = 94,
})

local totalCoinsLabel = create("TextLabel", {
	Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
	Text = "Total coins earned: 0", TextColor3 = C.gold,
	TextSize = 13, Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1,
	Parent = progPanel, ZIndex = 94,
})

local tierCards = {}
for tier = 0, TreeConfig.MaxTier do
	local info = TreeConfig.ProgressionTiers[tier]

	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = C.panelLight, LayoutOrder = tier + 2,
		Parent = progPanel, ZIndex = 94,
	})
	addCorner(card, 8)

	-- connector
	if tier > 0 then
		create("Frame", {
			Size = UDim2.new(0, 2, 0, 6), Position = UDim2.new(0, 28, 0, -6),
			BackgroundColor3 = C.darkGray, BorderSizePixel = 0,
			Parent = card, ZIndex = 94,
		})
	end

	local badge = create("Frame", {
		Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 8, 0, 16),
		BackgroundColor3 = C.darkGray, Parent = card, ZIndex = 95,
	})
	addCorner(badge, 19)

	local badgeText = create("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		Text = tostring(tier), TextColor3 = C.white,
		TextSize = 18, Font = Enum.Font.GothamBold,
		Parent = badge, ZIndex = 96,
	})

	create("TextLabel", {
		Size = UDim2.new(0, 180, 0, 20), Position = UDim2.new(0, 56, 0, 8),
		BackgroundTransparency = 1, Text = info.name,
		TextColor3 = C.white, TextSize = 15, Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})
	create("TextLabel", {
		Size = UDim2.new(0.45, 0, 0, 16), Position = UDim2.new(0, 56, 0, 28),
		BackgroundTransparency = 1, Text = "Unlocks: " .. info.unlocksText,
		TextColor3 = C.accent, TextSize = 10, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})
	create("TextLabel", {
		Size = UDim2.new(0.45, 0, 0, 14), Position = UDim2.new(0, 56, 0, 44),
		BackgroundTransparency = 1, Text = "Slots: " .. info.slotsGranted,
		TextColor3 = C.gray, TextSize = 10, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = card, ZIndex = 95,
	})

	local reqLabel = create("TextLabel", {
		Size = UDim2.new(0, 150, 0, 18), Position = UDim2.new(1, -160, 0, 8),
		BackgroundTransparency = 1,
		Text = if tier == 0 then "Unlocked" else info.coinsRequired .. " coins",
		TextColor3 = if tier == 0 then C.accent else C.gold,
		TextSize = 13, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Right, Parent = card, ZIndex = 95,
	})

	local barBg = create("Frame", {
		Size = UDim2.new(0, 140, 0, 8), Position = UDim2.new(1, -152, 0, 32),
		BackgroundColor3 = C.darkGray, Parent = card, ZIndex = 95,
	})
	addCorner(barBg, 4)

	local barFill = create("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = C.accent, Parent = barBg, ZIndex = 96,
	})
	addCorner(barFill, 4)

	local statusLabel = create("TextLabel", {
		Size = UDim2.new(0, 140, 0, 14), Position = UDim2.new(1, -152, 0, 44),
		BackgroundTransparency = 1, Text = "",
		TextColor3 = C.gray, TextSize = 10, Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right, Parent = card, ZIndex = 95,
	})

	tierCards[tier] = {
		card = card, badge = badge, badgeText = badgeText,
		reqLabel = reqLabel, barFill = barFill, statusLabel = statusLabel,
	}
end

menuTabPanels["progression"] = progPanel

----------------------------------------------------------------------
-- Menu tab switching
----------------------------------------------------------------------
local function switchMenuTab(tabId: string)
	currentTab = tabId
	for id, btn in menuTabBtns do
		btn.BackgroundColor3 = if id == tabId then C.panelLight else C.bg
		btn.TextColor3 = if id == tabId then C.accent else C.gray
	end
	for id, panel in menuTabPanels do
		panel.Visible = (id == tabId)
	end
end

for _, tab in menuTabs do
	menuTabBtns[tab.id].MouseButton1Click:Connect(function()
		switchMenuTab(tab.id)
	end)
end

----------------------------------------------------------------------
-- Menu open/close
----------------------------------------------------------------------
local function toggleMenu()
	menuOpen = not menuOpen
	menuOverlay.Visible = menuOpen
	menuBtn.Text = if menuOpen then "Close" else "Menu"
	menuBtn.BackgroundColor3 = if menuOpen then C.red else C.panel
end

menuBtn.MouseButton1Click:Connect(toggleMenu)
closeMenuBtn.MouseButton1Click:Connect(function()
	menuOpen = false
	menuOverlay.Visible = false
	menuBtn.Text = "Menu"
	menuBtn.BackgroundColor3 = C.panel
end)

-- Also close menu on clicking the dark overlay background
menuOverlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Only close if click is on the overlay itself, not the panel
		local mouse = UserInputService:GetMouseLocation()
		local panelAbsPos = menuPanel.AbsolutePosition
		local panelAbsSize = menuPanel.AbsoluteSize
		if mouse.X < panelAbsPos.X or mouse.X > panelAbsPos.X + panelAbsSize.X
			or mouse.Y < panelAbsPos.Y or mouse.Y > panelAbsPos.Y + panelAbsSize.Y then
			menuOpen = false
			menuOverlay.Visible = false
			menuBtn.Text = "Menu"
			menuBtn.BackgroundColor3 = C.panel
		end
	end
end)

-- Keyboard shortcut: M to toggle menu
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.M then
		toggleMenu()
	end
end)

----------------------------------------------------------------------
-- ============  UPDATE HUD & MENU FROM DATA  ============
----------------------------------------------------------------------
local function updateUI()
	if not cachedData then return end
	local data = cachedData

	-- HUD
	coinsLabel.Text = "Coins: " .. tostring(data.coins)
	local tierInfo = TreeConfig.ProgressionTiers[data.tier]
	tierLabel.Text = string.format("Tier %d - %s  |  Trees: %d  |  Slots: %d",
		data.tier, tierInfo and tierInfo.name or "?",
		#data.trees, data.maxSlots)

	for res, lbl in resourceLabels do
		lbl.Text = tostring(data.resources[res] or 0)
	end

	-- Shop
	for treeId, sc in shopCards do
		local treeCfg = TreeConfig.Trees[treeId]
		if treeCfg then
			sc.lockOverlay.Visible = (data.tier < treeCfg.unlockTier)
			sc.buyBtn.BackgroundColor3 = if data.coins >= treeCfg.cost then C.accent else C.darkGray
		end
	end

	-- Market stocks
	for res, mc in marketCards do
		mc.stockLabel.Text = "Stock: " .. tostring(data.resources[res] or 0)
	end

	-- Progression
	totalCoinsLabel.Text = "Total coins earned: " .. tostring(data.totalCoinsEarned)
	for tier = 0, TreeConfig.MaxTier do
		local tc = tierCards[tier]
		local info = TreeConfig.ProgressionTiers[tier]
		if not tc or not info then continue end

		local unlocked = data.tier >= tier
		local progress = math.clamp(data.totalCoinsEarned / math.max(1, info.coinsRequired), 0, 1)
		if tier == 0 then progress = 1 end

		tc.badge.BackgroundColor3 = if unlocked then C.accent else C.darkGray
		tc.badgeText.TextColor3 = if unlocked then C.bg else C.gray

		if unlocked then
			local stroke = tc.card:FindFirstChildOfClass("UIStroke")
			if not stroke then addStroke(tc.card, C.accent, 1)
			else stroke.Color = C.accent end
		end

		tc.barFill.Size = UDim2.new(math.max(0.01, progress), 0, 1, 0)
		tc.barFill.BackgroundColor3 = if unlocked then C.accent else C.blue

		if unlocked then
			tc.reqLabel.Text = "Unlocked"
			tc.reqLabel.TextColor3 = C.accent
			tc.statusLabel.Text = ""
		else
			tc.reqLabel.Text = info.coinsRequired .. " coins"
			tc.reqLabel.TextColor3 = C.gold
			tc.statusLabel.Text = string.format("%d / %d", data.totalCoinsEarned, info.coinsRequired)
		end
	end
end

----------------------------------------------------------------------
-- Market price refresh
----------------------------------------------------------------------
local function refreshMarketPrices()
	local ok, prices = pcall(function() return GetMarketFunc:InvokeServer() end)
	if not ok or not prices then return end

	for res, info in prices do
		local mc = marketCards[res]
		if mc then
			mc.priceLabel.Text = string.format("Price: %d coin%s", info.effective, if info.effective ~= 1 then "s" else "")
			mc.multLabel.Text = string.format("Market: %d%%", info.multiplier * 100)
			if info.multiplier < 0.7 then mc.multLabel.TextColor3 = C.red
			elseif info.multiplier < 0.9 then mc.multLabel.TextColor3 = C.orange
			elseif info.multiplier > 1.1 then mc.multLabel.TextColor3 = C.accent
			else mc.multLabel.TextColor3 = C.gray end
		end
	end
end

----------------------------------------------------------------------
-- Data handler
----------------------------------------------------------------------
UpdateDataEvent.OnClientEvent:Connect(function(data)
	cachedData = data
	updateUI()
end)

----------------------------------------------------------------------
-- Initial load
----------------------------------------------------------------------
task.spawn(function()
	cachedData = GetDataFunc:InvokeServer()
	updateUI()
end)

----------------------------------------------------------------------
-- Periodic refreshes
----------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(4)
		refreshMarketPrices()
	end
end)

print("[Client] Idle Gem-Tree Game loaded!")
