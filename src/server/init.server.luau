--[[
	Idle Gem-Tree Game – Server
	Creates 3D trees in the world. Handles data, growth, economics, progression.
]]

----------------------------------------------------------------------
-- Services
----------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local Workspace          = game:GetService("Workspace")

----------------------------------------------------------------------
-- Shared config
----------------------------------------------------------------------
local TreeConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TreeConfig"))

----------------------------------------------------------------------
-- Remote Events / Functions
----------------------------------------------------------------------
local RemotesFolder = Instance.new("Folder")
RemotesFolder.Name = "Remotes"
RemotesFolder.Parent = ReplicatedStorage

local function makeRemote(className: string, name: string): Instance
	local r = Instance.new(className)
	r.Name = name
	r.Parent = RemotesFolder
	return r
end

-- Client -> Server
local PlantTreeEvent    = makeRemote("RemoteEvent",    "PlantTree")
local WaterTreeEvent    = makeRemote("RemoteEvent",    "WaterTree")
local SellResourceEvent = makeRemote("RemoteEvent",    "SellResource")
local ReviveTreeEvent   = makeRemote("RemoteEvent",    "ReviveTree")
local CollectAllEvent   = makeRemote("RemoteEvent",    "CollectAll")
local GetDataFunc       = makeRemote("RemoteFunction", "GetPlayerData")
local GetMarketFunc     = makeRemote("RemoteFunction", "GetMarketPrices")
local EquipCosmeticFunc = makeRemote("RemoteFunction", "EquipCosmetic")
local DequipCosmeticFunc = makeRemote("RemoteFunction", "DequipCosmetic")
local GetWardrobeFunc   = makeRemote("RemoteFunction", "GetWardrobe")

-- Server -> Client
local UpdateDataEvent   = makeRemote("RemoteEvent", "UpdateData")
local FeedbackEvent     = makeRemote("RemoteEvent", "Feedback")
local NotificationEvent = makeRemote("RemoteEvent", "Notification")
local TierUnlockEvent   = makeRemote("RemoteEvent", "TierUnlock")
local FloatingTextEvent = makeRemote("RemoteEvent", "FloatingText") -- 3D floating text

----------------------------------------------------------------------
-- Player data types
----------------------------------------------------------------------
export type TreeInstance = {
	id: string,
	treeType: string,
	slotIndex: number,
	plantedAt: number,
	lastWatered: number,
	lastHarvest: number,
	totalYielded: number,
	withered: boolean,
	dead: boolean,
}

export type PlayerData = {
	coins: number,
	totalCoinsEarned: number,
	tier: number,
	maxSlots: number,
	resources: { [string]: number },
	trees: { TreeInstance },
	lastLogout: number,
	wardrobe: {
		equipped: { [string]: string },
		owned: { [string]: { string } },
	},
}

local DataStore: { [number]: PlayerData } = {}

----------------------------------------------------------------------
-- 3D Model tracking:  userId -> { slotIndex -> Model }
----------------------------------------------------------------------
local TreeModels: { [number]: { [number]: Model } } = {}
local PlayerPlots: { [number]: Folder } = {}

----------------------------------------------------------------------
-- Offline progression constants
----------------------------------------------------------------------
local OFFLINE_EARNINGS_CAP = 12 * 3600  -- Max 12 hours of offline earnings

----------------------------------------------------------------------
-- Market state
----------------------------------------------------------------------
local MarketPrices: { [string]: number } = {}

local function initMarket()
	for _, res in TreeConfig.ResourceOrder do
		MarketPrices[res] = 1.0
	end
end
initMarket()

local function tickMarket(dt: number)
	local cfg = TreeConfig.MarketConfig
	for res, mult in MarketPrices do
		if mult < 1.0 then
			MarketPrices[res] = math.min(1.0, mult + cfg.recoveryRate * dt)
		elseif mult > 1.0 then
			MarketPrices[res] = math.max(1.0, mult - cfg.recoveryRate * dt * 0.5)
		end
	end
end

local function dropPrice(resource: string, amount: number)
	local cfg = TreeConfig.MarketConfig
	local drop = amount * cfg.dropPerSale
	MarketPrices[resource] = math.max(cfg.minPriceMultiplier, (MarketPrices[resource] or 1) - drop)
	if MarketPrices[resource] < 0.6 then
		for _, p in Players:GetPlayers() do
			NotificationEvent:FireClient(p, string.format(
				TreeConfig.FeedbackMessages.marketCrash, resource
			), "warn")
		end
	end
