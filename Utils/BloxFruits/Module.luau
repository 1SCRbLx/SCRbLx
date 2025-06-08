local Settings, Connections = ...

local _ENV = (getgenv or getrenv or getfenv)()

if type(Settings) ~= "table" or type(Connections) ~= "table" then
	return {}
end

local VirtualInputManager: VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService: CollectionService = game:GetService("CollectionService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService: TeleportService = game:GetService("TeleportService")
local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunValidator: RemoteEvent = Remotes:WaitForChild("Validator2")
local CommF: RemoteFunction = Remotes:WaitForChild("CommF_")
local CommE: RemoteEvent = Remotes:WaitForChild("CommE")

local ChestModels: Folder = workspace:WaitForChild("ChestModels")
local WorldOrigin: Folder = workspace:WaitForChild("_WorldOrigin")
local Characters: Folder = workspace:WaitForChild("Characters")
local SeaBeasts: Folder = workspace:WaitForChild("SeaBeasts")
local Enemies: Folder = workspace:WaitForChild("Enemies")
local Boats: Folder = workspace:WaitForChild("Boats")
local Map: Model = workspace:WaitForChild("Map")

local EnemySpawns: Folder = WorldOrigin:WaitForChild("EnemySpawns")
local Locations: Folder = WorldOrigin:WaitForChild("Locations")

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped
local Player = Players.LocalPlayer

local Data: Folder = Player:WaitForChild("Data")
local Level: IntValue = Data:WaitForChild("Level")
local Fragments: IntValue = Data:WaitForChild("Fragments")
local Money: IntValue = Data:WaitForChild("Beli")

local Modules: Folder? = ReplicatedStorage:WaitForChild("Modules")
local Net: ModuleScript = Modules:WaitForChild("Net")

local EXECUTOR_NAME: string = string.upper(if identifyexecutor then identifyexecutor() else "NULL")
local IS_BLACKLISTED_EXECUTOR: boolean? = table.find({"NULL", "XENO", "JJSPLOIT"}, EXECUTOR_NAME)

local hookmetamethod = (not IS_BLACKLISTED_EXECUTOR and hookmetamethod) or (function(...) return ... end)
local hookfunction = (not IS_BLACKLISTED_EXECUTOR and hookfunction) or (function(...) return ... end)
local sethiddenproperty = sethiddenproperty or (function(...) return ... end)

local setupvalue: (any, number, any?) -> (nil) = setupvalue or (debug and debug.setupvalue)
local getupvalue: (any, number) -> any = getupvalue or (debug and debug.getupvalue)

local BRING_TAG: string = _ENV._Bring_Tag or `b{math.random(80, 2e4)}t`
local KILLAURA_TAG: string = _ENV._KillAura_Tag or `k{math.random(120, 2e4)}t`

local WaitSeconds = nil;

local HIDDEN_SETTINGS: { [string]: any } = {
	SKILL_COOLDOWN = 0.5,
	CLEAR_AFTER = 50,
	
	SILENT_AIM_ENABLED = false,
	WALKSPEED_BYPASS_ENABLED = true
}

_ENV._Bring_Tag = BRING_TAG
_ENV._KillAura_Tag = KILLAURA_TAG

local function GetEnemyName(string: string): string
	return (string:find("Lv. ") and string:gsub(" %pLv. %d+%p", "") or string):gsub(" %pBoss%p", "")
end

local function CheckPlayerAlly(__Player: Player): boolean
	if tostring(__Player.Team) == "Marines" and __Player.Team == Player.Team then
		return false
	elseif __Player:HasTag(`Ally{Player.Name}`) or Player:HasTag(`Ally{__Player.Name}`) then
		return false
	end
	
	return true
end

local function WaitChilds(Instance: Instance, ...): Instance?
	for _, Children: string in {...} do
		Instance = if Instance then Instance:WaitForChild(Children, WaitSeconds) else nil
	end
	
	return Instance
end

local function FastWait(Seconds: number, Instance: Instance, ...): Instance?
	WaitSeconds = if type(Seconds) == "number" then Seconds else nil
	local Success, _Instance = pcall(WaitChilds, Instance, ...)
	WaitSeconds = nil
	
	return if Success then _Instance else nil
end

local function CreateNewClear()
	local COUNT_NEWINDEX = 0
	
	return {
		__newindex = function(self, index, value)
			if COUNT_NEWINDEX >= HIDDEN_SETTINGS.CLEAR_AFTER then
				for key, cache in pairs(self) do
					if typeof(cache) == "Instance" and not cache:IsDescendantOf(game) then
						rawset(self, key, nil)
					end
				end
				COUNT_NEWINDEX = 0
			end
			
			COUNT_NEWINDEX += 1
			return rawset(self, index, value)
		end
	}
end

function CreateDictionary(array: { string }, value: any?): { [string]: any? }
	local Dictionary = {}
	
	for _, string in ipairs(array) do
		Dictionary[string] = if type(value) == "table" then {} else value
	end
	
	return Dictionary
end

local Signal = {} do
	local Connection = {} do
		Connection.__index = Connection
		
		function Connection:Disconnect(): (nil)
			if not self.Connected then
				return nil
			end
			
			local find = table.find(self.Signal, self)
			
			if find then
				table.remove(self.Signal, find)
			end
			
			self.Function = nil
			self.Connected = false
		end
		
		function Connection:Fire(...): (nil)
			if not self.Function then
				return nil
			end
			
			task.spawn(self.Function, ...)
		end
		
		function Connection.new(): Connection
			return setmetatable({
				Connected = true
			}, Connection)
		end
		
		setmetatable(Connection, {
			__index = function(self, index)
				error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(index)), 2)
			end,
			__newindex = function(tb, key, value)
				error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
			end
		})
	end
	
	Signal.__index = Signal
	
	function Signal:Connect(Function): Connection
		if type(Function) ~= "function" then
			return nil
		end
		
		local NewConnection = Connection.new()
		NewConnection.Function = Function
		NewConnection.Signal = self
		
		table.insert(self.Connections, NewConnection)
		return NewConnection
	end
	
	function Signal:Once(Function): (nil)
		local Connection;
		Connection = self:Connect(function(...)
			Function(...)
			Connection:Disconnect()
		end)
		return Connection
	end
	
	function Signal:Wait(): any?
		local WaitingCoroutine = coroutine.running()
		local Connection;Connection = self:Connect(function(...)
			Connection:Disconnect()
			task.spawn(WaitingCoroutine, ...)
		end)
		return coroutine.yield()
	end
	
	function Signal:Fire(...): (nil)
		for _, Connection in ipairs(self.Connections) do
			if Connection.Connected then
				Connection:Fire(...)
			end
		end
	end
	
	function Signal.new(): Signal
		return setmetatable({
			Connections = {}
		}, Signal)
	end
	
	setmetatable(Signal, {
		__index = function(self, index)
			error(`Attempt to get Signal::{ tostring(index) } (not a valid member)`, 2)
		end,
		__newindex = function(self, index, value)
			error(`Attempt to set Signal::{ tostring(index) } (not a valid member)`, 2)
		end
	})
