require("game")
local physics = require("physics")

-- Whether the player is currently playing on in the home screen.
_isPlaying = false
local soundStarted = false
-- Generate bugs falling.
local bugs = {}
local bugsEvent = nil
local isFalls = true

-- Instance of the game.
BugFallz = nil

-- Fade In and Out Splash Logo and initialize Home Screen
function initSplash()
	local tblRemove = {}
	local logoGround = nil
	local splashBg = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	splashBg:setFillColor(0, 0, 0)
	local copyrightText = display.newText("Copyright 2012.", 0, 0, native.systemFont, 14)
	copyrightText.x, copyrightText.y = display.contentWidth*0.5, display.contentHeight-12
	
	table.insert(tblRemove, splashBg)
	table.insert(tblRemove, copyrightText)
	
	local letters = {}
	
	local logoImages = {
		-- Image name, Y-Offset, Size
		{"letter_z.png", 0, {26, 33}},
		{"letter_a.png", 0, {21, 25}},
		{"letter_p.png", 8, {22, 34}},
		{"letter_t.png", 0, {14, 32}},
		{"letter_o.png", 0, {22, 25}},
		{" ",     0},
		{"letter_g.png", 0, {29, 33}},
		{"letter_a.png", 0, {21, 25}},
		{"letter_m.png", 0, {32, 25}},
		{"letter_e.png", 0, {22, 25}},
		{"letter_s.png", 0, {20, 25}}
	}
	
	local function dropto()
		local xStart = 70
		local yStart = 25
		local letterSpace = 35
		
		physics.start()
		physics.setGravity(0, 5)
		
		logoGround = display.newRect(0, 0, display.contentWidth*2, 2)
		logoGround.x, logoGround.y = display.contentWidth*0.5, display.contentHeight*0.5+15
		logoGround:setFillColor(255, 255, 255)
		logoGround.isVisible = false
		table.insert(tblRemove, logoGround)
		physics.addBody(logoGround, "static", { density=10, friction=1.5, bounce=0.75})
		
		for i=1,#logoImages do
			local image = logoImages[i][1]
			local size = logoImages[i][3]
			if image ~= " " then
				local letter = display.newImageRect(image, size[1], size[2])
				letter.x, letter.y = xStart + (i-1) * letterSpace, yStart
				letter:rotate(math.random(-45, 45))
				physics.addBody(letter, { density=1, friction=1.5, bounce=0.75})
				table.insert(letters, letter)
			else
				table.insert(letters, "space")
			end
		end
	end
	
	local function zapto()
		local xStart = 115
		local yStart = display.contentHeight*0.5+15
		local letterSpace = 3
		local whiteSpace = 10
		local xPos = xStart
		local prevLetter = nil
		
		soundPlay("zapto")
		
		for i=1,#letters do
			local letter = letters[i]
			if letter ~= "space" then
				physics.removeBody(letter)
				
				local yPos = yStart - letter.height*0.5
				local yAdjust = logoImages[i][2]
				
				if i ~= 1 then
					xPos = xPos + prevLetter.width*0.5 + letterSpace + letter.width*0.5
				end
				
				transition.to(letter, { time=500, x=xPos, y=yPos+yAdjust, rotation=0, transition=easing.outQuad })
			
				prevLetter = letter
			else
				-- It's a space.
				xPos = xPos + whiteSpace
			end
		end
	end
	
	local function zaptoFadeout()
		-- Remove ground and stop physics.
		physics.removeBody(logoGround)
		physics.stop()
		
		clearTable(letters)
		clearTable(tblRemove)
		initHomeScreen()
	end
	
	dropto()
	timer.performWithDelay(2500, function(e)
		zapto()
		
		timer.performWithDelay(2000, function()
			zaptoFadeout()
		end)
	end)
end

