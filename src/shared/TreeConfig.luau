--[[
	TreeConfig – shared configuration for the Idle Gem-Tree Game
	Used by both server and client.
]]

local TreeConfig = {}

--------------------------------------------------------------------------------
-- Tree Definitions  (now with 3D appearance data)
--------------------------------------------------------------------------------
TreeConfig.Trees = {
	BasicTree = {
		id            = "BasicTree",
		name          = "Basic Tree",
		icon          = "🌱",
		cost          = 0,
		resourceType  = "Wood",
		yieldPerCycle = 1,
		cycleTime     = 3,
		unlockTier    = 0,
		description   = "A simple sapling. Produces wood slowly.",
		withersAfter  = 120,
		diesAfter     = 240,
		-- 3D appearance
		trunkColor    = { 139, 90, 43 },
		leafColor     = { 34, 139, 34 },
		trunkHeight   = 5,
		canopySize    = 6,
		resourceColor = { 194, 178, 128 },  -- wood color for floating text
	},
	OakTree = {
		id            = "OakTree",
		name          = "Oak Tree",
		icon          = "🌳",
		cost          = 150,
		resourceType  = "Wood",
		yieldPerCycle = 3,
		cycleTime     = 4,
		unlockTier    = 1,
		description   = "A sturdy oak. Produces wood faster.",
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
		cost          = 500,
		resourceType  = "Apples",
		yieldPerCycle = 2,
		cycleTime     = 5,
		unlockTier    = 2,
		description   = "Sweet apples! Worth more than wood.",
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
		cost          = 1500,
		resourceType  = "Rubies",
		yieldPerCycle = 1,
		cycleTime     = 8,
		unlockTier    = 3,
		description   = "A mystical tree that crystallises rubies!",
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
		cost          = 2000,
		resourceType  = "Opals",
		yieldPerCycle = 1,
		cycleTime     = 10,
		unlockTier    = 3,
		description   = "Shimmering opals bloom on every branch.",
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
		cost          = 3500,
		resourceType  = "Emeralds",
		yieldPerCycle = 1,
		cycleTime     = 12,
		unlockTier    = 4,
		description   = "Deep-green emeralds of the finest quality.",
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
		cost          = 6000,
		resourceType  = "Diamonds",
		yieldPerCycle = 1,
		cycleTime     = 15,
		unlockTier    = 5,
		description   = "The rarest tree. Diamonds are forever!",
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
	[0] = { name = "Beginner",       coinsRequired = 0,      unlocksText = "Basic Tree",                slotsGranted = 3  },
	[1] = { name = "Apprentice",     coinsRequired = 300,    unlocksText = "Oak Tree",                  slotsGranted = 4  },
	[2] = { name = "Farmer",         coinsRequired = 1000,   unlocksText = "Apple Tree",                slotsGranted = 5  },
	[3] = { name = "Gem Collector",  coinsRequired = 3000,   unlocksText = "Ruby Tree & Opal Tree",     slotsGranted = 7  },
	[4] = { name = "Jeweler",        coinsRequired = 8000,   unlocksText = "Emerald Tree",              slotsGranted = 9  },
	[5] = { name = "Tycoon",         coinsRequired = 20000,  unlocksText = "Diamond Tree",              slotsGranted = 12 },
}

TreeConfig.MaxTier = 5

--------------------------------------------------------------------------------
-- Economics – market config
--------------------------------------------------------------------------------
TreeConfig.MarketConfig = {
	minPriceMultiplier  = 0.4,
	maxPriceMultiplier  = 1.5,
	recoveryRate        = 0.002,
	dropPerSale         = 0.03,
	updateInterval      = 5,
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
-- Feedback messages
--------------------------------------------------------------------------------
TreeConfig.FeedbackMessages = {
	treePlanted     = "New %s planted!",
	treeWithering   = "Your %s is withering! Water it!",
	treeDied        = "Your %s has died from neglect!",
	treeWatered     = "%s watered!",
	tierUnlocked    = "Tier %d unlocked: %s!",
	marketCrash     = "%s price crashed! Oversupply!",
	marketBoom      = "%s price is booming!",
	notEnoughCoins  = "Not enough coins!",
	notUnlocked     = "Unlock tier %d first!",
	slotsFull       = "All tree slots are full!",
	soldResources   = "Sold %d %s for %d coins!",
	noResources     = "No %s to sell!",
	alreadyWatered  = "This tree was recently watered.",
	revived         = "%s revived!",
	cosmeticEquipped = "%s equipped!",
	cosmeticUnlocked = "New cosmetic unlocked: %s!",
}

--------------------------------------------------------------------------------
-- Cosmetics / Wardrobe
--------------------------------------------------------------------------------
TreeConfig.Cosmetics = {
	-- HATS
	BasicCap = {
		id = "BasicCap",
		name = "Basic Cap",
		icon = "🧢",
		category = "hat",
		rarity = "common",
		unlockTier = 0,
		bonus = {},
		headColor = Color3.fromRGB(100, 100, 100),
	},
	GardenerHat = {
		id = "GardenerHat",
		name = "Gardener's Hat",
		icon = "🎩",
		category = "hat",
		rarity = "uncommon",
		unlockTier = 1,
		bonus = {},
		headColor = Color3.fromRGB(139, 90, 43),
	},
	CrownOfGems = {
		id = "CrownOfGems",
		name = "Crown of Gems",
		icon = "👑",
		category = "hat",
		rarity = "legendary",
		unlockTier = 3,
		bonus = { productionMultiplier = 1.02 },
		headColor = Color3.fromRGB(255, 215, 0),
	},
	DiamondHalo = {
		id = "DiamondHalo",
		name = "Diamond Halo",
		icon = "💎",
		category = "hat",
		rarity = "epic",
		unlockTier = 5,
		bonus = { productionMultiplier = 1.03 },
		headColor = Color3.fromRGB(185, 242, 255),
	},
	MysticMask = {
		id = "MysticMask",
		name = "Mystic Mask",
		icon = "🎭",
		category = "hat",
		rarity = "rare",
		unlockTier = 2,
		bonus = {},
		headColor = Color3.fromRGB(160, 32, 240),
	},

	-- SHIRTS
	PlainShirt = {
		id = "PlainShirt",
		name = "Plain Shirt",
		icon = "👕",
		category = "shirt",
		rarity = "common",
		unlockTier = 0,
		bonus = {},
		torsoColor = Color3.fromRGB(255, 255, 255),
		armColor = Color3.fromRGB(255, 200, 124),
	},
	GemCollectorAttire = {
		id = "GemCollectorAttire",
		name = "Gem Collector Attire",
		icon = "💎",
		category = "shirt",
		rarity = "epic",
		unlockTier = 3,
		bonus = { resourceValue = 1.05 },
		torsoColor = Color3.fromRGB(70, 130, 230),
		armColor = Color3.fromRGB(70, 130, 230),
	},
	GoldenVest = {
		id = "GoldenVest",
		name = "Golden Vest",
		icon = "🟡",
		category = "shirt",
		rarity = "legendary",
		unlockTier = 4,
		bonus = { resourceValue = 1.03 },
		torsoColor = Color3.fromRGB(255, 215, 0),
		armColor = Color3.fromRGB(255, 215, 0),
	},
	RobeOfPower = {
		id = "RobeOfPower",
		name = "Robe of Power",
		icon = "🪄",
		category = "shirt",
		rarity = "rare",
		unlockTier = 2,
		bonus = {},
		torsoColor = Color3.fromRGB(128, 0, 128),
		armColor = Color3.fromRGB(128, 0, 128),
	},
	DiamondPlateArmor = {
		id = "DiamondPlateArmor",
		name = "Diamond Plate Armor",
		icon = "⚔️",
		category = "shirt",
		rarity = "epic",
		unlockTier = 5,
		bonus = { productionMultiplier = 1.02 },
		torsoColor = Color3.fromRGB(192, 192, 192),
		armColor = Color3.fromRGB(192, 192, 192),
	},

	-- PANTS
	BasicPants = {
		id = "BasicPants",
		name = "Basic Pants",
		icon = "👖",
		category = "pants",
		rarity = "common",
		unlockTier = 0,
		bonus = {},
		legColor = Color3.fromRGB(0, 0, 0),
	},
	GardenOveralls = {
		id = "GardenOveralls",
		name = "Garden Overalls",
		icon = "🦺",
		category = "pants",
		rarity = "uncommon",
		unlockTier = 1,
		bonus = {},
		legColor = Color3.fromRGB(34, 139, 34),
	},
	RoyalTrousers = {
		id = "RoyalTrousers",
		name = "Royal Trousers",
		icon = "🟣",
		category = "pants",
		rarity = "epic",
		unlockTier = 3,
		bonus = {},
		legColor = Color3.fromRGB(128, 0, 128),
	},
	TycoonSlacks = {
		id = "TycoonSlacks",
		name = "Tycoon Slacks",
		icon = "💼",
		category = "pants",
		rarity = "legendary",
		unlockTier = 4,
		bonus = {},
		legColor = Color3.fromRGB(50, 50, 50),
	},
	CasualJeans = {
		id = "CasualJeans",
		name = "Casual Jeans",
		icon = "🔵",
		category = "pants",
		rarity = "common",
		unlockTier = 0,
		bonus = {},
		legColor = Color3.fromRGB(0, 51, 153),
	},

	-- ACCESSORIES
	SimpleBackpack = {
		id = "SimpleBackpack",
		name = "Simple Backpack",
		icon = "🎒",
		category = "accessory",
		rarity = "uncommon",
		unlockTier = 1,
		bonus = {},
	},
	BackpackOfWonder = {
		id = "BackpackOfWonder",
		name = "Backpack of Wonder",
		icon = "✨🎒",
		category = "accessory",
		rarity = "rare",
		unlockTier = 2,
		bonus = { coinBonus = 1.02 },
	},
	LuckyCharm = {
		id = "LuckyCharm",
		name = "Lucky Charm",
		icon = "🍀",
		category = "accessory",
		rarity = "rare",
		unlockTier = 2,
		bonus = {},
	},
	TycoonWatch = {
		id = "TycoonWatch",
		name = "Tycoon Watch",
		icon = "⌚",
		category = "accessory",
		rarity = "legendary",
		unlockTier = 4,
		bonus = { resourceValue = 1.02 },
	},
	AscendedAura = {
		id = "AscendedAura",
		name = "Ascended Aura",
		icon = "✨",
		category = "accessory",
		rarity = "legendary",
		unlockTier = 5,
		bonus = {},
	},

	-- SKINS
	DefaultHuman = {
		id = "DefaultHuman",
		name = "Human",
		icon = "🧑",
		category = "skin",
		rarity = "common",
		unlockTier = 0,
		bonus = {},
	},
	GnomeSkin = {
		id = "GnomeSkin",
		name = "Gnome",
		icon = "🧙",
		category = "skin",
		rarity = "uncommon",
		unlockTier = 1,
		bonus = {},
	},
	FairySkin = {
		id = "FairySkin",
		name = "Fairy",
		icon = "🧚",
		category = "skin",
		rarity = "rare",
		unlockTier = 2,
		bonus = { productionMultiplier = 1.01 },
	},
	WizardSkin = {
		id = "WizardSkin",
		name = "Wizard",
		icon = "🧙",
		category = "skin",
		rarity = "epic",
		unlockTier = 3,
		bonus = {},
	},
	TycoonSkin = {
		id = "TycoonSkin",
		name = "Business Tycoon",
		icon = "🕴️",
		category = "skin",
		rarity = "legendary",
		unlockTier = 5,
		bonus = { resourceValue = 1.01, productionMultiplier = 1.01 },
	},
}

-- Cosmetics ordered by category for UI
TreeConfig.CosmeticCategories = { "hat", "shirt", "pants", "accessory", "skin" }

return TreeConfig