end

local Module = {} do
	local Cached = {
		Closest = nil,
		Equipped = nil,
		Humanoids = setmetatable({}, CreateNewClear()),
		RealFruitsName = setmetatable({}, CreateNewClear()),
		RealFruitsId = setmetatable({}, CreateNewClear()),
		Enemies = {}, -- setmetatable({}, CreateNewClear()),
		Progress = {},
		Bring = {},
		Tools = {}
	}
	
	Module.GameData = {
		Sea = ({ [2753915549] = 1, [4442272183] = 2, [7449423635] = 3 })[game.PlaceId] or 0,
		SeasName = { "Main", "Dressrosa", "Zou" },
		MaxMastery = 600,
		MaxLevel = 2650
	}
	
	Module.Debounce = {
		TargetDebounce = 0,
		UpdateDebounce = 0,
		GetEnemy = 0,
		Skills = {}
	}
	
	do
		Module.FruitsId = {
			["rbxassetid://15124425041"] = "Rocket",
			["rbxassetid://15123685330"] = "Spin",
			["rbxassetid://15123613404"] = "Blade",
			["rbxassetid://15123689268"] = "Spring",
			["rbxassetid://15123595806"] = "Bomb",
			["rbxassetid://15123677932"] = "Smoke",
			["rbxassetid://15124220207"] = "Spike",
			["rbxassetid://121545956771325"] = "Flame",
			["rbxassetid://15123673019"] = "Sand",
			["rbxassetid://15123618591"] = "Dark",
			["rbxassetid://77885466312115"] = "Eagle",
			["rbxassetid://15112600534"] = "Diamond",
			["rbxassetid://15123640714"] = "Light",
			["rbxassetid://15123668008"] = "Rubber",
			["rbxassetid://15123662036"] = "Ghost",
			["rbxassetid://15123645682"] = "Magma",
			["rbxassetid://15123606541"] = "Quake",
			["rbxassetid://15123606541"] = "Buddha",
			["rbxassetid://15123643097"] = "Love",
			["rbxassetid://15123681598"] = "Spider",
			["rbxassetid://116828771482820"] = "Creation",
			["rbxassetid://15123679712"] = "Sound",
			["rbxassetid://15123654553"] = "Phoenix",
			["rbxassetid://15123656798"] = "Portal",
			["rbxassetid://15123670514"] = "Rumble",
			["rbxassetid://15123652069"] = "Pain",
			["rbxassetid://15123587371"] = "Blizzard",
			["rbxassetid://15123633312"] = "Gravity",
			["rbxassetid://15123648309"] = "Mammoth",
			["rbxassetid://15694681122"] = "T-Rex",
			["rbxassetid://15123624401"] = "Dough",
			["rbxassetid://15123675904"] = "Shadow",
			["rbxassetid://10773719142"] = "Venom",
			["rbxassetid://15123616275"] = "Control",
			["rbxassetid://11911905519"] = "Spirit",
			["rbxassetid://15123638064"] = "Leopard",
			["rbxassetid://15487764876"] = "Kitsune",
			["rbxassetid://115276580506154"] = "Yeti",
			["rbxassetid://118054805452821"] = "Gas",
			["rbxassetid://95749033139458"] = "Dragon East"
		}
		
		Module.Bosses = {
			-- Bosses Sea 1
			["Saber Expert"] = {
				NoQuest = true,
				Position = CFrame.new(-1461, 30, -51)
			},
			["The Saw"] = {
				RaidBoss = true,
				Position = CFrame.new(-690, 15, 1583)
			},
			["Greybeard"] = {
				RaidBoss = true,
				Position = CFrame.new(-5043, 25, 4262)
			},
			["The Gorilla King"] = {
				IsBoss = true,
				Level = 20,
				Position = CFrame.new(-1128, 6, -451),
				Quest = {"JungleQuest", CFrame.new(-1598, 37, 153)}
			},
			["Chef"] = {
				IsBoss = true,
				Level = 55,
				Position = CFrame.new(-1131, 14, 4080),
				Quest = {"BuggyQuest1", CFrame.new(-1140, 4, 3829)}
			},
			["Yeti"] = {
				IsBoss = true,
				Level = 105,
				Position = CFrame.new(1185, 106, -1518),
				Quest = {"SnowQuest", CFrame.new(1385, 87, -1298)}
			},
			["Vice Admiral"] = {
				IsBoss = true,
				Level = 130,
				Position = CFrame.new(-4807, 21, 4360),
				Quest = {"MarineQuest2", CFrame.new(-5035, 29, 4326), 2}
			},
			["Swan"] = {
				IsBoss = true,
				Level = 240,
				Position = CFrame.new(5230, 4, 749),
				Quest = {"ImpelQuest", CFrame.new(5191, 4, 692)}
			},
			["Chief Warden"] = {
				IsBoss = true,
				Level = 230,
				Position = CFrame.new(5230, 4, 749),
				Quest = {"ImpelQuest", CFrame.new(5191, 4, 692), 2}
			},
			["Warden"] = {
				IsBoss = true,
				Level = 220,
				Position = CFrame.new(5230, 4, 749),
				Quest = {"ImpelQuest", CFrame.new(5191, 4, 692), 1}
			},
			["Magma Admiral"] = {
				IsBoss = true,
				Level = 350,
				Position = CFrame.new(-5694, 18, 8735),
				Quest = {"MagmaQuest", CFrame.new(-5319, 12, 8515)}
			},
			["Fishman Lord"] = {
				IsBoss = true,
				Level = 425,
				Position = CFrame.new(61350, 31, 1095),
				Quest = {"FishmanQuest", CFrame.new(61122, 18, 1567)}
			},
			["Wysper"] = {
				IsBoss = true,
				Level = 500,
				Position = CFrame.new(-7927, 5551, -637),
				Quest = {"SkyExp1Quest", CFrame.new(-7861, 5545, -381)}
			},
			["Thunder God"] = {
				IsBoss = true,
				Level = 575,
				Position = CFrame.new(-7751, 5607, -2315),
				Quest = {"SkyExp2Quest", CFrame.new(-7903, 5636, -1412)}
			},
			["Cyborg"] = {
				IsBoss = true,
				Level = 675,
				Position = CFrame.new(6138, 10, 3939),
				Quest = {"FountainQuest", CFrame.new(5258, 39, 4052)}
			},
			
			-- Bosses Sea 2
			["Don Swan"] = {
				RaidBoss = true,
				Position = CFrame.new(2289, 15, 808)
			},
			["Cursed Captain"] = {
				RaidBoss = true,
				Position = CFrame.new(912, 186, 33591)
			},
			["Darkbeard"] = {
				RaidBoss = true,
				Position = CFrame.new(3695, 13, -3599)
			},
			["Diamond"] = {
				IsBoss = true,
				Level = 750,
				Position = CFrame.new(-1569, 199, -31),
				Quest = {"Area1Quest", CFrame.new(-427, 73, 1835)}
			},
			["Jeremy"] = {
				IsBoss = true,
				Level = 850,
				Position = CFrame.new(2316, 449, 787),
				Quest = {"Area2Quest", CFrame.new(635, 73, 919)}
			},
			["Orbitus"] = {
				IsBoss = true,
				Level = 925,
				Position = CFrame.new(-2086, 73, -4208),
				Quest = {"MarineQuest3", CFrame.new(-2441, 73, -3219)}
			},
			["Smoke Admiral"] = {
				IsBoss = true,
				Level = 1150,
				Position = CFrame.new(-5078, 24, -5352),
				Quest = {"IceSideQuest", CFrame.new(-6061, 16, -4904)}
			},
			["Awakened Ice Admiral"] = {
				IsBoss = true,
				Level = 1400,
				Position = CFrame.new(6473, 297, -6944),
				Quest = {"FrostQuest", CFrame.new(5668, 28, -6484)}
			},
			["Tide Keeper"] = {
				IsBoss = true,
				Level = 1475,
				Position = CFrame.new(-3711, 77, -11469),
				Quest = {"ForgottenQuest", CFrame.new(-3056, 240, -10145)}
			},
			
			-- Bosses Sea 3
			["Tyrant of the Skies"] = {
				RaidBoss = true,
				Position = CFrame.new(-16252, 153, 1394)
			},
			["Cake Prince"] = {
				RaidBoss = true,
				Position = CFrame.new(-2103, 70, -12165)
			},
			["Dough King"] = {
				RaidBoss = true,
				Position = CFrame.new(-2103, 70, -12165)
			},
			["rip_indra True Form"] = {
				RaidBoss = true,
				Position = CFrame.new(-5333, 424, -2673)
			},
			["Stone"] = {
				IsBoss = true,
				Level = 1550,
				Position = CFrame.new(-1049, 40, 6791),
				Quest = {"PiratePortQuest", CFrame.new(-449, 109, 5950)}
			},
			["Hydra Leader"] = {
				IsBoss = true,
				Level = 1675,
				Position = CFrame.new(5836, 1019, -83),
				Quest = {"VenomCrewQuest", CFrame.new(5214, 1004, 761)}
			},
			["Kilo Admiral"] = {
				IsBoss = true,
				Level = 1750,
				Position = CFrame.new(2904, 509, -7349),
				Quest = {"MarineTreeIsland", CFrame.new(2485, 74, -6788)}
			},
			["Captain Elephant"] = {
				IsBoss = true,
				Level = 1875,
				Position = CFrame.new(-13393, 319, -8423),
				Quest = {"DeepForestIsland", CFrame.new(-13233, 332, -7626)}
			},
			["Beautiful Pirate"] = {
				IsBoss = true,
				Level = 1950,
				Position = CFrame.new(5370, 22, -89),
				Quest = {"DeepForestIsland2", CFrame.new(-12682, 391, -9901)}
			},
			["Cake Queen"] = {
				IsBoss = true,
				Level = 2175,
				Position = CFrame.new(-710, 382, -11150),
				Quest = {"IceCreamIslandQuest", CFrame.new(-818, 66, -10964)}
			},
			["Longma"] = {
				NoQuest = true,
				Position = CFrame.new(-10218, 333, -9444)
			}
		}
		
		Module.Shop = {
			{"Frags", {{"Race Reroll", {"BlackbeardReward", "Reroll", "2"}}, {"Reset Stats", {"BlackbeardReward", "Refund", "2"}}}},
			{"Fighting Style", {
				{"Buy Black Leg", {"BuyBlackLeg"}},
				{"Buy Electro", {"BuyElectro"}},
				{"Buy Fishman Karate", {"BuyFishmanKarate"}},
				{"Buy Dragon Claw", {"BlackbeardReward", "DragonClaw", "2"}},
				{"Buy Superhuman", {"BuySuperhuman"}},
				{"Buy Death Step", {"BuyDeathStep"}},
				{"Buy Sharkman Karate", {"BuySharkmanKarate"}},
				{"Buy Electric Claw", {"BuyElectricClaw"}},
				{"Buy Dragon Talon", {"BuyDragonTalon"}},
				{"Buy GodHuman", {"BuyGodhuman"}},
				{"Buy Sanguine Art", {"BuySanguineArt"}}
				-- {"Buy Divine Art", {"BuyDivineArt"}}
			}},
			{"Ability Teacher", {
				{"Buy Geppo", {"BuyHaki", "Geppo"}},
				{"Buy Buso", {"BuyHaki", "Buso"}},
				{"Buy Soru", {"BuyHaki", "Soru"}},
				{"Buy Ken", {"KenTalk", "Buy"}}
			}},
			{"Sword", {
				{"Buy Katana", {"BuyItem", "Katana"}},
				{"Buy Cutlass", {"BuyItem", "Cutlass"}},
				{"Buy Dual Katana", {"BuyItem", "Dual Katana"}},
				{"Buy Iron Mace", {"BuyItem", "Iron Mace"}},
				{"Buy Triple Katana", {"BuyItem", "Triple Katana"}},
				{"Buy Pipe", {"BuyItem", "Pipe"}},
				{"Buy Dual-Headed Blade", {"BuyItem", "Dual-Headed Blade"}},
				{"Buy Soul Cane", {"BuyItem", "Soul Cane"}},
				{"Buy Bisento", {"BuyItem", "Bisento"}}
			}},
			{"Gun", {
				{"Buy Musket", {"BuyItem", "Musket"}},
				{"Buy Slingshot", {"BuyItem", "Slingshot"}},
				{"Buy Flintlock", {"BuyItem", "Flintlock"}},
				{"Buy Refined Slingshot", {"BuyItem", "Refined Slingshot"}},
				{"Buy Dual Flintlock", {"BuyItem", "Dual Flintlock"}},
				{"Buy Cannon", {"BuyItem", "Cannon"}},
				{"Buy Kabucha", {"BlackbeardReward", "Slingshot", "2"}}
			}},
			{"Accessories", {
				{"Buy Black Cape", {"BuyItem", "Black Cape"}},
				{"Buy Swordsman Hat", {"BuyItem", "Swordsman Hat"}},
				{"Buy Tomoe Ring", {"BuyItem", "Tomoe Ring"}}
			}},
			{"Race", {{"Ghoul Race", {"Ectoplasm", "Change", 4}}, {"Cyborg Race", {"CyborgTrainer", "Buy"}}}}
		}
	end
	
	do
		Module.IsSuperBring = false
		
		Module.RemoveCanTouch = 0
		Module.AttackCooldown = 0
		Module.PirateRaid = 0
		
		Module.Webhooks = true
		Module.JobIds = true
		
		Module.Progress = {}
		Module.EnemyLocations = {}
		Module.SpawnLocations = {}
		
		Module.Cached = Cached
	end
	
	Module.Signals = {} do
		local Signals = Module.Signals
		
		Signals.PossibleStaff = Signal.new()
		Signals.OptionChanged = Signal.new()
		Signals.EnemyAdded = Signal.new()
		Signals.EnemyDied = Signal.new()
		Signals.Notify = Signal.new()
		Signals.Error = Signal.new()

		Signals.Error:Connect(function(ErrorMessage)
			_ENV.loadedFarm = false
			_ENV.OnFarm = false
			
			local Message = Instance.new("Message", workspace)
			_ENV.redz_hub_error = Message
			Message.Text = (`redz-Hub error [ {Settings.RunningOption or "Null"} ] {ErrorMessage}`)
		end)
	end
	
	Module.RunFunctions = {} do
		Module.RunFunctions.TweenModule = function()
			local module = {}
			module.__index = module
			
			local TweenService = game:GetService("TweenService")
			
			local tweens = {}
			local EasingStyle = Enum.EasingStyle.Linear
			
			function module.new(obj, time, prop, value)
				local self = setmetatable({}, module)
				
				self.tween = TweenService:Create(obj, TweenInfo.new(time, EasingStyle), { [prop] = value })
				self.tween:Play()
				self.value = value
				self.object = obj
				
				if tweens[obj] then
					tweens[obj]:destroy()
				end
				
				tweens[obj] = self
				return self
			end
			
			function module:destroy()
				self.tween:Pause()
				self.tween:Destroy()
				
				tweens[self.object] = nil
				setmetatable(self, nil)
			end
			
			function module:stopTween(obj)
				if obj and tweens[obj] then
					tweens[obj]:destroy()
				end
			end
			
			return module
		end
		
		Module.RunFunctions.Translator = function(Window, Translation)
			local MakeTab = Window.MakeTab
			
			Window.MakeTab = function(self, Configs)
				if Translation[ Configs[1] ] then
					Configs[1] = Translation[ Configs[1] ]
				end
				
				local Tab = MakeTab(self, Configs)
				local NewTab = {}
				
				function NewTab:AddSection(Name)
					return Tab:AddSection(Translation[Name] or Name)
				end
				
				function NewTab:AddButton(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddButton(Configs)
				end
				
				function NewTab:AddToggle(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddToggle(Configs)
				end
				
				function NewTab:AddSlider(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddSlider(Configs)
				end
				
				function NewTab:AddDropdown(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddDropdown(Configs)
				end
				
				function NewTab:AddTextBox(Configs)
					local Translator = Translation[ Configs[1] ]
					
					
