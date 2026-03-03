--[[
	TreeConfig – shared configuration for the Idle Gem-Tree Game
	Used by both server and client.
	
	TASK 8:  Feedbacks & consequences
	TASK 9:  Economics (supply/demand, taxes, boom/crash)
	TASK 10: Progression – collect resources to buy SEEDS for gem trees
]]

local TreeConfig = {}

--------------------------------------------------------------------------------
-- Tree Definitions  (seedCost = resources needed to BUY the seed)
--------------------------------------------------------------------------------
TreeConfig.Trees = {
	BasicTree = {
		id            = "BasicTree",
		name          = "Basic Tree",
		icon          = "🌱",
		cost          = 0,
		seedCost      = nil,           -- free starter, no seed needed
		resourceType  = "Wood",
		yieldPerCycle = 1,
		cycleTime     = 3,
		unlockTier    = 0,
		description   = "A simple sapling. Produces wood slowly.",
		withersAfter  = 120,
		diesAfter     = 240,
		trunkColor    = { 139, 90, 43 },
		leafColor     = { 34, 139, 34 },
		trunkHeight   = 5,
		canopySize    = 6,
		resourceColor = { 194, 178, 128 },
	},
	OakTree = {
		id            = "OakTree",
		name          = "Oak Tree",
		icon          = "🌳",
		cost          = 100,
		seedCost      = { Wood = 200 },
		resourceType  = "Wood",
		yieldPerCycle = 3,
		cycleTime     = 4,
		unlockTier    = 1,
		description   = "Sturdy oak. Seed: 200 Wood + 100 coins.",
		withersAfter  = 140,
		diesAfter     = 280,
		trunkColor    = { 101, 67, 33 },
		leafColor     = { 85, 107, 47 },
		trunkHeight   = 7,
		canopySize    = 8,
		resourceColor = { 194, 178, 128 },
	},
	AppleTree = {
		id            = "AppleTree",
		name          = "Apple Tree",
		icon          = "🍎",
		cost          = 300,
		seedCost      = { Wood = 500 },
		resourceType  = "Apples",
		yieldPerCycle = 2,
		cycleTime     = 5,
		unlockTier    = 2,
		description   = "Sweet apples! Seed: 500 Wood + 300 coins.",
		withersAfter  = 110,
		diesAfter     = 220,
		trunkColor    = { 120, 80, 40 },
		leafColor     = { 50, 150, 50 },
		trunkHeight   = 6,
		canopySize    = 7,
		resourceColor = { 220, 20, 60 },
	},
	RubyTree = {
		id            = "RubyTree",
		name          = "Ruby Tree",
		icon          = "💎",
		cost          = 800,
		seedCost      = { Wood = 1000, Apples = 200 },
		resourceType  = "Rubies",
		yieldPerCycle = 1,
		cycleTime     = 8,
		unlockTier    = 3,
		description   = "Crystallises rubies! Seed: 1000 Wood + 200 Apples.",
		withersAfter  = 90,
		diesAfter     = 180,
		trunkColor    = { 80, 40, 50 },
		leafColor     = { 224, 17, 95 },
		trunkHeight   = 6,
		canopySize    = 7,
		resourceColor = { 224, 17, 95 },
	},
	OpalTree = {
		id            = "OpalTree",
		name          = "Opal Tree",
		icon          = "🔮",
		cost          = 1200,
		seedCost      = { Wood = 1500, Apples = 300 },
		resourceType  = "Opals",
		yieldPerCycle = 1,
		cycleTime     = 10,
		unlockTier    = 3,
		description   = "Shimmering opals! Seed: 1500 Wood + 300 Apples.",
		withersAfter  = 80,
		diesAfter     = 160,
		trunkColor    = { 100, 80, 120 },
		leafColor     = { 168, 195, 230 },
		trunkHeight   = 6,
		canopySize    = 7,
		resourceColor = { 168, 195, 230 },
	},
	EmeraldTree = {
		id            = "EmeraldTree",
		name          = "Emerald Tree",
		icon          = "💚",
		cost          = 2000,
		seedCost      = { Wood = 2000, Rubies = 100, Opals = 50 },
		resourceType  = "Emeralds",
		yieldPerCycle = 1,
		cycleTime     = 12,
		unlockTier    = 4,
		description   = "Finest emeralds! Seed: 2000 Wood + gems.",
		withersAfter  = 70,
		diesAfter     = 140,
		trunkColor    = { 40, 80, 60 },
		leafColor     = { 0, 168, 107 },
		trunkHeight   = 7,
		canopySize    = 8,
		resourceColor = { 0, 168, 107 },
	},
	DiamondTree = {
		id            = "DiamondTree",
		name          = "Diamond Tree",
		icon          = "💎",
		cost          = 5000,
		seedCost      = { Wood = 2000, Emeralds = 80, Rubies = 150, Opals = 100 },
		resourceType  = "Diamonds",
		yieldPerCycle = 1,
		cycleTime     = 15,
		unlockTier    = 5,
		description   = "Diamonds forever! Massive seed investment.",
		withersAfter  = 60,
		diesAfter     = 120,
		trunkColor    = { 120, 140, 160 },
		leafColor     = { 185, 242, 255 },
		trunkHeight   = 8,
		canopySize    = 9,
		resourceColor = { 185, 242, 255 },
	},
}

