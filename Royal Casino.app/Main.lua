
-- Royal Casino for MineOS
-- A beautiful casino application with three game modes

local GUI = require("GUI")
local system = require("System")
local filesystem = require("Filesystem")
local paths = require("Paths")
local image = require("Image")
local color = require("Color")

--------------------------------------------------------------------------------

-- Constants
local COLORS = {
	background = 0x1E1E1E,
	gold = 0xFFD700,
	red = 0xFF3333,
	green = 0x33FF33,
	white = 0xFFFFFF,
	gray = 0xAAAAAA,
	darkGray = 0x2D2D2D,
	black = 0x000000,
}

local MIN_BET = 10
local INITIAL_BALANCE = 0
local DAILY_BONUS = 100

-- Paths
local appPath = filesystem.path(system.getCurrentScript())
local resourcesPath = appPath .. "Resources/"
local balanceFile = paths.system.applicationData .. "RoyalCasino/balance.cfg"

-- Global variables
local workspace, window, menu
local localization
local playerData = {}
local currentGame = nil

--------------------------------------------------------------------------------
-- Balance Management
--------------------------------------------------------------------------------

local function ensureDirectoryExists(path)
	local dir = filesystem.path(path)
	if not filesystem.exists(dir) then
		filesystem.makeDirectory(dir)
	end
end

local function loadBalance()
	ensureDirectoryExists(balanceFile)
	
	if filesystem.exists(balanceFile) then
		local file = io.open(balanceFile, "r")
		if file then
			local data = file:read("*a")
			file:close()
			
			local success, result = pcall(load("return " .. data))
			if success and result then
				playerData = result
				return
			end
		end
	end
	
	-- Initialize default data
	playerData = {
		balance = 0,
		totalWins = 0,
		totalLosses = 0,
		gamesPlayed = 0,
		biggestWin = 0,
		lastPlayed = os.time(),
	}
	saveBalance()
end

local function saveBalance()
	ensureDirectoryExists(balanceFile)
	
	local file = io.open(balanceFile, "w")
	if file then
		file:write(require("Serialization").serialize(playerData))
		file:close()
	end
end

local function addCredits(amount)
	playerData.balance = playerData.balance + amount
	saveBalance()
end

local function deductCredits(amount)
	if playerData.balance >= amount then
		playerData.balance = playerData.balance - amount
		saveBalance()
		return true
	end
	return false
end

local function checkDailyBonus()
	local currentTime = os.time()
	local lastPlayed = playerData.lastPlayed or 0
	
	-- Check if 24 hours have passed (86400 seconds)
	if currentTime - lastPlayed >= 86400 then
		addCredits(DAILY_BONUS)
		playerData.lastPlayed = currentTime
		saveBalance()
		return true
	end
	return false
end

local function formatNumber(num)
	local formatted = tostring(math.floor(num))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

--------------------------------------------------------------------------------
-- Slot Machine Game
--------------------------------------------------------------------------------

local SLOT_SYMBOLS = {
	{name = "cherry", file = "slot_cherry.png", multiplier = 2},
	{name = "bell", file = "slot_bell.png", multiplier = 5},
	{name = "bar", file = "slot_bar.png", multiplier = 10},
	{name = "diamond", file = "slot_diamond.png", multiplier = 25},
	{name = "seven", file = "slot_seven.png", multiplier = 100},
}