-- Bug falls. Make the bugs fall into the frogs mouth.
local function startFalls()
	local bugTypes = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm'}
	local function bugFalls()
		if not isFalls then return end
		local delay = 1000 + math.random(1500)
		timer.performWithDelay(delay, function(e)
			deprint("Bug falls.")
			local posX = 95 + math.random(50)
			local type = math.random(#bugTypes)
			
			local bugTable = _bugs[bugTypes[type]]
			
			local bug = display.newImageRect(bugTable.image, bugTable.size[1], bugTable.size[2])
			bug.x, bug.y = posX, -25
			bug.velocity = 0
			bug.acceleration = .025
			
			table.insert(bugs, bug)
			
			bugFalls()
		end)
	end
	
	local function bugFrame(e)
		local endY = 215
		
		for i=1,#bugs do
			local bug = bugs[i]
			if bug == nil then break end
			
			bug.velocity = bug.velocity + bug.acceleration
			bug.y = bug.y + bug.velocity
			
			if bug.y > endY then
				table.remove(bugs, i)
				bug.parent:remove(bug)
				bug = nil
				
				if i ~= #bugs then
					i = i - 1
				end
			end
		end
	end
	
	bugEvent = bugFrame
	
	-- Begin making bugs.
	isFalls = true
	bugFalls()
	Runtime:addEventListener("enterFrame", bugEvent)
end

-- Stop bug falls.
local function stopFalls()
	isFalls = false
	
	for i=1,#bugs do
		local bug = bugs[i]
		if bug ~= nil then
			bug.parent:remove(bug)
			bug = nil
		end
	end
	
	bugs = {}
	Runtime:removeEventListener("enterFrame", bugEvent)
end

-- Display main UI for player to start playing
function initHomeScreen()
	local buttonX = 255
	local buttonStart = 555
	local buttonWidth = 50
	local buttonHeight = 45
	local buttonRadius = 25
	local buttonSpacer = 55
	local buttonTextsize = 12
	
	local tblRemove = {}
	
	local bg = display.newRect(0, 0, 480, 320)
	bg:setFillColor(255, 255, 255)
	
	local bgImage = display.newImageRect("main.png", 480, 320)
	bgImage.x, bgImage.y = display.contentWidth*0.5, display.contentHeight*0.5
	
	local isMale = fileTable['settings_frogie'] == 0
	local imagePrefix = ""
	local height = 160
	if not isMale then 
		imagePrefix = "ms_" 
		height = 172
	end
	local frog = display.newImageRect(imagePrefix.."main-frog.png", 152, height)
	if isMale then
		frog.x, frog.y = 118, 220
	else
		frog.x, frog.y = 118, 210
	end
	
	local bugfallz = display.newImageRect("bugfallz.png", 415, 98)
	bugfallz.x, bugfallz.y = display.contentWidth * 0.5, bugfallz.height*0.5 + 5
	
	-- Scale BugFallz logo up and down
	local isScale = false
	local scaleTimer = timer.performWithDelay(1500, function()
		if isScale then
			transition.to(bugfallz, { time = 1500, xScale = 1, yScale = 1 })
		else
			transition.to(bugfallz, { time = 1500, xScale = 0.85, yScale = 0.85 })
		end
		isScale = not isScale
	end, -1)
	
	local playGroup = display.newGroup()
	local playButton = display.newRoundedRect(0, 0, buttonWidth, buttonHeight, buttonRadius)
	local playText = display.newText("Play", 0, 0, native.systemFont, buttonTextsize)
	playButton.strokeWidth = 3
	playButton:setStrokeColor(150, 150, 150)
	playButton:setFillColor(0, 200, 20)
	playText.x, playText.y = playButton.x, playButton.y
	playText:setTextColor(0, 0, 0)
	playGroup:insert(playButton)
	playGroup:insert(playText)
	playGroup.x, playGroup.y = buttonStart, 145
	
	local levelGroup = display.newGroup()
	local levelButton = display.newRoundedRect(0, 0, buttonWidth, buttonHeight, buttonRadius)
	local levelText = display.newText("Levels", 0, 0, native.systemFont, buttonTextsize)
	levelButton.strokeWidth = 3
	levelButton:setStrokeColor(150, 150, 150)
	levelButton:setFillColor(255, 150, 20)
	levelText.x, levelText.y = levelButton.x, levelButton.y
	levelText:setTextColor(0, 0, 0)
	levelGroup:insert(levelButton)
	levelGroup:insert(levelText)
	levelGroup.x, levelGroup.y = buttonStart, playGroup.y+buttonSpacer
	
	local optionGroup = display.newGroup()
	local optionButton = display.newRoundedRect(0, 0, buttonWidth, buttonHeight, buttonRadius)
	local optionText = display.newText("Options", 0, 0, native.systemFont, buttonTextsize)
	optionButton.strokeWidth = 3
	optionButton:setStrokeColor(150, 150, 150)
	optionButton:setFillColor(0, 170, 220)
	optionText.x, optionText.y = optionButton.x, optionButton.y
	optionText:setTextColor(0, 0, 0)
	optionGroup:insert(optionButton)
	optionGroup:insert(optionText)
	optionGroup.x, optionGroup.y = buttonStart, 170
	
	-- Slide the buttons in.
	local buttons = { playGroup, levelGroup, optionGroup}
	local buttonsX = { buttonX, buttonX + 20, buttonX + 140}
	local buttonIndex = 1
	timer.performWithDelay(75, function(e)
		deprint(buttonIndex)
		transition.to(buttons[buttonIndex], { time = 1500, x = buttonsX[buttonIndex], transition = easing.outExpo})
		buttonIndex = buttonIndex + 1
	end, #buttons)
	
	startFalls()
	
	-- Let them know it's free
	local freeText = nil
	if isFree then
		freeText = display.newText("Free", 0, 0, native.systemFont, 23)
		--freeText:setTextColor(255, 147, 19)
		freeText:setTextColor(0, 0, 0)
		freeText.x = 110
		freeText.y = display.contentHeight - 50
	end
	
	function playButton:tap(event)
		playButton:removeEventListener("tap", playButton)
		timer.cancel(scaleTimer)
		clearTable(tblRemove)
		stopFalls()
		playScreen()
		return true
	end
	
	function levelButton:tap(event)
		levelButton:removeEventListener("tap", levelButton)
		timer.cancel(scaleTimer)
		clearTable(tblRemove)
		stopFalls()
		levelsScreen()
		return true
	end
	
	function optionButton:tap(event)
		optionButton:removeEventListener("tap", optionButton)
		timer.cancel(scaleTimer)
		clearTable(tblRemove)
		stopFalls()
		optionScreen()
		return true
	end
	
	playButton:addEventListener("tap", playButton)
	levelButton:addEventListener("tap", levelButton)
	optionButton:addEventListener("tap", optionButton)
	
	-- Objects to remove
	table.insert(tblRemove, bg)
	table.insert(tblRemove, bgImage)
	table.insert(tblRemove, frog)
	table.insert(tblRemove, bugfallz)
	table.insert(tblRemove, playButton)
	table.insert(tblRemove, playText)
	table.insert(tblRemove, levelButton)
	table.insert(tblRemove, levelText)
	table.insert(tblRemove, optionButton)
	table.insert(tblRemove, optionText)
	table.insert(tblRemove, playGroup)
	table.insert(tblRemove, levelGroup)
	table.insert(tblRemove, optionGroup)
	if isFree then table.insert(tblRemove, freeText) end
	
	-- Load music
	if not soundStarted then
		soundPlay("intro")
		soundStarted = true
	end
	
	-- Instanciate game
	BugFallz = Game:new()
end

function playScreen()
	-- Initiate the game play
	deprint("Play game!")
	soundStarted = false
	soundStop("intro")
	BugFallz:init(1)
end

function levelsScreen()
	-- Display buttons for screen.
	deprint("Levels screen.")
	local tblRemove = {}
	
	local bg = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	bg:setFillColor(255, 150, 20)
	table.insert(tblRemove, bg)
	
	local scoreText = display.newText("Score: " .. tostring(fileTable['points']), 0, 0, native.systemFont, 20)
	scoreText.x, scoreText.y = 25 + scoreText.width*0.5, 20
	scoreText:setTextColor(0, 0, 0)
	
	local startY = 20
	local buttonRadius = 5
	-- Free version settings.
	local buttonWidth = 50
	local buttonHeight = 50
	local buttonSpacer = 25
	local levelsCount = freeLevels
	local perRow = 5
	
	if not isFree then
		buttonWidth = 45
		buttonHeight = 45
		buttonSpacer = 10
		levelsCount = 25
		perRow = 7
	end
	
	-- And one more for the back button.
	levelsCount = levelsCount + 1
	
	local currentLevel = fileTable['level']
	
	for i=1,levelsCount do
		local levelImage = display.newRoundedRect(0, 0, buttonWidth, buttonHeight, buttonRadius)
		
		if i <= currentLevel then
			--levelImage:setFillColor(0, 0, 150),(142, 142, 255)
			levelImage:setFillColor(104, 122, 255)
		else
			levelImage:setFillColor(100, 100, 100)
		end
		
		local text = i
		if i == levelsCount then text = "<" end
		
		local levelText = display.newText(text, 0, 0, native.systemFont, 25)
		local row = math.ceil(i/perRow)
		local xpos = i % perRow
		if xpos == 0 then 
			xpos = perRow
		end
		
		-- Make the Left arrow always be the first element in the last row.
		if i == levelsCount and xpos ~= 1 then
			xpos = 1
			row = row + 1
		end
		
		levelImage.x, levelImage.y = levelImage.width*xpos + (xpos-1)*buttonSpacer, levelImage.height*row + (row-1)*buttonSpacer + startY
		levelText.x, levelText.y = levelImage.x, levelImage.y
		
		table.insert(tblRemove, levelImage)
		table.insert(tblRemove, levelText)
		
		local function levelEvent(e)
			if i ~= levelsCount then
				if i <= currentLevel + 1 then
					levelImage:removeEventListener("tap", levelEvent)
					clearTable(tblRemove)
					soundStarted = false
					soundStop("intro")
					-- Load level i
					BugFallz:init(i)
				else
					deprint("You don't have access to this level.")
				end
			else
				-- Go back to home screen
				levelImage:removeEventListener("tap", levelEvent)
				clearTable(tblRemove)
				initHomeScreen()
			end
			return true
		end
		
		levelImage:addEventListener("tap", levelEvent)
	end
end

function optionScreen()
	-- Display player options/settings.
	deprint("Options screen")
	local tblRemove = {}
	local textX = 95
	local startX = 160
	local yPos = 30
	local colorActive = {90, 200, 255}
	local colorInactive = {0, 170, 220}
	local hasGyro = system.hasEventSource("gyroscope")
	-- To disable vibrate on the Nook.
	local isNook = true--BugFallz:getPlatform() == "Nook Color"
	
	local settings = {
		gyro = fileTable['settings_gyro'],
		music = fileTable['settings_music'],
		vibrate = fileTable['settings_vibrate'],
		frogie = fileTable['settings_frogie'],
		reset = 0
	}
	
	local bg = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	bg:setFillColor(0, 170, 220)
	
    local controlsText = display.newText("Controls:", 0, 0, native.systemFont, 18)
	controlsText.x, controlsText.y = textX - controlsText.width*0.5, yPos
    controlsText:setTextColor(0,0,0)
	
	-- UIPad Button
	local uipadRect = display.newRoundedRect(0, 0, 100, 40, 5)
	local uipadText = display.newText("Screen", 0, 0, native.systemFont, 18)
	uipadRect.x, uipadRect.y = startX, yPos
	uipadText.x, uipadText.y = uipadRect.x, uipadRect.y
	uipadRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
	uipadText:setTextColor(0,0,0)
	uipadRect.isHitTestable = true
	
	-- Gyroscope Button
	local gyroRect = display.newRoundedRect(0, 0, 100, 40, 5)
	local gyroText = display.newText("Gyroscope", 0, 0, native.systemFont, 18)
	gyroRect.x, gyroRect.y = startX + 125, yPos
	gyroText.x, gyroText.y = gyroRect.x, gyroRect.y
	gyroRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
	gyroText:setTextColor(0,0,0)
	gyroRect.isHitTestable = true
	
	if not hasGyro then
		gyroRect:setFillColor(100, 100, 100)
	end
	
	if settings['gyro'] == 1 then
		uipadRect.isVisible = false
	else
		if hasGyro then gyroRect.isVisible = false end
	end
	
	local function settingGyro(e)
		if e.target == uipadRect then
			deprint("Settings uipad.")
			settings['gyro'] = 0
			uipadRect.isVisible = true
			if hasGyro then gyroRect.isVisible = false end
		elseif e.target == gyroRect then
			deprint("Settings gyro.")
			settings['gyro'] = 1
			gyroRect.isVisible = true
			uipadRect.isVisible = false
		end
		return true
	end
	
	uipadRect:addEventListener("tap", settingGyro)
	if hasGyro then	gyroRect:addEventListener("tap", settingGyro) end
	
	yPos = yPos + 45
	
	local musicText = display.newText("Music:", 0, 0, native.systemFont, 18)
	musicText.x, musicText.y = textX - musicText.width*0.5, yPos
	musicText:setTextColor(0,0,0)
	
	local musicRect = display.newRoundedRect(0, 0, 25, 25, 5)
	musicRect.x, musicRect.y = startX - 35, yPos
	musicRect.strokeWidth = 3
	musicRect:setStrokeColor(0, 0, 0)
	
	if settings['music'] == 0 then
		musicRect:setFillColor(colorInactive[1], colorInactive[2], colorInactive[3])
	else
		musicRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
	end
	
	local function settingMusic(e)
		deprint("Settings music.")
		if settings['music'] == 0 then
			settings['music'] = 1
			musicRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
		else
			settings['music'] = 0
			musicRect:setFillColor(colorInactive[1], colorInactive[2], colorInactive[3])
		end
		return true
	end
	
	musicRect:addEventListener("tap", settingMusic)
	
	yPos = yPos + 45
	
	local vibrateText = nil
	local vibrateRect = nil
	local settingVibrate = nil
	
	if not isNook then
		vibrateText = display.newText("Vibrate:", 0, 0, native.systemFont, 18)
		vibrateText.x, vibrateText.y = textX - vibrateText.width*0.5, yPos
		vibrateText:setTextColor(0,0,0)
		
		vibrateRect = display.newRoundedRect(0, 0, 25, 25, 5)
		vibrateRect.x, vibrateRect.y = startX - 35, yPos
		vibrateRect.strokeWidth = 3
		vibrateRect:setStrokeColor(0, 0, 0)
		
		if settings['vibrate'] == 0 then
			vibrateRect:setFillColor(colorInactive[1], colorInactive[2], colorInactive[3])
		else
			vibrateRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
		end
		
		settingVibrate = function(e)
			deprint("Settings vibrate.")
			if settings['vibrate'] == 0 then
				settings['vibrate'] = 1
				vibrateRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
			else
				settings['vibrate'] = 0
				vibrateRect:setFillColor(colorInactive[1], colorInactive[2], colorInactive[3])
			end
			return true
		end
		
		vibrateRect:addEventListener("tap", settingVibrate)
		
		yPos = yPos + 45
	end
	
	local frogieText = display.newText("Frogie:", 0, 0, native.systemFont, 18)
	frogieText.x, frogieText.y = textX - frogieText.width*0.5, yPos
	frogieText:setTextColor(0,0,0)
	
	local mrRect = display.newRoundedRect(0, 0, 100, 40, 5)
	local mrText = display.newText("Mr.", 0, 0, native.systemFont, 18)
	mrRect.x, mrRect.y = startX, yPos
	mrText.x, mrText.y = mrRect.x, mrRect.y
	mrRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
	mrText:setTextColor(0,0,0)
	mrRect.isHitTestable = true
	
	local msRect = display.newRoundedRect(0, 0, 100, 40, 5)
	local msText = display.newText("Ms.", 0, 0, native.systemFont, 18)
	msRect.x, msRect.y = startX + 125, yPos
	msText.x, msText.y = msRect.x, msRect.y
	msRect:setFillColor(230, 115, 210)
	msText:setTextColor(0,0,0)
	msRect.isHitTestable = true
	
	if settings['frogie'] == 0 then
		msRect.isVisible = false
	else
		mrRect.isVisible = false
	end
	
	local function settingFrogie(e)
		if e.target == mrRect then
			deprint("Clicked Mr. Frogie.")
			settings["frogie"] = 0
			mrRect.isVisible = true
			msRect.isVisible = false
		elseif e.target == msRect then
			deprint("Clicked Ms. Frogie.")
			settings["frogie"] = 1
			msRect.isVisible = true
			mrRect.isVisible = false
		end
		return true
	end
	
	mrRect:addEventListener("tap", settingFrogie)
	msRect:addEventListener("tap", settingFrogie)
	
	yPos = yPos + 45
	
	local resetText = display.newText("Reset:", 0, 0, native.systemFont, 18)
	resetText.x, resetText.y = textX - resetText.width*0.5, yPos
	resetText:setTextColor(0,0,0)
	
	local noRect = display.newRoundedRect(0, 0, 100, 40, 5)
	local noText = display.newText("No", 0, 0, native.systemFont, 18)
	noRect.x, noRect.y = startX, yPos
	noText.x, noText.y = noRect.x, noRect.y
	noRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
	noText:setTextColor(0,0,0)
	noRect.isHitTestable = true
	
	local yesRect = display.newRoundedRect(0, 0, 100, 40, 5)
	local yesText = display.newText("Yes", 0, 0, native.systemFont, 18)
	yesRect.x, yesRect.y = startX + 125, yPos
	yesText.x, yesText.y = yesRect.x, yesRect.y
	yesRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
	yesText:setTextColor(0,0,0)
	yesRect.isHitTestable = true
	
	if settings['reset'] == 0 then
		yesRect.isVisible = false
	else
		noRect.isVisible = false
	end
	
	yPos = yPos + 40
	
	local disclaimerText = display.newText("Resetting the game will clear all your progress and score.", 0, 0, native.systemFont, 12)
	disclaimerText.x, disclaimerText.y = textX + disclaimerText.width*0.5, yPos
	disclaimerText:setTextColor(0,0,0)
	disclaimerText.isVisible = false
	
	local function settingReset(e)
		if e.target == noRect then
			deprint("Clicked No.")
			settings["reset"] = 0
			noRect.isVisible = true
			yesRect.isVisible = false
			disclaimerText.isVisible = false
		elseif e.target == yesRect then
			deprint("Clicked Yes")
			settings["reset"] = 1
			yesRect.isVisible = true
			noRect.isVisible = false
			disclaimerText.isVisible = true
		end
		return true
	end
	
	noRect:addEventListener("tap", settingReset)
	yesRect:addEventListener("tap", settingReset)
	
	local saveRect = display.newRoundedRect(0, 0, 125, 40, 5)
	local saveText = display.newText("Save & Exit", 0, 0, native.systemFont, 21)
	saveRect.x, saveRect.y = display.contentWidth*0.5 - 100, display.contentHeight - 30
	saveText.x, saveText.y = saveRect.x, saveRect.y
	--saveRect:setFillColor(247, 63, 27)
	saveRect:setFillColor(255, 90, 90)
	saveText:setTextColor(0, 0, 0)	
	
	local exitRect = display.newRoundedRect(0, 0, 125, 40, 5)
	local exitText = display.newText("Exit", exitRect.x, exitRect.y, native.systemFont, 21)
	exitRect.x, exitRect.y = display.contentWidth*0.5 + 100, display.contentHeight - 30
	exitText.x, exitText.y = exitRect.x, exitRect.y
	exitRect:setFillColor(colorActive[1], colorActive[2], colorActive[3])
	exitText:setTextColor(0, 0, 0)
	
	table.insert(tblRemove, bg)
	table.insert(tblRemove, controlsText)
	table.insert(tblRemove, uipadRect)
	table.insert(tblRemove, uipadText)
	table.insert(tblRemove, gyroRect)
	table.insert(tblRemove, gyroText)
	table.insert(tblRemove, musicRect)
	table.insert(tblRemove, musicText)
	table.insert(tblRemove, vibrateRect)
	table.insert(tblRemove, vibrateText)
	table.insert(tblRemove, frogieText)
	table.insert(tblRemove, mrRect)
	table.insert(tblRemove, mrText)
	table.insert(tblRemove, msRect)
	table.insert(tblRemove, msText)
	table.insert(tblRemove, resetText)
	table.insert(tblRemove, noRect)
	table.insert(tblRemove, noText)
	table.insert(tblRemove, yesRect)
	table.insert(tblRemove, yesText)
	table.insert(tblRemove, disclaimerText)
	table.insert(tblRemove, saveRect)
	table.insert(tblRemove, saveText)
	table.insert(tblRemove, exitRect)
	table.insert(tblRemove, exitText)
	
	local function settingExit(e)
		deprint("Setting exit.")
		
		-- Remove event listeners on buttons.
		uipadRect:removeEventListener("tap", settingGyro)
		if hasGyro then gyroRect:removeEventListener("tap", settingGyro) end
		musicRect:removeEventListener("tap", settingMusic)
		if not isNook then vibrateRect:removeEventListener("tap", settingVibrate) end
		mrRect:removeEventListener("tap", settingFrogie)
		msRect:removeEventListener("tap", settingFrogie)
		noRect:removeEventListener("tap", settingReset)
		yesRect:removeEventListener("tap", settingReset)
		saveRect:removeEventListener("tap", settingSave)
		exitRect:removeEventListener("tap", settingExit)
		
		clearTable(tblRemove)
		initHomeScreen()
		return true
	end
	
	function settingSave(e)
		deprint("Setting save.")
		if settings['reset'] == 1 then
			for k,v in pairs(fileTable) do
				fileTable[k] = 0
			end
			fileTable['level'] = 1
		end
		
		fileTable['settings_gyro'] = settings['gyro']
		fileTable['settings_music'] = settings['music']
		fileTable['settings_vibrate'] = settings['vibrate']
		fileTable['settings_frogie'] = settings['frogie']
		
		fileWrite(fileTable)
		
		settingExit(e)
		return true
	end
	
	saveRect:addEventListener("tap", settingSave)
	exitRect:addEventListener("tap", settingExit)
end