-- Ordered list for UI display
TreeConfig.TreeOrder = {
	"BasicTree", "OakTree", "AppleTree",
	"RubyTree", "OpalTree", "EmeraldTree", "DiamondTree",
}

--------------------------------------------------------------------------------
-- Resource base sell values (coins per unit)
--------------------------------------------------------------------------------
TreeConfig.ResourceValues = {
	Wood     = 1,
	Apples   = 5,
	Rubies   = 25,
	Opals    = 35,
	Emeralds = 50,
	Diamonds = 100,
}

TreeConfig.ResourceOrder = { "Wood", "Apples", "Rubies", "Opals", "Emeralds", "Diamonds" }

--------------------------------------------------------------------------------
-- Progression Tiers
--------------------------------------------------------------------------------
TreeConfig.ProgressionTiers = {
	[0] = { name = "Beginner",       coinsRequired = 0,      unlocksText = "Basic Tree",            slotsGranted = 3  },
	[1] = { name = "Apprentice",     coinsRequired = 200,    unlocksText = "Oak Tree seed",         slotsGranted = 4  },
	[2] = { name = "Farmer",         coinsRequired = 800,    unlocksText = "Apple Tree seed",       slotsGranted = 5  },
	[3] = { name = "Gem Collector",  coinsRequired = 2500,   unlocksText = "Ruby & Opal seeds",     slotsGranted = 7  },
	[4] = { name = "Jeweler",        coinsRequired = 6000,   unlocksText = "Emerald Tree seed",     slotsGranted = 9  },
	[5] = { name = "Tycoon",         coinsRequired = 15000,  unlocksText = "Diamond Tree seed",     slotsGranted = 12 },
}

TreeConfig.MaxTier = 5

--------------------------------------------------------------------------------
-- Economics – market config  (supply/demand, taxes, boom/crash)
--------------------------------------------------------------------------------
TreeConfig.MarketConfig = {
	minPriceMultiplier  = 0.25,     -- crash floor: 25%
	maxPriceMultiplier  = 2.0,      -- boom ceiling: 200%
	recoveryRate        = 0.001,    -- slow natural recovery toward 1.0
	dropPerSale         = 0.025,    -- each unit sold pushes price down
	updateInterval      = 5,
	taxRate             = 0.05,     -- 5% tax on all sales (coin sink)
	boomChance          = 0.008,    -- per-tick chance of random boom
	boomMultiplier      = 1.4,      -- boom pushes price up
}

--------------------------------------------------------------------------------
-- Watering
--------------------------------------------------------------------------------
TreeConfig.WateringCooldown = 25

--------------------------------------------------------------------------------
-- 3D world layout
--------------------------------------------------------------------------------
TreeConfig.PlotOrigin  = Vector3.new(0, 0, 0)   -- center of the player's plot
TreeConfig.GridSpacing = 14                      -- studs between tree slots
TreeConfig.GridColumns = 4                       -- slots per row