local function getRandomSymbol()
	return math.random(1, #SLOT_SYMBOLS)
end

local function calculateSlotWin(reel1, reel2, reel3, bet)
	if reel1 == reel2 and reel2 == reel3 then
		-- Three of a kind - full multiplier
		return bet * SLOT_SYMBOLS[reel1].multiplier
	elseif reel1 == reel2 or reel2 == reel3 or reel1 == reel3 then
		-- Two of a kind - smaller win
		return math.floor(bet * 1.5)
	end
	return 0
end

local function createSlotMachine()
	-- Clear window
	window:removeChildren()
	
	local container = window:addChild(GUI.container(1, 1, window.width, window.height))
	
	-- Title
	container:addChild(GUI.text(1, 2, COLORS.gold, localization.slotMachine))
	
	-- Balance display
	local balanceText = container:addChild(GUI.text(1, 4, COLORS.white, localization.balance .. ": " .. formatNumber(playerData.balance) .. " CC"))
	
	-- Bet input
	container:addChild(GUI.text(1, 6, COLORS.gray, localization.slotBet .. ":"))
	local betInput = container:addChild(GUI.input(15, 6, 20, 1, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.darkGray, COLORS.white, "100", localization.slotBet))
	
	-- Reels
	local reel1Value = 1
	local reel2Value = 2
	local reel3Value = 3
	
	local reel1 = container:addChild(GUI.text(10, 10, COLORS.white, "?"))
	local reel2 = container:addChild(GUI.text(20, 10, COLORS.white, "?"))
	local reel3 = container:addChild(GUI.text(30, 10, COLORS.white, "?"))
	
	-- Win display
	local winText = container:addChild(GUI.text(1, 14, COLORS.green, ""))
	
	-- Spin button
	local spinButton = container:addChild(GUI.button(15, 16, 20, 3, COLORS.gold, COLORS.black, COLORS.darkGray, COLORS.white, localization.slotSpin))
	spinButton.onTouch = function()
		local bet = tonumber(betInput.text) or 0
		
		if bet < MIN_BET then
			GUI.alert(localization.msgMinBet)
			return
		end
		
		if not deductCredits(bet) then
			GUI.alert(localization.msgInsufficientFunds)
			return
		end
		
		-- Spin animation
		for i = 1, 10 do
			reel1Value = getRandomSymbol()
			reel2Value = getRandomSymbol()
			reel3Value = getRandomSymbol()
			
			reel1.text = SLOT_SYMBOLS[reel1Value].name:sub(1, 1):upper()
			reel2.text = SLOT_SYMBOLS[reel2Value].name:sub(1, 1):upper()
			reel3.text = SLOT_SYMBOLS[reel3Value].name:sub(1, 1):upper()
			
			workspace:draw()
			os.sleep(0.1)
		end
		
		-- Calculate win
		local winAmount = calculateSlotWin(reel1Value, reel2Value, reel3Value, bet)
		
		if winAmount > 0 then
			addCredits(winAmount)
			playerData.totalWins = playerData.totalWins + winAmount
			playerData.biggestWin = math.max(playerData.biggestWin, winAmount)
			
			if winAmount >= bet * 100 then
				winText.text = localization.slotJackpot .. " " .. formatNumber(winAmount) .. " CC!"
				winText.color = COLORS.gold
			else
				winText.text = localization.slotWin .. ": " .. formatNumber(winAmount) .. " CC"
				winText.color = COLORS.green
			end
		else
			playerData.totalLosses = playerData.totalLosses + bet
			winText.text = "Better luck next time!"
			winText.color = COLORS.red
		end
		
		playerData.gamesPlayed = playerData.gamesPlayed + 1
		saveBalance()
		
		balanceText.text = localization.balance .. ": " .. formatNumber(playerData.balance) .. " CC"
		workspace:draw()
	end
	
	-- Back button
	local backButton = container:addChild(GUI.button(1, window.height - 2, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.back))
	backButton.onTouch = function()
		createMainMenu()
	end
	
	workspace:draw()
end

--------------------------------------------------------------------------------
-- Roulette Game
--------------------------------------------------------------------------------

local ROULETTE_RED = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36}
local ROULETTE_BLACK = {2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35}

local function isRed(number)
	for i = 1, #ROULETTE_RED do
		if ROULETTE_RED[i] == number then
			return true
		end
	end
	return false
end