end

----------------------------------------------------------------------
-- 3D TREE BUILDING
----------------------------------------------------------------------
local function getSlotPosition(slotIndex: number): Vector3
	local col = (slotIndex - 1) % TreeConfig.GridColumns
	local row = math.floor((slotIndex - 1) / TreeConfig.GridColumns)
	local spacing = TreeConfig.GridSpacing
	local origin = TreeConfig.PlotOrigin
	return Vector3.new(
		origin.X + col * spacing - (TreeConfig.GridColumns - 1) * spacing * 0.5,
		origin.Y,
		origin.Z + row * spacing + 10
	)
end

local function createTreeModel(treeData: TreeInstance, plotFolder: Folder): Model
	local cfg = TreeConfig.Trees[treeData.treeType]
	if not cfg then return nil end

	local pos = getSlotPosition(treeData.slotIndex)
	local trunkH = cfg.trunkHeight
	local canopyS = cfg.canopySize

	-- Model
	local model = Instance.new("Model")
	model.Name = treeData.id

	-- Trunk (cylinder)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(trunkH, 2, 2)
	trunk.CFrame = CFrame.new(pos + Vector3.new(0, trunkH / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Color = Color3.fromRGB(cfg.trunkColor[1], cfg.trunkColor[2], cfg.trunkColor[3])
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.Parent = model

	-- Canopy (ball)
	local canopy = Instance.new("Part")
	canopy.Name = "Canopy"
	canopy.Shape = Enum.PartType.Ball
	canopy.Size = Vector3.new(canopyS, canopyS, canopyS)
	canopy.Position = pos + Vector3.new(0, trunkH + canopyS * 0.35, 0)
	canopy.Color = Color3.fromRGB(cfg.leafColor[1], cfg.leafColor[2], cfg.leafColor[3])
	canopy.Material = Enum.Material.Grass
	canopy.Anchored = true
	canopy.CanCollide = false
	canopy.Parent = model

	model.PrimaryPart = trunk

	-- BillboardGui above canopy
	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "TreeInfo"
	bbGui.Size = UDim2.new(0, 200, 0, 80)
	bbGui.StudsOffset = Vector3.new(0, canopyS * 0.5 + 2, 0)
	bbGui.AlwaysOnTop = true
	bbGui.Adornee = canopy
	bbGui.Parent = canopy

	-- Tree name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "TreeName"
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = cfg.icon .. " " .. cfg.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = bbGui

	-- Status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Size = UDim2.new(1, 0, 0, 16)
	statusLabel.Position = UDim2.new(0, 0, 0, 22)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Healthy"
	statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
	statusLabel.TextStrokeTransparency = 0.5
	statusLabel.TextSize = 13
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.Parent = bbGui

	-- Water bar background
	local barBg = Instance.new("Frame")
	barBg.Name = "WaterBarBg"
	barBg.Size = UDim2.new(0.7, 0, 0, 6)
	barBg.Position = UDim2.new(0.15, 0, 0, 42)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	barBg.BorderSizePixel = 0
	barBg.Parent = bbGui
	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0, 3)
	barBgCorner.Parent = barBg

	-- Water bar fill
	local barFill = Instance.new("Frame")
	barFill.Name = "WaterBarFill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(70, 130, 230)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(0, 3)
	barFillCorner.Parent = barFill

	-- Resource production text
	local prodLabel = Instance.new("TextLabel")
	prodLabel.Name = "Production"
	prodLabel.Size = UDim2.new(1, 0, 0, 14)
	prodLabel.Position = UDim2.new(0, 0, 0, 52)
	prodLabel.BackgroundTransparency = 1
	prodLabel.Text = string.format("+%d %s / %ds", cfg.yieldPerCycle, cfg.resourceType, cfg.cycleTime)
	prodLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	prodLabel.TextStrokeTransparency = 0.5
	prodLabel.TextSize = 11
	prodLabel.Font = Enum.Font.Gotham
	prodLabel.Parent = bbGui

	-- ProximityPrompt for interaction
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TreePrompt"
	prompt.ActionText = "Water"
	prompt.ObjectText = cfg.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = trunk

	-- Store tree data id as attribute
	trunk:SetAttribute("TreeId", treeData.id)
	trunk:SetAttribute("OwnerId", 0) -- set later

	model.Parent = plotFolder
	return model
end

local function updateTreeAppearance(model: Model, treeData: TreeInstance)
	if not model then return end
	local cfg = TreeConfig.Trees[treeData.treeType]
	if not cfg then return end

	local canopy = model:FindFirstChild("Canopy")
	local trunk = model:FindFirstChild("Trunk")
	if not canopy or not trunk then return end

	local bbGui = canopy:FindFirstChild("TreeInfo")

	-- Colors based on state
	if treeData.dead then
		canopy.Color = Color3.fromRGB(60, 50, 50)
		canopy.Material = Enum.Material.Slate
		canopy.Transparency = 0.4
		trunk.Color = Color3.fromRGB(50, 40, 35)
		if bbGui then
			local sl = bbGui:FindFirstChild("Status")
			if sl then sl.Text = "DEAD"; sl.TextColor3 = Color3.fromRGB(220, 50, 50) end
			local prod = bbGui:FindFirstChild("Production")
			if prod then prod.Text = "Not producing" end
		end
		-- Update prompt
		local prompt = trunk:FindFirstChild("TreePrompt")
		if prompt then
			prompt.ActionText = "Revive"
			local cost = math.floor(cfg.cost * 0.5)
			prompt.ObjectText = cfg.name .. " (" .. cost .. " coins)"
		end
	elseif treeData.withered then
		canopy.Color = Color3.fromRGB(160, 140, 50)
		canopy.Material = Enum.Material.Grass
		canopy.Transparency = 0.15
		trunk.Color = Color3.fromRGB(cfg.trunkColor[1], cfg.trunkColor[2], cfg.trunkColor[3])
		if bbGui then
			local sl = bbGui:FindFirstChild("Status")
			if sl then sl.Text = "WITHERING!"; sl.TextColor3 = Color3.fromRGB(255, 165, 0) end
			local prod = bbGui:FindFirstChild("Production")
			if prod then prod.Text = "Not producing (wither)" end
		end
		local prompt = trunk:FindFirstChild("TreePrompt")
		if prompt then prompt.ActionText = "Water NOW!"; prompt.ObjectText = cfg.name end
	else
		canopy.Color = Color3.fromRGB(cfg.leafColor[1], cfg.leafColor[2], cfg.leafColor[3])
		canopy.Material = Enum.Material.Grass
		canopy.Transparency = 0
		trunk.Color = Color3.fromRGB(cfg.trunkColor[1], cfg.trunkColor[2], cfg.trunkColor[3])
		if bbGui then
			local sl = bbGui:FindFirstChild("Status")
			if sl then sl.Text = "Healthy"; sl.TextColor3 = Color3.fromRGB(80, 200, 120) end
			local prod = bbGui:FindFirstChild("Production")
			if prod then prod.Text = string.format("+%d %s / %ds", cfg.yieldPerCycle, cfg.resourceType, cfg.cycleTime) end
		end
		local prompt = trunk:FindFirstChild("TreePrompt")
		if prompt then prompt.ActionText = "Water"; prompt.ObjectText = cfg.name end
	end

	-- Water bar
	if bbGui then
		local barBg = bbGui:FindFirstChild("WaterBarBg")
		if barBg then
			local barFill = barBg:FindFirstChild("WaterBarFill")
			if barFill then
				if treeData.dead then
					barFill.Size = UDim2.new(0, 0, 1, 0)
					barFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
				else
					local now = os.clock()
					local elapsed = now - treeData.lastWatered
					local pct = math.clamp(1 - elapsed / cfg.withersAfter, 0, 1)
					barFill.Size = UDim2.new(math.max(0.01, pct), 0, 1, 0)
					if pct > 0.4 then
						barFill.BackgroundColor3 = Color3.fromRGB(70, 130, 230)
					elseif pct > 0.15 then
						barFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
					else
						barFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
					end
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- Find next free slot index for a player
----------------------------------------------------------------------
local function getNextSlotIndex(data: PlayerData): number?
	local usedSlots = {}
	for _, t in data.trees do
		usedSlots[t.slotIndex] = true
	end
	for i = 1, data.maxSlots do
		if not usedSlots[i] then return i end
	end
	return nil
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function sendData(player: Player)
	local data = DataStore[player.UserId]
	if data then
		UpdateDataEvent:FireClient(player, data)
	end
end

local function checkTierUp(player: Player)
	local data = DataStore[player.UserId]
	if not data then return end
	local nextTier = data.tier + 1
	local info = TreeConfig.ProgressionTiers[nextTier]
	if info and data.totalCoinsEarned >= info.coinsRequired then
		data.tier = nextTier
		data.maxSlots = info.slotsGranted
		
		-- All cosmetics are now available from the start, so no need to unlock by tier
		
		TierUnlockEvent:FireClient(player, nextTier, info.name, info.unlocksText)
		NotificationEvent:FireClient(player, string.format(
			TreeConfig.FeedbackMessages.tierUnlocked, nextTier, info.unlocksText
		), "success")
		checkTierUp(player)
	end
end

----------------------------------------------------------------------
-- Spawn a player's plot with all their trees
----------------------------------------------------------------------
local function buildPlayerPlot(player: Player)
	local data = DataStore[player.UserId]
	if not data then return end

	-- Clean up old plot
	if PlayerPlots[player.UserId] then
		PlayerPlots[player.UserId]:Destroy()
	end

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plot_" .. player.Name
	plotFolder.Parent = Workspace

	PlayerPlots[player.UserId] = plotFolder
	TreeModels[player.UserId] = {}

	-- Create ground plot
	local plotSize = TreeConfig.GridColumns * TreeConfig.GridSpacing + 8
	local maxRows = math.ceil(12 / TreeConfig.GridColumns)
	local plotDepth = maxRows * TreeConfig.GridSpacing + 16

	local ground = Instance.new("Part")
	ground.Name = "PlotGround"
	ground.Size = Vector3.new(plotSize, 1, plotDepth)
	ground.Position = Vector3.new(TreeConfig.PlotOrigin.X, -0.5, TreeConfig.PlotOrigin.Z + plotDepth / 2 - 4)
	ground.Color = Color3.fromRGB(76, 153, 0)
	ground.Material = Enum.Material.Grass
	ground.Anchored = true
	ground.CanCollide = true
	ground.Parent = plotFolder

	-- Build 3D tree for each existing tree
	for _, tree in data.trees do
		local model = createTreeModel(tree, plotFolder)
		if model then
			local trunk = model:FindFirstChild("Trunk")
			if trunk then trunk:SetAttribute("OwnerId", player.UserId) end
			TreeModels[player.UserId][tree.slotIndex] = model
			updateTreeAppearance(model, tree)
		end
	end
end

----------------------------------------------------------------------
-- Player init / cleanup
----------------------------------------------------------------------
----------------------------------------------------------------------
-- Initialize wardrobe for a player - grant basic clothing items
----------------------------------------------------------------------
local function initializeWardrobe(data: PlayerData)
	if not data.wardrobe then
		data.wardrobe = {
			equipped = {
				-- Start with nil - show default Roblox clothing
				shirt = nil,
				pants = nil,
			},
			owned = {},
		}
	end

	-- Ensure owned structure exists for all categories
	for _, category in TreeConfig.CosmeticCategories do
		if not data.wardrobe.owned[category] then
			data.wardrobe.owned[category] = {}
		end
	end

	-- Unlock ALL clothing items for player (classic clothing is always available)
	for cosmeticId, cosmetic in TreeConfig.Cosmetics do
		local owned = data.wardrobe.owned[cosmetic.category]
		local alreadyHas = false
		for _, id in owned do
			if id == cosmeticId then
				alreadyHas = true
				break
			end
		end
		if not alreadyHas then
			table.insert(owned, cosmeticId)
		end
	end
end

local function initPlayer(player: Player)
	local startTier = TreeConfig.ProgressionTiers[0]
	local data: PlayerData = {
		coins            = 50,
		totalCoinsEarned = 50,
		tier             = 0,
		maxSlots         = startTier.slotsGranted,
		resources        = {},
		trees            = {},
		lastLogout       = 0,
		wardrobe         = {
			equipped = {},
			owned = {},
		},
	}

	for _, res in TreeConfig.ResourceOrder do
		data.resources[res] = 0
	end

	-- Initialize wardrobe
	initializeWardrobe(data)

	-- Free starter tree at slot 1
	table.insert(data.trees, {
		id          = "BasicTree_starter",
		treeType    = "BasicTree",
		slotIndex   = 1,
		plantedAt   = os.clock(),
		lastWatered = os.clock(),
		lastHarvest = os.clock(),
		totalYielded = 0,
		withered    = false,
		dead        = false,
	})

	data.lastLogout = 0
	DataStore[player.UserId] = data
	buildPlayerPlot(player)
	sendData(player)
end

----------------------------------------------------------------------
-- Calculate offline earnings from last logout
----------------------------------------------------------------------
local function processOfflineEarnings(data: PlayerData)
	if data.lastLogout == 0 then return {} end  -- Never logged out before

	local now = os.clock()
	local elapsedTime = now - data.lastLogout
	if elapsedTime <= 0 then return {} end

	local maxTime = OFFLINE_EARNINGS_CAP
	local actualTime = math.min(elapsedTime, maxTime)

	local offlineCollected = {}  -- Track what was earned offline

	for _, tree in data.trees do
		if tree.dead or tree.withered then continue end
		local cfg = TreeConfig.Trees[tree.treeType]
		if not cfg then continue end

		-- Calculate production cycles during offline time
		local cycles = math.floor(actualTime / cfg.cycleTime)
		if cycles > 0 then
			local yield = cycles * cfg.yieldPerCycle
			data.resources[cfg.resourceType] = (data.resources[cfg.resourceType] or 0) + yield
			tree.totalYielded += yield
			offlineCollected[cfg.resourceType] = (offlineCollected[cfg.resourceType] or 0) + yield
			-- Reset harvest timer to now
			tree.lastHarvest = now
		end
	end

	return offlineCollected
end

Players.PlayerAdded:Connect(function(player)
	-- Check if player data exists
	if not DataStore[player.UserId] then
		initPlayer(player)
	else
		-- Existing player - ensure wardrobe is initialized
		local data = DataStore[player.UserId]
		initializeWardrobe(data)
	end
	-- Process offline earnings
	local data = DataStore[player.UserId]
	if data then
		local offlineCollected = processOfflineEarnings(data)
		if next(offlineCollected) then
			-- Show notification for each resource earned offline
			for res, amt in offlineCollected do
				NotificationEvent:FireClient(player, string.format(
					"Offline bonus: +%d %s", amt, res
				), "success")
			end
		end
		sendData(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local data = DataStore[player.UserId]
	if data then
		data.lastLogout = os.clock()
	end
	if PlayerPlots[player.UserId] then
		PlayerPlots[player.UserId]:Destroy()
		PlayerPlots[player.UserId] = nil
	end
	TreeModels[player.UserId] = nil
end)

for _, p in Players:GetPlayers() do
	if not DataStore[p.UserId] then
		initPlayer(p)
	end
	-- Ensure wardrobe is initialized
	local data = DataStore[p.UserId]
	if data then
		initializeWardrobe(data)
		local offlineCollected = processOfflineEarnings(data)
		if next(offlineCollected) then
			for res, amt in offlineCollected do
				NotificationEvent:FireClient(p, string.format(
					"Offline bonus: +%d %s", amt, res
				), "success")
			end
		end
	end
end

----------------------------------------------------------------------
-- ProximityPrompt handler (water / revive when clicked)
----------------------------------------------------------------------
local function onPromptTriggered(prompt: ProximityPrompt, triggerPlayer: Player)
	local trunk = prompt.Parent
	if not trunk then return end
	local ownerId = trunk:GetAttribute("OwnerId")
	local treeId = trunk:GetAttribute("TreeId")
	if not ownerId or not treeId then return end
	if triggerPlayer.UserId ~= ownerId then return end -- only owner

	local data = DataStore[ownerId]
	if not data then return end

	for _, tree in data.trees do
		if tree.id == treeId then
			local cfg = TreeConfig.Trees[tree.treeType]
			if not cfg then return end

			if tree.dead then
				-- Revive
				local cost = math.floor(cfg.cost * 0.5)
				if data.coins < cost then
					FeedbackEvent:FireClient(triggerPlayer, TreeConfig.FeedbackMessages.notEnoughCoins, "error")
					return
				end
				data.coins -= cost
				tree.dead = false
				tree.withered = false
				tree.lastWatered = os.clock()
				tree.lastHarvest = os.clock()
				FeedbackEvent:FireClient(triggerPlayer, string.format(
					TreeConfig.FeedbackMessages.revived, cfg.name
				), "success")
			else
				-- Water
				local elapsed = os.clock() - tree.lastWatered
				if elapsed < TreeConfig.WateringCooldown and not tree.withered then
					FeedbackEvent:FireClient(triggerPlayer, TreeConfig.FeedbackMessages.alreadyWatered, "info")
					return
				end
				tree.lastWatered = os.clock()
				if tree.withered then
					tree.withered = false
					FeedbackEvent:FireClient(triggerPlayer, string.format(
						TreeConfig.FeedbackMessages.revived, cfg.name
					), "success")
				else
					FeedbackEvent:FireClient(triggerPlayer, string.format(
						TreeConfig.FeedbackMessages.treeWatered, cfg.name
					), "success")
				end
			end

			-- Update 3D model
			local models = TreeModels[ownerId]
			if models and models[tree.slotIndex] then
				updateTreeAppearance(models[tree.slotIndex], tree)
			end
			sendData(triggerPlayer)
			return
		end
	end
end

-- Listen to ALL proximity prompts in workspace
Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("ProximityPrompt") and desc.Name == "TreePrompt" then
		desc.Triggered:Connect(function(plr)
			onPromptTriggered(desc, plr)
		end)
	end
end)
-- Also connect existing
for _, desc in Workspace:GetDescendants() do
	if desc:IsA("ProximityPrompt") and desc.Name == "TreePrompt" then
		desc.Triggered:Connect(function(plr)
			onPromptTriggered(desc, plr)
		end)
	end
end

----------------------------------------------------------------------
-- Remote: GetPlayerData / GetMarketPrices / Wardrobe
----------------------------------------------------------------------
GetDataFunc.OnServerInvoke = function(player)
	return DataStore[player.UserId]
end

GetMarketFunc.OnServerInvoke = function(_player)
	local prices = {}
	for res, mult in MarketPrices do
		local base = TreeConfig.ResourceValues[res] or 1
		prices[res] = {
			base       = base,
			multiplier = math.floor(mult * 100 + 0.5) / 100,
			effective  = math.floor(base * mult + 0.5),
		}
	end
	return prices
end

GetWardrobeFunc.OnServerInvoke = function(player)
	local data = DataStore[player.UserId]
	if not data then return nil end
	return data.wardrobe
end

EquipCosmeticFunc.OnServerInvoke = function(player, category: string, cosmeticId: string)
	local data = DataStore[player.UserId]
	if not data then return false end
	
	-- Verify player owns this cosmetic
	local owned = data.wardrobe.owned[category]
	if not owned then return false end
	
	local hasCosmetic = false
	for _, id in owned do
		if id == cosmeticId then
			hasCosmetic = true
			break
		end
	end
	
	if not hasCosmetic then return false end
	
	-- Equip it
	data.wardrobe.equipped[category] = cosmeticId
	local cosmetic = TreeConfig.Cosmetics[cosmeticId]
	if cosmetic then
		NotificationEvent:FireClient(player, string.format(
			TreeConfig.FeedbackMessages.cosmeticEquipped, cosmetic.name
		), "success")
	end
	sendData(player)
	return true
end

DequipCosmeticFunc.OnServerInvoke = function(player, category: string)
	local data = DataStore[player.UserId]
	if not data then return false end
	
	-- Remove equipped item (set to nil/empty)
	data.wardrobe.equipped[category] = nil
	NotificationEvent:FireClient(player, "Clothing removed", "info")
	sendData(player)
	return true
end

----------------------------------------------------------------------
-- Remote: PlantTree
----------------------------------------------------------------------
PlantTreeEvent.OnServerEvent:Connect(function(player, treeTypeId: string)
	local data = DataStore[player.UserId]
	if not data then return end

	local treeCfg = TreeConfig.Trees[treeTypeId]
	if not treeCfg then return end

	if data.tier < treeCfg.unlockTier then
		FeedbackEvent:FireClient(player, string.format(
			TreeConfig.FeedbackMessages.notUnlocked, treeCfg.unlockTier
		), "error")
		return
	end

	local slotIndex = getNextSlotIndex(data)
	if not slotIndex then
		FeedbackEvent:FireClient(player, TreeConfig.FeedbackMessages.slotsFull, "error")
		return
	end

	if data.coins < treeCfg.cost then
		FeedbackEvent:FireClient(player, TreeConfig.FeedbackMessages.notEnoughCoins, "error")
		return
	end

	data.coins -= treeCfg.cost
	local newTree: TreeInstance = {
		id          = treeTypeId .. "_" .. tostring(os.clock()) .. "_" .. tostring(math.random(1000, 9999)),
		treeType    = treeTypeId,
		slotIndex   = slotIndex,
		plantedAt   = os.clock(),
		lastWatered = os.clock(),
		lastHarvest = os.clock(),
		totalYielded = 0,
		withered    = false,
		dead        = false,
	}
	table.insert(data.trees, newTree)

	-- Create 3D model
	local plotFolder = PlayerPlots[player.UserId]
	if plotFolder then
		local model = createTreeModel(newTree, plotFolder)
		if model then
			local trunk = model:FindFirstChild("Trunk")
			if trunk then trunk:SetAttribute("OwnerId", player.UserId) end
			if not TreeModels[player.UserId] then TreeModels[player.UserId] = {} end
			TreeModels[player.UserId][slotIndex] = model
		end
	end

	FeedbackEvent:FireClient(player, string.format(
		TreeConfig.FeedbackMessages.treePlanted, treeCfg.name
	), "success")
	sendData(player)
end)

----------------------------------------------------------------------
-- Remote: WaterTree (from menu – also works, but prompt is primary)
----------------------------------------------------------------------
WaterTreeEvent.OnServerEvent:Connect(function(player, treeId: string)
	local data = DataStore[player.UserId]
	if not data then return end

	for _, tree in data.trees do
		if tree.id == treeId then
			if tree.dead then
				FeedbackEvent:FireClient(player, "This tree is dead. Walk to it and revive!", "error")
				return
			end
			local elapsed = os.clock() - tree.lastWatered
			if elapsed < TreeConfig.WateringCooldown and not tree.withered then
				FeedbackEvent:FireClient(player, TreeConfig.FeedbackMessages.alreadyWatered, "info")
				return
			end
			tree.lastWatered = os.clock()
			local cfg = TreeConfig.Trees[tree.treeType]
			if tree.withered then
				tree.withered = false
				FeedbackEvent:FireClient(player, string.format(
					TreeConfig.FeedbackMessages.revived, cfg and cfg.name or "Tree"
				), "success")
			else
				FeedbackEvent:FireClient(player, string.format(
					TreeConfig.FeedbackMessages.treeWatered, cfg and cfg.name or "Tree"
				), "success")
			end
			-- Update 3D
			local models = TreeModels[player.UserId]
			if models and models[tree.slotIndex] then
				updateTreeAppearance(models[tree.slotIndex], tree)
			end
			sendData(player)
			return
		end
	end
end)

----------------------------------------------------------------------
-- Remote: ReviveTree
----------------------------------------------------------------------
ReviveTreeEvent.OnServerEvent:Connect(function(player, treeId: string)
	local data = DataStore[player.UserId]
	if not data then return end

	for _, tree in data.trees do
		if tree.id == treeId and tree.dead then
			local cfg = TreeConfig.Trees[tree.treeType]
			if not cfg then return end
			local cost = math.floor(cfg.cost * 0.5)
			if data.coins < cost then
				FeedbackEvent:FireClient(player, TreeConfig.FeedbackMessages.notEnoughCoins, "error")
				return
			end
			data.coins -= cost
			tree.dead = false
			tree.withered = false
			tree.lastWatered = os.clock()
			tree.lastHarvest = os.clock()
			FeedbackEvent:FireClient(player, string.format(
				TreeConfig.FeedbackMessages.revived, cfg.name
			), "success")
			-- Update 3D
			local models = TreeModels[player.UserId]
			if models and models[tree.slotIndex] then
				updateTreeAppearance(models[tree.slotIndex], tree)
			end
			sendData(player)
			return
		end
	end
end)

----------------------------------------------------------------------
-- Remote: SellResource
----------------------------------------------------------------------
SellResourceEvent.OnServerEvent:Connect(function(player, resource: string, amount: number?)
	local data = DataStore[player.UserId]
	if not data then return end
	if not TreeConfig.ResourceValues[resource] then return end

	local available = data.resources[resource] or 0
	local toSell = math.min(available, amount or available)
	if toSell <= 0 then
		FeedbackEvent:FireClient(player, string.format(
			TreeConfig.FeedbackMessages.noResources, resource
		), "error")
		return
	end

	local baseValue = TreeConfig.ResourceValues[resource]
	local mult = MarketPrices[resource] or 1
	local totalValue = math.floor(toSell * baseValue * mult + 0.5)

	data.resources[resource] -= toSell
	data.coins += totalValue
	data.totalCoinsEarned += totalValue

	dropPrice(resource, toSell)

	FeedbackEvent:FireClient(player, string.format(
		TreeConfig.FeedbackMessages.soldResources, toSell, resource, totalValue
	), "coins")

	checkTierUp(player)
	sendData(player)
end)

----------------------------------------------------------------------
-- Remote: CollectAll
----------------------------------------------------------------------
CollectAllEvent.OnServerEvent:Connect(function(player)
	local data = DataStore[player.UserId]
	if not data then return end
	local now = os.clock()
	local totalCollected = {}
	for _, tree in data.trees do
		if tree.dead or tree.withered then continue end
		local cfg = TreeConfig.Trees[tree.treeType]
		if not cfg then continue end
		local elapsed = now - tree.lastHarvest
		local cycles = math.floor(elapsed / cfg.cycleTime)
		if cycles > 0 then
			local yield = cycles * cfg.yieldPerCycle
			data.resources[cfg.resourceType] = (data.resources[cfg.resourceType] or 0) + yield
			tree.lastHarvest = now
			tree.totalYielded += yield
			totalCollected[cfg.resourceType] = (totalCollected[cfg.resourceType] or 0) + yield
		end
	end

	for res, amt in totalCollected do
		FeedbackEvent:FireClient(player, string.format("+%d %s", amt, res), "resource")
	end
	sendData(player)
end)

----------------------------------------------------------------------
-- Main game loop
----------------------------------------------------------------------
local TICK_INTERVAL = 1.0
local accumulator = 0

RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	tickMarket(dt)

	if accumulator < TICK_INTERVAL then return end
	accumulator -= TICK_INTERVAL

	local now = os.clock()

	for _, player in Players:GetPlayers() do
		local data = DataStore[player.UserId]
		if not data then continue end

		local changed = false
		local witherWarnings = {}
		local deathNotices = {}

		for _, tree in data.trees do
			if tree.dead then continue end

			local cfg = TreeConfig.Trees[tree.treeType]
			if not cfg then continue end

			local sinceWatered = now - tree.lastWatered

			-- Wither
			if not tree.withered and sinceWatered >= cfg.withersAfter then
				tree.withered = true
				changed = true
				table.insert(witherWarnings, cfg.name)
			end

			-- Death
			if sinceWatered >= cfg.diesAfter then
				tree.dead = true
				changed = true
				table.insert(deathNotices, cfg.name)
			end

			-- Production (alive + not withered)
			if not tree.withered and not tree.dead then
				local elapsed = now - tree.lastHarvest
				local cycles = math.floor(elapsed / cfg.cycleTime)
				if cycles > 0 then
					local yield = cycles * cfg.yieldPerCycle
					data.resources[cfg.resourceType] = (data.resources[cfg.resourceType] or 0) + yield
					tree.lastHarvest = now
					tree.totalYielded += yield
					changed = true

					-- Send 3D floating text above tree
					local models = TreeModels[player.UserId]
					if models and models[tree.slotIndex] then
						local canopy = models[tree.slotIndex]:FindFirstChild("Canopy")
						if canopy then
							FloatingTextEvent:FireClient(player,
								string.format("+%d %s", yield, cfg.resourceType),
								canopy.Position + Vector3.new(0, 4, 0),
								{ cfg.resourceColor[1], cfg.resourceColor[2], cfg.resourceColor[3] }
							)
						end
					end
				end
			end

			-- Always update 3D appearance (water bar etc.)
			local models = TreeModels[player.UserId]
			if models and models[tree.slotIndex] then
				updateTreeAppearance(models[tree.slotIndex], tree)
			end
		end

		for _, name in witherWarnings do
			NotificationEvent:FireClient(player, string.format(
				TreeConfig.FeedbackMessages.treeWithering, name
			), "warn")
		end

		for _, name in deathNotices do
			NotificationEvent:FireClient(player, string.format(
				TreeConfig.FeedbackMessages.treeDied, name
			), "error")
		end

		if changed then
			sendData(player)
		end
	end
end)

print("[Server] Idle Gem-Tree Game loaded!")