--------------------------------------------------------------------------------
-- Feedback messages  (rich feedback & consequences)
--------------------------------------------------------------------------------
TreeConfig.FeedbackMessages = {
	-- Planting & seeds
	treePlanted       = "🌱 New %s planted!",
	seedPurchased     = "🌰 Seed for %s acquired! Planting...",
	notEnoughSeeds    = "❌ Not enough resources for this seed! Need: %s",
	
	-- Watering & consequences
	treeWatered       = "💧 %s watered!",
	alreadyWatered    = "This tree was recently watered.",
	treeWithering     = "⚠ Your %s is WITHERING! Water it NOW!",
	treeDied          = "💀 Your %s has DIED from neglect!",
	revived           = "✅ %s revived!",
	
	-- Consequence warnings
	deathPenalty      = "A dead tree wastes a slot. Revive (50%% cost) or lose it!",
	witherWarning     = "Withered trees produce NOTHING until watered!",
	oversellWarning   = "📉 Selling too much at once crashes the price!",
	
	-- Tiers
	tierUnlocked      = "🎉 Tier %d unlocked: %s!",
	notUnlocked       = "🔒 Unlock tier %d first!",
	
	-- Money & market
	notEnoughCoins    = "💰 Not enough coins!",
	soldResources     = "💰 Sold %d %s for %d coins (tax: %d)!",
	noResources       = "No %s to sell!",
	slotsFull         = "All tree slots are full!",
	marketCrash       = "📉 %s price CRASHED! Oversupply!",
	marketBoom        = "📈 %s is BOOMING! Sell now for big profit!",
	
	-- Cosmetics
	cosmeticEquipped  = "%s equipped!",
	cosmeticUnlocked  = "New cosmetic unlocked: %s!",
}

--------------------------------------------------------------------------------
-- Cosmetics / Wardrobe - CLASSIC CLOTHING ONLY
-- Using verified Roblox classic clothing template asset IDs
--------------------------------------------------------------------------------
TreeConfig.Cosmetics = {
	-- SHIRTS (Classic Roblox Clothing - Base templates with Color3 colorization)
	WhiteShirt = {
		id = "WhiteShirt",
		name = "White Shirt",
		icon = "👕",
		category = "shirt",
		assetId = "rbxassetid://86896487",  -- Classic white shirt template
		color = Color3.fromRGB(255, 255, 255),  -- White
	},
	RedShirt = {
		id = "RedShirt",
		name = "Red Shirt",
		icon = "👕",
		category = "shirt",
		assetId = "rbxassetid://86896487",  -- Using base template with Color3
		color = Color3.fromRGB(255, 0, 0),  -- Red
	},
	BlueShirt = {
		id = "BlueShirt",
		name = "Blue Shirt",
		icon = "👕",
		category = "shirt",
		assetId = "rbxassetid://86896487",  -- Using base template with Color3
		color = Color3.fromRGB(0, 0, 255),  -- Blue
	},
	GreenShirt = {
		id = "GreenShirt",
		name = "Green Shirt",
		icon = "👕",
		category = "shirt",
		assetId = "rbxassetid://86896487",  -- Using base template with Color3
		color = Color3.fromRGB(0, 255, 0),  -- Green
	},
	PurpleShirt = {
		id = "PurpleShirt",
		name = "Purple Shirt",
		icon = "👕",
		category = "shirt",
		assetId = "rbxassetid://86896487",  -- Using base template with Color3
		color = Color3.fromRGB(128, 0, 255),  -- Purple
	},

	-- PANTS (Classic Roblox Clothing - Base templates with Color3 colorization)
	WhitePants = {
		id = "WhitePants",
		name = "White Pants",
		icon = "👖",
		category = "pants",
		assetId = "rbxassetid://86896501",  -- Classic pants template
		color = Color3.fromRGB(255, 255, 255),  -- White
	},
	BlackPants = {
		id = "BlackPants",
		name = "Black Pants",
		icon = "👖",
		category = "pants",
		assetId = "rbxassetid://86896501",  -- Using base template with Color3
		color = Color3.fromRGB(0, 0, 0),  -- Black
	},
	BluePants = {
		id = "BluePants",
		name = "Blue Pants",
		icon = "👖",
		category = "pants",
		assetId = "rbxassetid://86896501",  -- Using base template with Color3
		color = Color3.fromRGB(0, 0, 255),  -- Blue
	},
	GreenPants = {
		id = "GreenPants",
		name = "Green Pants",
		icon = "👖",
		category = "pants",
		assetId = "rbxassetid://86896501",  -- Using base template with Color3
		color = Color3.fromRGB(0, 255, 0),  -- Green
	},
	JeansPants = {
		id = "JeansPants",
		name = "Jeans Pants",
		icon = "👖",
		category = "pants",
		assetId = "rbxassetid://86896501",  -- Using base template with Color3
		color = Color3.fromRGB(25, 25, 112),  -- Indigo (jean blue)
	},
}

-- Only show shirt and pants categories for classic clothing
TreeConfig.CosmeticCategories = { "shirt", "pants" }

return TreeConfig