local function createRoulette()
	window:removeChildren()
	
	local container = window:addChild(GUI.container(1, 1, window.width, window.height))
	
	-- Title
	container:addChild(GUI.text(1, 2, COLORS.gold, localization.roulette))
	
	-- Balance display
	local balanceText = container:addChild(GUI.text(1, 4, COLORS.white, localization.balance .. ": " .. formatNumber(playerData.balance) .. " CC"))
	
	-- Bet input
	container:addChild(GUI.text(1, 6, COLORS.gray, localization.slotBet .. ":"))
	local betInput = container:addChild(GUI.input(15, 6, 20, 1, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.darkGray, COLORS.white, "50", localization.slotBet))
	
	-- Winning number display
	local numberText = container:addChild(GUI.text(1, 10, COLORS.white, ""))
	
	-- Bet type buttons
	local y = 12
	
	-- Red/Black buttons
	local redButton = container:addChild(GUI.button(1, y, 15, 3, COLORS.red, COLORS.white, COLORS.darkGray, COLORS.white, localization.rouletteRed))
	local blackButton = container:addChild(GUI.button(17, y, 15, 3, COLORS.black, COLORS.white, COLORS.darkGray, COLORS.white, localization.rouletteBlack))
	
	y = y + 4
	
	-- Even/Odd buttons
	local evenButton = container:addChild(GUI.button(1, y, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.rouletteEven))
	local oddButton = container:addChild(GUI.button(17, y, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.rouletteOdd))
	
	y = y + 4
	
	-- Low/High buttons
	local lowButton = container:addChild(GUI.button(1, y, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.rouletteLow))
	local highButton = container:addChild(GUI.button(17, y, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.rouletteHigh))
	
	local function spinRoulette(betType)
		local bet = tonumber(betInput.text) or 0
		
		if bet < MIN_BET then
			GUI.alert(localization.msgMinBet)
			return
		end
		
		if not deductCredits(bet) then
			GUI.alert(localization.msgInsufficientFunds)
			return
		end
		
		-- Spin animation
		for i = 1, 15 do
			local num = math.random(0, 36)
			numberText.text = tostring(num)
			numberText.color = num == 0 and COLORS.green or (isRed(num) and COLORS.red or COLORS.white)
			workspace:draw()
			os.sleep(0.1)
		end
		
		-- Final number
		local winningNumber = math.random(0, 36)
		numberText.text = tostring(winningNumber)
		numberText.color = winningNumber == 0 and COLORS.green or (isRed(winningNumber) and COLORS.red or COLORS.white)
		
		-- Check win
		local won = false
		local multiplier = 2
		
		if betType == "red" and isRed(winningNumber) then
			won = true
		elseif betType == "black" and not isRed(winningNumber) and winningNumber ~= 0 then
			won = true
		elseif betType == "even" and winningNumber % 2 == 0 and winningNumber ~= 0 then
			won = true
		elseif betType == "odd" and winningNumber % 2 == 1 then
			won = true
		elseif betType == "low" and winningNumber >= 1 and winningNumber <= 18 then
			won = true
		elseif betType == "high" and winningNumber >= 19 and winningNumber <= 36 then
			won = true
		end
		
		if won then
			local winAmount = bet * multiplier
			addCredits(winAmount)
			playerData.totalWins = playerData.totalWins + winAmount
			playerData.biggestWin = math.max(playerData.biggestWin, winAmount)
			GUI.alert(localization.slotWin .. ": " .. formatNumber(winAmount) .. " CC")
		else
			playerData.totalLosses = playerData.totalLosses + bet
			GUI.alert("You lose!")
		end
		
		playerData.gamesPlayed = playerData.gamesPlayed + 1
		saveBalance()
		
		balanceText.text = localization.balance .. ": " .. formatNumber(playerData.balance) .. " CC"
		workspace:draw()
	end
	
	redButton.onTouch = function() spinRoulette("red") end
	blackButton.onTouch = function() spinRoulette("black") end
	evenButton.onTouch = function() spinRoulette("even") end
	oddButton.onTouch = function() spinRoulette("odd") end
	lowButton.onTouch = function() spinRoulette("low") end
	highButton.onTouch = function() spinRoulette("high") end
	
	-- Back button
	local backButton = container:addChild(GUI.button(1, window.height - 2, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.back))
	backButton.onTouch = function()
		createMainMenu()
	end
	
	workspace:draw()
end

--------------------------------------------------------------------------------
-- Blackjack Game
--------------------------------------------------------------------------------

