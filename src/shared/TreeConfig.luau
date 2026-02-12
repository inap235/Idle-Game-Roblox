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
}

return TreeConfig