local CARD_VALUES = {
	["A"] = 11, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5,
	["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["10"] = 10,
	["J"] = 10, ["Q"] = 10, ["K"] = 10
}

local CARD_NAMES = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"}

local function getRandomCard()
	return CARD_NAMES[math.random(1, #CARD_NAMES)]
end

local function calculateHandValue(hand)
	local value = 0
	local aces = 0
	
	for i = 1, #hand do
		local cardValue = CARD_VALUES[hand[i]]
		value = value + cardValue
		if hand[i] == "A" then
			aces = aces + 1
		end
	end
	
	-- Adjust for aces
	while value > 21 and aces > 0 do
		value = value - 10
		aces = aces - 1
	end
	
	return value
end

local function createBlackjack()
	window:removeChildren()
	
	local container = window:addChild(GUI.container(1, 1, window.width, window.height))
	
	-- Title
	container:addChild(GUI.text(1, 2, COLORS.gold, localization.blackjack))
	
	-- Balance display
	local balanceText = container:addChild(GUI.text(1, 4, COLORS.white, localization.balance .. ": " .. formatNumber(playerData.balance) .. " CC"))
	
	-- Bet input
	container:addChild(GUI.text(1, 6, COLORS.gray, localization.slotBet .. ":"))
	local betInput = container:addChild(GUI.input(15, 6, 20, 1, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.darkGray, COLORS.white, "50", localization.slotBet))
	
	-- Game state
	local dealerHand = {}
	local playerHand = {}
	local gameActive = false
	local currentBet = 0
	
	-- Display areas
	local dealerText = container:addChild(GUI.text(1, 10, COLORS.gray, localization.blackjackDealer .. ": "))
	local dealerValueText = container:addChild(GUI.text(1, 11, COLORS.white, ""))
	
	local playerText = container:addChild(GUI.text(1, 13, COLORS.gray, localization.blackjackPlayer .. ": "))
	local playerValueText = container:addChild(GUI.text(1, 14, COLORS.white, ""))
	
	local resultText = container:addChild(GUI.text(1, 16, COLORS.white, ""))
	
	local function updateDisplay(hideDealer)
		local dealerCards = ""
		for i = 1, #dealerHand do
			if hideDealer and i == 2 then
				dealerCards = dealerCards .. "[?] "
			else
				dealerCards = dealerCards .. "[" .. dealerHand[i] .. "] "
			end
		end
		dealerText.text = localization.blackjackDealer .. ": " .. dealerCards
		
		if not hideDealer then
			dealerValueText.text = "Value: " .. calculateHandValue(dealerHand)
		else
			dealerValueText.text = ""
		end
		
		local playerCards = ""
		for i = 1, #playerHand do
			playerCards = playerCards .. "[" .. playerHand[i] .. "] "
		end
		playerText.text = localization.blackjackPlayer .. ": " .. playerCards
		playerValueText.text = "Value: " .. calculateHandValue(playerHand)
		
		workspace:draw()
	end
	
	local function endGame(result)
		gameActive = false
		updateDisplay(false)
		
		if result == "win" then
			local winAmount = currentBet * 2
			addCredits(winAmount)
			playerData.totalWins = playerData.totalWins + winAmount
			playerData.biggestWin = math.max(playerData.biggestWin, winAmount)
			resultText.text = localization.blackjackWin .. " +" .. formatNumber(winAmount) .. " CC"
			resultText.color = COLORS.green
		elseif result == "blackjack" then
			local winAmount = math.floor(currentBet * 2.5)
			addCredits(winAmount)
			playerData.totalWins = playerData.totalWins + winAmount
			playerData.biggestWin = math.max(playerData.biggestWin, winAmount)
			resultText.text = "BLACKJACK! +" .. formatNumber(winAmount) .. " CC"
			resultText.color = COLORS.gold
		elseif result == "push" then
			addCredits(currentBet)
			resultText.text = localization.blackjackPush
			resultText.color = COLORS.gray
		else
			playerData.totalLosses = playerData.totalLosses + currentBet
			resultText.text = localization.blackjackLose
			resultText.color = COLORS.red
		end
		
		playerData.gamesPlayed = playerData.gamesPlayed + 1
		saveBalance()
		balanceText.text = localization.balance .. ": " .. formatNumber(playerData.balance) .. " CC"
		workspace:draw()
	end
	
	-- Deal button
	local dealButton = container:addChild(GUI.button(1, 18, 15, 3, COLORS.gold, COLORS.black, COLORS.darkGray, COLORS.white, localization.blackjackDeal))
	dealButton.onTouch = function()
		local bet = tonumber(betInput.text) or 0
		
		if bet < MIN_BET then
			GUI.alert(localization.msgMinBet)
			return
		end
		
		if not deductCredits(bet) then
			GUI.alert(localization.msgInsufficientFunds)
			return
		end
		
		currentBet = bet
		gameActive = true
		resultText.text = ""
		
		-- Deal initial cards
		dealerHand = {getRandomCard(), getRandomCard()}
		playerHand = {getRandomCard(), getRandomCard()}
		
		updateDisplay(true)
		
		-- Check for blackjack
		if calculateHandValue(playerHand) == 21 then
			endGame("blackjack")
		end
	end
	
	-- Hit button
	local hitButton = container:addChild(GUI.button(17, 18, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.blackjackHit))
	hitButton.onTouch = function()
		if not gameActive then
			return
		end
		
		table.insert(playerHand, getRandomCard())
		updateDisplay(true)
		
		local playerValue = calculateHandValue(playerHand)
		if playerValue > 21 then
			resultText.text = localization.blackjackBust
			resultText.color = COLORS.red
			endGame("lose")
		elseif playerValue == 21 then
			-- Auto-stand on 21
			hitButton.onTouch = nil
			standButton.onTouch()
		end
	end
	
	-- Stand button
	local standButton = container:addChild(GUI.button(33, 18, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.blackjackStand))
	standButton.onTouch = function()
		if not gameActive then
			return
		end
		
		-- Dealer plays
		while calculateHandValue(dealerHand) < 17 do
			table.insert(dealerHand, getRandomCard())
			updateDisplay(false)
			os.sleep(0.5)
		end
		
		local dealerValue = calculateHandValue(dealerHand)
		local playerValue = calculateHandValue(playerHand)
		
		if dealerValue > 21 then
			endGame("win")
		elseif playerValue > dealerValue then
			endGame("win")
		elseif playerValue == dealerValue then
			endGame("push")
		else
			endGame("lose")
		end
	end
	
	-- Back button
	local backButton = container:addChild(GUI.button(1, window.height - 2, 15, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.back))
	backButton.onTouch = function()
		createMainMenu()
	end
	
	workspace:draw()
end

--------------------------------------------------------------------------------
-- Main Menu
--------------------------------------------------------------------------------

function createMainMenu()
	window:removeChildren()
	
	local container = window:addChild(GUI.container(1, 1, window.width, window.height))
	
	-- Title
	container:addChild(GUI.text(math.floor(window.width / 2) - 6, 2, COLORS.gold, localization.appName))
	
	-- Balance display
	local balanceText = container:addChild(GUI.text(1, 5, COLORS.white, localization.balance .. ": " .. formatNumber(playerData.balance) .. " CC"))
	
	-- Add credits button
	local addCreditsButton = container:addChild(GUI.button(window.width - 20, 5, 20, 3, COLORS.green, COLORS.white, COLORS.darkGray, COLORS.white, localization.addCredits))
	addCreditsButton.onTouch = function()
		local container = GUI.addBackgroundContainer(workspace, true, true, localization.addCredits)
		
		local input = container.layout:addChild(GUI.input(1, 1, 30, 3, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.darkGray, COLORS.white, "100", localization.msgEnterAmount))
		
		container.layout:addChild(GUI.button(1, 1, 30, 3, COLORS.green, COLORS.white, COLORS.darkGray, COLORS.white, "OK")).onTouch = function()
			local amount = tonumber(input.text) or 0
			if amount > 0 then
				addCredits(amount)
				balanceText.text = localization.balance .. ": " .. formatNumber(playerData.balance) .. " CC"
				GUI.alert(localization.msgCreditsAdded)
			end
			container:remove()
			workspace:draw()
		end
		
		workspace:draw()
	end
	
	-- Game buttons
	local y = 10
	local buttonWidth = 25
	local buttonHeight = 5
	local spacing = 2
	
	-- Slot Machine
	local slotButton = container:addChild(GUI.button(5, y, buttonWidth, buttonHeight, COLORS.red, COLORS.white, COLORS.darkGray, COLORS.white, localization.slotMachine))
	slotButton.onTouch = function()
		createSlotMachine()
	end
	
	-- Roulette
	local rouletteButton = container:addChild(GUI.button(5 + buttonWidth + spacing, y, buttonWidth, buttonHeight, COLORS.black, COLORS.white, COLORS.darkGray, COLORS.white, localization.roulette))
	rouletteButton.onTouch = function()
		createRoulette()
	end
	
	y = y + buttonHeight + spacing
	
	-- Blackjack
	local blackjackButton = container:addChild(GUI.button(5, y, buttonWidth, buttonHeight, COLORS.darkGray, COLORS.white, COLORS.gray, COLORS.white, localization.blackjack))
	blackjackButton.onTouch = function()
		createBlackjack()
	end
	
	-- Statistics
	y = y + buttonHeight + spacing + 2
	container:addChild(GUI.text(1, y, COLORS.gray, localization.statistics .. ":"))
	y = y + 1
	container:addChild(GUI.text(1, y, COLORS.white, localization.gamesPlayed .. ": " .. formatNumber(playerData.gamesPlayed)))
	y = y + 1
	container:addChild(GUI.text(1, y, COLORS.green, localization.totalWins .. ": " .. formatNumber(playerData.totalWins) .. " CC"))
	y = y + 1
	container:addChild(GUI.text(1, y, COLORS.red, localization.totalLosses .. ": " .. formatNumber(playerData.totalLosses) .. " CC"))
	y = y + 1
	container:addChild(GUI.text(1, y, COLORS.gold, localization.biggestWin .. ": " .. formatNumber(playerData.biggestWin) .. " CC"))
	
	workspace:draw()
end

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

-- Initialize
math.randomseed(os.time())

-- Create window
workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 80, 30, COLORS.background))
window.backgroundPanel.colors.transparency = 0.3

-- Get localization
localization = system.getCurrentScriptLocalization()

-- Load balance
loadBalance()

-- Check daily bonus
if checkDailyBonus() then
	GUI.alert(localization.msgDailyBonus)
end

-- Create main menu
createMainMenu()

-- Draw workspace
workspace:draw()

