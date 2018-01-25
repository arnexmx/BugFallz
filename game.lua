require("bugs")
require("sounds")
local physics = require("physics")
local movieclip = require("movieclip")

Game = {}
Game.__mt = {__index = Game}
function Game:new()
	local self = {}
	setmetatable(self, Game.__mt)
	
	self.tblRemove = {}
	
	self.frameEvent = nil
	self.gyroEvent = nil
	self.padEvent = nil			-- Event for the pad touch.
	self.playerEvent = nil		-- Event for the player collisions.
	self.floorEvent = nil		-- Event for the floor collisions.
	self.animationTimer = nil	-- Timer to reset animation to frame 1.
	self.inputX = 0
	self.gyroAngle = 0			-- Angle of gyroscope
	self.hasGyro = system.hasEventSource("gyroscope") and fileTable['settings_gyro'] == 1
	self.hasVibrate = fileTable['settings_vibrate'] == 1
	self.centerX = display.contentWidth * 0.5
	self.centerY = display.contentHeight * 0.5
	self.isMale = fileTable['settings_frogie'] == 0
	self.background = nil
	self.skyGradient = nil
	self.skyBackground = nil
	self.floorBackground = nil
	self.floor = nil
	self.player = nil
	self.playerShadow = nil
	self.pointsText = nil
	self.healthBg = nil
	self.healthMeter = nil
	self.pauseButton = nil
	
	self.levelPoints = 0		-- Points earned for that level.
	self.points = 0				-- Total points earned for all played levels.
	self.prevPoints = 0			-- Total points earned upon starting current level.
	self.health = 100
	self.healthSize = .80		-- Percent to decrease the healthMeter.
	self.bugHit = 0
	self.bugMiss = 0
	self.enemyHit = 0
	self.isDead = false
	self.isFinished = false
	self.isPaused = false
	self.pauseDisabled = false
	
	self.moveSpeed = 6
	self.currentLevel = 1
	self.levelChannel = 0
	
	return self
end

-- Starts the whole game.
function Game:init(level)
	deprint("Initializing.")
	physics.start()
	_isPlaying = true
	
	self.tblRemove = {}
	
	self.inputX = 0
	self.gyroAngle = 0
	self.health = 100
	self.isDead = false
	self.isFinished = false
	self.pauseDisabled = false
	self.points = 0
	self.levelPoints = 0
	self.prevPoints = 0
	
	-- Load the background specific to the level.
	self:loadLevel(level)
	
	-- Load the player, images, and objects of the level
	self:loadMain()
	
	-- Load the UI to control the player or use gyroscope if system has one.
	if self.hasGyro then
		self:gyroHandler(true)
	else
		self:screenTouch()
	end
	
	local lastLevel = fileTable['level']
	-- Player is resuming from the last played level, so points accordingly.
	if lastLevel == self.currentLevel then
		local actualPoints = fileTable['points']
		self.points = actualPoints
		self.prevPoints = actualPoints
	end
	
	-- Show teaser when levels equals freeLevels on the free version without the health and points.
	if not isFree or level ~= freeLevels then
		self:infoUI()
	end
	
	-- Set player collision and event handlers.
	self:handleCollisions()
	
	-- Start enterFrame event.
	self:enterFrame(true)
end

function Game:destructor()
	deprint("Garbage collect and remove Game.")
	physics.stop()
	_isPlaying = false
	
	-- Stop the level sound
	audio.stop()
	
	self.health = 100
	self.bugHit = 0
	self.bugMiss = 0
	
	table.insert(self.tblRemove, self.background)
	table.insert(self.tblRemove, self.skyGradient)
	table.insert(self.tblRemove, self.skyBackground)
	table.insert(self.tblRemove, self.floorBackground)
	table.insert(self.tblRemove, self.floor)
	table.insert(self.tblRemove, self.player)
	table.insert(self.tblRemove, self.playerShadow)
	table.insert(self.tblRemove, self.pointsText)
	table.insert(self.tblRemove, self.healthBg)
	table.insert(self.tblRemove, self.healthMeter)
	table.insert(self.tblRemove, self.pauseButton)
	
	-- Stop bugs
	stopBugs()
	
	-- Stop enterFrame
	self:enterFrame(false)
	
	-- Stop gyroHandler
	if self.hasGyro then
		self:gyroHandler(false)
	else
		display.getCurrentStage():removeEventListener("touch", self.padEvent)
	end
	
	self.player:removeEventListener("collision", self.playerEvent)
	self.floor:removeEventListener("touch", self.floorEvent)
	
	clearTable(self.tblRemove)
end

-- Starts a new game at level n if there's a game already running.
function Game:restart(n)
	-- Set points back to its initial value.
	self.points = self.prevPoints

	self:destructor()
	self:init(n)
end

-- Load level specific modules.
function Game:loadLevel(n)
	deprint("Loading level: " .. tostring(n))
	local tblRemove = {}
	
	-- Set the current level
	self.currentLevel = n
	
	-- Load level file and set prop table.
	initBugs(n)
	
	local delay = tonumber(levelProp('delay'))
	local gravity = tonumber(levelProp('gravity'))
	local music = levelProp('music')
	
	physics.setGravity(0, gravity)
	
	self.skyBackground = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	-- Show blue background at the teaser level, otherwise show regular level.
	if not isFree or n ~= freeLevels then
		self.skyBackground:setFillColor(tonumber(levelProp('red')), tonumber(levelProp('green')), tonumber(levelProp('blue')))
	else
		self.skyBackground:setFillColor(108, 137, 254)
	end
	
	self.skyGradient = display.newImageRect("skygradient.png", 480, 320)
	self.skyGradient.x, self.skyGradient.y = self.centerX, self.centerY
	
	self.background = display.newImageRect("bg.png", 480, 320)
	self.background.x, self.background.y = self.centerX, self.centerY
	
	self.floorBackground = display.newImageRect("floorbg.png", 480, 25)
	self.floorBackground.x, self.floorBackground.y = self.centerX, display.contentHeight - self.floorBackground.height*0.5 + 12
	
	if not isFree or n ~= freeLevels then
		-- Show level number and name
		local lName = levelProp('name')
		deprint(lName)
		local lNumber = "Level " .. tostring(n)
		if lName == nil then 
			lName = ""
		else
			lNumber = lNumber .. ":"
		end
		local levelNumber = display.newText(lNumber, 0, 0, native.systemFont, 25)
		local levelName = display.newText(lName, 0, 0, native.systemFont, 20)
		levelNumber.x, levelNumber.y = self.centerX, self.centerY - levelNumber.height * 0.5
		levelName.x, levelName.y = self.centerX, levelNumber.y + 30
		
		table.insert(tblRemove, levelNumber)
		table.insert(tblRemove, levelName)
		
		timer.performWithDelay(2000, function (ev)
			transition.to(levelNumber, { time = 1000, alpha = 0 })
			transition.to(levelName, { time = 1000, alpha = 0, onComplete= function( e )
				clearTable(tblRemove)
			end})
		end)
	end
	
	-- Show teaser at level 10 on the free version.
	if isFree and n == freeLevels then
		self:showTeaser()
	else
		-- Start the timer
		startBugs(delay)
	end
	
	-- Make the moveSpeed faster on levels greater than 10.
	if n >= 10 then self.moveSpeed = 7 end
	
	-- Play the level sound
	if music and fileTable['settings_music'] == 1 then
		local soundID = audio.loadSound(music)
		self.levelChannel = audio.play(soundID, {loops = -1})
	end
end

-- Load the bare game, without the levels dependent objects.
function Game:loadMain()
	self.floor = display.newRect(0, 0, display.contentWidth, 20)
	self.floor:setFillColor(150, 0, 0)
	self.floor.y = display.contentHeight
	self.floor.isVisible = false;
	
	-- Image prefix if it's female.
	local imagePrefix = ""
	local height = 53
	if not self.isMale then 
		imagePrefix = "ms_" 
		height = 57
	end
	
	self.playerShadow = display.newImageRect("playershadow.png", 81, 10)
	
	-- Images size may need proper suffix for each device.
	self.player = movieclip.newAnim({imagePrefix.."frog-50.png", imagePrefix.."frog-eating-50.png", imagePrefix.."frog-dead-50.png", imagePrefix.."frog-badeat-50.png", "frog-dollars-50.png", imagePrefix.."frog-neutral-50.png", imagePrefix.."frog-heart-50.png"}, 50, height)
	self.player.x, self.player.y = self.centerX, display.contentHeight - self.floor.height - self.player.height*0.5 + 12
	
	local shadowPos = 24
	if not self.isMale then shadowPos = 28 end
	self.playerShadow.x, self.playerShadow.y = self.player.x, self.player.y + shadowPos
	
	if isFree and self.currentLevel == freeLevels then
		self:playEvent("rich")
	end
	
	physics.addBody( self.player, "static", { density=1.0, friction=0, bounce=0, filter={categoryBits=1, maskBits=2} } )
	physics.addBody( self.floor, "static", { density=1.0, friction=0, bounce=0, filter={categoryBits=1, maskBits=2} } )
end

-- Load sounds
function Game:getPlatform()
	local platformName = system.getInfo("platformName")
	local modelName = system.getInfo("model")
	
	local isAndroid = "Android" == platformName
	local isIphone = "iPhone OS" == platformName
	local isSimulator = "simulator" == platformName
	
	return platformName
end

-- Gyroscope events
function Game:gyroHandler( bool )
	local function gyroUpdate( event )
		-- Control the player with the gyroscope, instead of UIPad.
		local deltaRadians = event.zRotation * event.deltaTime
		local deltaDegrees = deltaRadians * (180 / math.pi)
		self.gyroAngle = self.gyroAngle + deltaDegrees
		--self.gyroText.text = tostring(self.gyroAngle)
		
		local maxAngle = 10
		
		self.gyroAngle = math.min(self.gyroAngle, maxAngle)
		self.gyroAngle = math.max(self.gyroAngle, -maxAngle)
		
		local actualAngle = -self.gyroAngle
		
		local percent =  actualAngle / maxAngle
		
		self.inputX = percent
	end
	
	if self.gyroEvent == nil then
		self.gyroEvent = gyroUpdate
	end
	
	if bool then
		Runtime:addEventListener("gyroscope", self.gyroEvent)
	else
		Runtime:removeEventListener("gyroscope", self.gyroEvent)
		self.gyroEvent = nil
	end
end

-- Handle touch input from screen.
function Game:screenTouch()
	local startX = 0
	local prevX = 0
	local currentX = 0
	local prevTime = 0
	local currentTime = 0
	local maxSpeed = 100
	local maxDistance = 125
	
	local function padEvent(e)
		if "began" == e.phase then
			prevX, currentX = e.x, e.x
			prevTime, currentTime = e.time, e.time
		elseif "moved" == e.phase then
			prevX = currentX
			prevTime = currentTime
			currentX = e.x
			currentTime = e.time
		elseif "ended" == e.phase then
			print("Event ended.")
			return true
		end
		
		local speed = currentX - prevX
		
		speed = math.min(speed, maxSpeed)
		speed = math.max(speed, -maxSpeed)
		
		local percent = speed / maxSpeed
		self.inputX = self.inputX + percent
		
		self.inputX = math.min(self.inputX, 1)
		self.inputX = math.max(self.inputX, -1)
		--deprint(self.inputX)
		return true
	end
	
	local function padEvent2(e)
		if "began" == e.phase then
			startX = e.x
			prevTime = e.time
		elseif "moved" == e.phase then
			currentX = e.x
			currentTime = e.time
		elseif "ended" == e.phase then
			--prevX = currentX
			--currentX = startX
			print("Event ended.")
		end
		
		local distance = currentX - startX
		
		distance = math.min(distance, maxDistance)
		distance = math.max(distance, -maxDistance)
		
		local percent = distance / maxDistance
		self.inputX = percent
		deprint(percent)
		return true
	end
	
	self.padEvent = padEvent
	
	display.getCurrentStage():addEventListener("touch", self.padEvent)
end

function Game:infoUI()
	-- Points count in the top center.
	local fromRight = 100
	local points = self.points
	
	self.pointsText = display.newText(tostring(points), display.contentWidth-fromRight, 10, native.systemFont, 20)
	
	-- Health meter background
	self.healthBg = display.newRect(15, 10, 10, self.health * self.healthSize)
	self.healthBg:setFillColor(100, 100, 100)
	
	-- Health meter for frog on the top right
	self.healthMeter = display.newRect(15, 10, 10, self.health * self.healthSize)
	self.healthMeter:setFillColor(255, 0, 0)
	
	-- Pause Button
	self.pauseButton = display.newImageRect("pause.png", 25, 25)
	self.pauseButton.x, self.pauseButton.y = display.contentWidth-20, 20
	
	local function pauseTap(e)
		if not self.isPaused then
			self:pause()
		end
		return true
	end
	
	self.pauseButton:addEventListener("tap", pauseTap)
end

-- Either activate or disactivate the enterFrame event.
function Game:enterFrame(bool)
	local function frameEvent()
		-- Move frog according to player input or gyroscope position.
		self.player.x = self.player.x + self.inputX * self.moveSpeed
		
		-- Keep the player on the screen
		if self.player.x < self.player.width*0.5 then self.player.x = self.player.width*0.5; self.inputX = 0 end
		if self.player.x > display.contentWidth - self.player.width*0.5 then self.player.x = display.contentWidth - self.player.width*0.5; self.inputX = 0 end
		
		-- Shadow follows player.
		self.playerShadow.x = self.player.x
	end
	
	-- We need to store this instance of frameEvent so we can remove it later.
	if self.frameEvent == nil then
		self.frameEvent = frameEvent
	end
	
	if bool then
		Runtime:addEventListener("enterFrame", self.frameEvent)
	else
		-- Make sure there are no duplicate frame events running.
		Runtime:removeEventListener("enterFrame", self.frameEvent)
		self.frameEvent = nil
	end
end

-- For pausing the game during gameplay.
function Game:pause()
	if self.isPaused or self.pauseDisabled or self.isDead or self.isFinished then return end
	deprint("Game pausing.")
	audio.pause(self.levelChannel)
	stopBugs()
	physics.pause()
	
	self.isPaused = true
	
	system.setIdleTimer(true)
	
	local tblRemove = {}
	
	local fadeRect = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	fadeRect:setFillColor(0, 0, 0)
	fadeRect.alpha = 0.65
	
	local resumeText = display.newText("Resume", 0, 0, native.systemFont, 35)
	local exitText = display.newText("Exit", 0, 0, native.systemFont, 22)
	resumeText.x, resumeText.y = self.centerX, self.centerY
	exitText.x, exitText.y = self.centerX, resumeText.y+50
	
	table.insert(tblRemove, fadeRect)
	table.insert(tblRemove, resumeText)
	table.insert(tblRemove, exitText)
	
	self:enterFrame(false)
	
	-- Disable player input.
	if self.hasGyro then
		Runtime:removeEventListener("gyroscope", self.gyroEvent)
	else
		display.getCurrentStage():removeEventListener("touch", self.padEvent)
	end
	self.inputX = 0
	
	local function resumeTap(e)
		resumeText:removeEventListener("tap", resumeTap)
		clearTable(tblRemove)
		self:resume()
		return true
	end
	
	local function exitTap(e)
		exitText:removeEventListener("tap", exitTap)
		clearTable(tblRemove)
		self:destructor()
		initHomeScreen()
		return true
	end
	
	resumeText:addEventListener("tap", resumeTap)
	exitText:addEventListener("tap", exitTap)
end

-- For pausing the game during home screen.
function Game:pauseSilent()
	if self.isPaused then return end
	deprint("Game pausing.")
	self.isPaused = true
	system.setIdleTimer(true)
	audio.stop()
end

function Game:resume()
	deprint("Game resuming.")
	self.isPaused = false;
	system.setIdleTimer(false)
	
	if _isPlaying then
		-- Resume gameplay.
		audio.resume(self.levelChannel)
		startBugs(rowInterval)
		physics.start()
		
		self:enterFrame(true)
		
		-- Re-enable player input.
		if self.hasGyro then
			Runtime:addEventListener("gyroscope", self.gyroEvent)
		else
			display.getCurrentStage():addEventListener("touch", self.padEvent)
		end
	else
		-- Resume intro song.
		soundPlay("intro")
	end
end

function Game:removeBug(obj)
	local o = obj
	-- Flag to disable collision on object.
	o.isRemoved = true
	o:removeSelf()
end

function Game:handleCollisions(e)
	local function playerCollision (e)
		deprint("Collision with player.")
		-- Don't do collisions if player is dead or finished. Happens when he dies and bugs are still falling.
		if self.isDead or self.isFinished then return end
		
		local obj = e.other.self
		
		-- Don't handle collision on the same object twice.
		if obj.isRemoved == true then
			deprint("Removing dual!!!!")
			return true
		end
		
		if obj.isRemoved == nil then obj.isRemoved = false end
		
		if e.phase == "began" then
			-- Bug collides with frog
			if obj ~= nil and obj.type == "bug" then
				if obj.isEnemy then
					self:playEvent("hurt")
					
					-- Decrease health
					local bugDamage = obj.damage
					
					self.health = self.health - bugDamage
					self:updateHealth()
				else
					-- Special Items
					if obj.bugType == 16 then
						-- 2X Power Up (Not Used)
						deprint("2X Power-Up.")
					elseif obj.bugType == 17 then
						self.health = self.health + obj.damage
						self:updateHealth()
						self:playEvent("heart")
					elseif obj.bugType == 18 then
						deprint("Bug 18.")
					else 
						-- Just a regular bug.
						self:playEvent("eat")
					end
					
					-- Increase points
					self.bugHit = self.bugHit + 1
					
					local bugPoint = obj.points
					self.points = self.points + bugPoint
					self.levelPoints = self.levelPoints + bugPoint
					self.pointsText.text = tostring(self.points)
				end
				
				-- Check if it's the last bug so we can move to the next level.
				if obj.isLast and not self.isDead then
					self.pauseDisabled = true
					timer.performWithDelay(2000, function(e)
						deprint("Bugs finished on player.")
						self:bugsFinished()
					end)
				end
				
				-- Kill the bug
				self:removeBug(obj)
			end
		end -- End phase "began"
		
		return true
	end
	
	self.playerEvent = playerCollision
	self.player:addEventListener("collision", self.playerEvent)

	local function floorCollision (e)
		deprint("Collision with floor.")
		
		local obj = e.other.self
		
		-- Don't handle collision on the same object twice.
		if obj.isRemoved == true then
			deprint("Removing dual!!!!!")
			return true
		end
		
		if obj.isRemoved == nil then obj.isRemoved = false end
		
		if e.phase == "began" then
			-- Bug collides with floor
			if obj ~= nil and obj.type == "bug" then
				self:playEvent("splat")
				if not obj.isEnemy then
					deprint("Bug hit the floor.")
					self.bugMiss = self.bugMiss + 1
					
					self:playEvent("miss")
					self:vibrate()
					
					-- Objects to exclude from penalization, i.e., don't penalize for missing the heart.
					if obj.bugType ~= 17 then
						-- Penalize health for missing
						local bugDamage =  obj.damage
						
						self.health = self.health - bugDamage
						self:updateHealth()
					end
				end
				
				-- Check if it's the last bug so we can move to the next level.
				if obj.isLast and not self.isDead then
					self.pauseDisabled = true
					timer.performWithDelay(2000, function(e)
						deprint("Bugs finished on floor.")
						self:bugsFinished()
					end)
				end
				
				-- Kill the bug
				self:removeBug(obj)
			end
		end -- End phase "began".
		
		return true
	end
	
	self.floorEvent = floorCollision
	self.floor:addEventListener("collision", self.floorEvent)
end

-- Called to update health meter.
function Game:updateHealth()
	-- For the heart, don't go over 100 health.
	if self.health >= 100 then self.health = 100 end
		
	local healthY = 10 + (100 * self.healthSize)
    
	if self.health <= 0 then
		self:playerDead()
		self.healthMeter.height = 0
		self.healthMeter.y = healthY
		-- Hide the healthMeter
		self.healthMeter.alpha = 0
	else
		self.healthMeter.height = self.health * self.healthSize
		self.healthMeter.y = healthY - self.healthMeter.height*0.5
	end
end

-- Player died, so restart level or exit to the home screen.
function Game:playerDead()
	-- playerDead shouldn't be called if bugsFinished is called and vice-versa.
	if self.isDead or self.isFinished then return end
	deprint("Player died.")
	local tblRemove = {}
	
	-- Play lose event and die.
	self:playEvent("die")
	
	self.isDead = true
	
	self.pauseDisabled = true
	
	-- Stop making bugs
	stopBugs()
	
	-- Clear "last bugs"
	clearTable(lastBugs)
	
	-- Stop enterFrame
	self:enterFrame(false)
	
	-- Plays the same level again.
	local restartText = display.newText("Restart", 0, 0, native.systemFont, 35)
	restartText.x, restartText.y = self.centerX, self.centerY
	
	-- Takes them to the initHomeScreen.
	local exitText = display.newText("Exit", 0, 0, native.systemFont, 22)
	exitText.x, exitText.y = self.centerX, restartText.y + 50
	
	table.insert(tblRemove, restartText)
	table.insert(tblRemove, exitText)
	
	local function restartTap(e)
		deprint("Restart pressed.")
		restartText:removeEventListener("tap", restartTap)
		clearTable(tblRemove)
		self:restart(self.currentLevel)
		return true
	end
	
	restartText:addEventListener("tap", restartTap)
	
	local function exitTap(e)
		deprint("Exit pressed.")
		exitText:removeEventListener("tap", exitTap)
		clearTable(tblRemove)
		self:destructor()
		initHomeScreen()
		return true
	end
	
	exitText:addEventListener("tap", exitTap)
end

-- Called by last bug when bugs have finished generating. Reward the player for surviving.
function Game:bugsFinished()
	-- playerDead shouldn't be called if bugsFinished is called and vice-versa.
	if self.isDead or self.isFinished then return end
	deprint("Bugs finished.")
	local tblRemove = {}
	
	self.pauseDisabled = true
	
	-- Stop Bugs(doing it doesn't hurt)
	stopBugs()
	
	-- Stop enterFrame
	self:enterFrame(false)
	
	-- Play win sound!
	self:playEvent("win")
	
	self.isFinished = true
	
	local previousLevel = self.currentLevel
	self.currentLevel = self.currentLevel + 1
	local isLast = self.currentLevel == 26
	
	local percent = math.ceil(self.bugHit / (self.bugHit + self.bugMiss) * 100)
	if self.bugMiss == 0 then percent = 100 end
	
	local percentText = display.newText("", 0, 0, system.nativeFont, 35)
	percentText.x, percentText.y = self.centerX, self.centerY - 30
	
	-- Animate percent.
	local percentValue = 0
	local percentTimer = timer.performWithDelay(20, function(e)
		percentValue = percentValue + 1
		
		if percentValue > percent then percentValue = percent end
		
		percentText.text = "Score: " .. tostring(percentValue) .. "%"
		
		if percentValue == percent then
			if percentValue == 100 then soundPlay("applause") end
			timer.cancel(e.source)
		end
	end, 0)
	
	local textNext = "Next Level"
	if isLast then textNext = "The End" end
	
	local nextText = display.newText(textNext, 0, 0, system.nativeFont, 25)
	nextText.x, nextText.y = self.centerX, percentText.y + 50
	
	-- Save the level progress in our file.
	if self.currentLevel > fileTable.level and self.currentLevel ~= 26 then
		fileTable.level = self.currentLevel
		fileTable.points = self.points
		fileWrite(fileTable)
	end
	
	deprint("Current level is:" .. tostring(previousLevel))
	-- Save the highscore for the level in our file.
	local highscoreText = nil
	local filePoints = fileTable['level'..tostring(previousLevel)]
	if filePoints then
		local highScore = filePoints
		local highPrefix = ""
		if self.levelPoints > filePoints then
			-- New high score
			highPrefix = "New "
			highScore = self.levelPoints
			fileTable['level'..tostring(previousLevel)] = highScore
			fileWrite(fileTable)
		end
		-- High score text
		highscoreText = display.newText(highPrefix .. "High Score: " .. tostring(self.levelPoints), 0, 0, system.nativeFont, 20)
		highscoreText.x, highscoreText.y = nextText.x, nextText.y + 50
	end
	
	table.insert(tblRemove, percentText)
	table.insert(tblRemove, nextText)
	table.insert(tblRemove, highscoreText)
	
	-- Load next level. Show the end credits if it's the last level.
	local function nextTap(e)
		deprint("Next level.")
		timer.cancel(percentTimer)
		nextText:removeEventListener("tap", nextTap)
		clearTable(tblRemove)
		
		if not isLast then
			self:restart(self.currentLevel)
		else
			self:credits()
		end
		
		return true
	end

	nextText:addEventListener("tap", nextTap)
end

-- Handles the playing of animations(key frames) and sounds simultaneously.
-- Events: eat, miss, hurt, die, heart, powerup, lose, win, rich.
-- 1-"frog-50.png", 2-"frog-eating-50.png", 3-"frog-dead-50.png", 4-"frog-badeat-50.png", 5-"frog-dollars-50.png", 6-"frog-neutral-50.png", 7-"frog-heart-50.png"
function Game:playEvent(name)
	-- Prevent from re-animating after death.
	if self.isDead or self.isFinished then return end
	
	-- Eating a good bug
	if name == "eat" then
		self:playAnim(self.player, 2, true)
		if self.isMale then soundPlay("eat") else soundPlay("eat_female") end
	-- Missing any bug
	elseif name == "splat" then
		soundPlay("splat")
	-- Missing a good bug
	elseif name == "miss" then
		self:playAnim(self.player, 6, true)
		if self.isMale then soundPlay("miss") else soundPlay("miss_female") end
	-- Eating a bad bug
	elseif name == "hurt" then
		self:playAnim(self.player, 4, true)
		if self.isMale then soundPlay("hurt") else soundPlay("hurt_female") end
	-- Dieing when health is 0
	elseif name == "die" then
		self:playAnim(self.player, 3)
		soundPlay("lost")
	-- Eating a heart
	elseif name == "heart" then
		self:playAnim(self.player, 7, true, 450)
		if self.isMale then soundPlay("heart") else soundPlay("heart_female") end
	-- Eating a power-up
	elseif name == "powerup" then
		self:playAnim(self.player, 2, true)
		soundPlay("eat")
	-- Winning a level
	elseif name == "win" then
		soundPlay("win")
	-- Rich
	elseif name == "rich" then
		self:playAnim(self.player, 5)
	else
		self:playAnim(self.player, 1)
	end
end

-- Goto a certain frameNum. If goBack is true, then reset to frame 1 after a certain delay.
function Game:playAnim(obj, frameNum, goBack, delay)
	if delay == nil then delay = 150 end
	-- Animations: eat, miss, die, heart, hurt, rich.
	--if obj.animationTimer then timer.cancel(self.animationTimer) end
	obj:stopAtFrame(frameNum)
	if goBack then
		--obj.animationTimer = 
		timer.performWithDelay(delay, function (e)
			if not self.isDead then
				obj:stopAtFrame(1)
			end
		end)
	end
end

-- Does vibrate if the user enables it.
function Game:vibrate()
	if self.hasVibrate then
		system.vibrate()
	end
end

-- Game finished. Show credits.
function Game:credits()
	deprint("Game finished!")
    local tblRemove = {}
	
    -- Disable player input.
	if self.hasGyro then
		Runtime:removeEventListener("gyroscope", self.gyroEvent)
	else
		display.getCurrentStage():removeEventListener("touch", self.padEvent)
	end
	self.inputX = 0
    
    local creditsGroup = display.newGroup()
    local yPos = 0
    
    local zaptoGames = display.newImageRect("zaptogames.png", 246, 43)
    zaptoGames.x, zaptoGames.y = 0, 0
    local bugFallz = display.newImageRect("bugfallz-250.png", 250, 59)
    bugFallz.x, bugFallz.y = 0, 0

	local text1 = display.newText("", 0, 0, native.systemFont, 18)
	text1.text = "Programmer, Design, Levels:"
	local text2 = display.newText("", 0, 0, native.systemFont, 15)
	text2.text = "Wilmar Siqueira"
	local text3 = display.newText("", 0, 0, native.systemFont, 18)
	text3.text = "Levels, Audio:"
	local text4 = display.newText("", 0, 0, native.systemFont, 15)
	text4.text = "Winicius Siqueira"
    local text5 = display.newText("", 0, 0, native.systemFont, 18)
    text5.text = "Special Thanks"
    local text6 = display.newText("", 0, 0, native.systemFont, 15)
    text6.text = "Wellington Siqueira"
    
    creditsGroup.x, creditsGroup.y = self.centerX, display.contentHeight + 50
    
	creditsGroup:insert(zaptoGames)
    creditsGroup:insert(bugFallz)
    creditsGroup:insert(text1)
    creditsGroup:insert(text2)
    creditsGroup:insert(text3)
    creditsGroup:insert(text4)
    creditsGroup:insert(text5)
    creditsGroup:insert(text6)
    
    table.insert(tblRemove, zaptoGames)
    table.insert(tblRemove, bugFallz)
    table.insert(tblRemove, text1)
    table.insert(tblRemove, text2)
    table.insert(tblRemove, text3)
    table.insert(tblRemove, text4)
    table.insert(tblRemove, text5)
    table.insert(tblRemove, text6)
    
    yPos = yPos + 95
    bugFallz.y = yPos
    
    yPos = yPos + 70
    text1.y = yPos
    
    yPos = yPos + 30
    text2.y = yPos
    
    yPos = yPos + 60
    text3.y = yPos
    
    yPos = yPos + 30
    text4.y = yPos
    
    yPos = yPos + 60
    text5.y = yPos

    yPos = yPos + 30
    text6.y = yPos
    
    local function showLove()
    	local oppositeSex = not self.isMale
    	local imagePrefix = ""
    	local height = 53
    	if not oppositeSex then
    		imagePrefix = "ms_"
    		height = 57
    	end
	
    	local friend = display.newImageRect(imagePrefix.."frog-50.png", 50, height)
    	friend.x, friend.y = display.contentWidth + friend.width, self.player.y
    	
    	table.insert(tblRemove, friend)
    	
    	transition.to(friend, { time=8000, x = self.player.x - self.player.width, onComplete=function(e)
    		deprint("Showing love.")
    		timer.performWithDelay(2000, function(e)
    			self.isFinished = false
    			self:playEvent("heart")
    			self.isFinished = true
    			
    			timer.performWithDelay(3000, function(e)
    				clearTable(tblRemove)
    				self:destructor()
    				-- Send them back home.
    				initHomeScreen()
    			end)
    		end)
    	end}) 
    end
    
	transition.to(creditsGroup, {time = 25000, y = -450, onComplete=function(e)
		deprint("Finished credits.")
		showLove()
	end})
end

-- Show teaser on free version at the tenth level.
function Game:showTeaser()
	local thanksText = display.newText("Thank You for Playing!", 0, 0, native.systemFont, 25)
	thanksText.x, thanksText.y = self.centerX, 20
	
	-- BugFallz logo
	local bugFallz = display.newImageRect("BugFallz-250.png", 250, 59)
	bugFallz.x, bugFallz.y = self.centerX, 38 + bugFallz.height * 0.5
	
	local availableText = display.newText("Available Now on:", 0, 0, native.systemFont, 25)
	availableText.x, availableText.y = self.centerX, 115
	
	local platform = self:getPlatform()
	local storeImage = "store-android.png"
	if platform == "Amazon Fire" then
		storeImage = "store-amazon.png"
	elseif platform == "Nook Color" then
		storeImage = "store-nook.png"
	end
	
	-- iPhone Purchase Button
	local iphoneButton = display.newImageRect("store-iphone.png", 192, 84)
	iphoneButton.x, iphoneButton.y = display.contentWidth / 4 + 20, availableText.y - iphoneButton.height * 0.5 + 97
	
	-- Android/Amazon/Nook Purchase Button
	local androidButton = display.newImageRect(storeImage, 192, 84)
	androidButton.x, androidButton.y = display.contentWidth / 4 * 3 - 20, availableText.y - androidButton.height * 0.5 + 97
	
	function iphoneButton:tap(e)
		deprint("iphoneButton tapped.")
		system.openURL("http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=491252448&mt=8")
		return true
	end
	
	function androidButton:tap(e)
		deprint("androidButton tapped.")
		--system.openURL("http://market.android.com/")
		return true
	end
	
	iphoneButton:addEventListener("tap", iphoneButton)
	androidButton:addEventListener("tap", androidButton)
	
	textTimer = timer.performWithDelay(1000, function (e)
		if availableText.alpha == 1 then availableText.alpha = 0
		else availableText.alpha = 1 end
	end, -1)
	
	local scrollerBg = display.newRoundedRect(50, iphoneButton.y + 50, display.contentWidth - 100, 25, 5)
	scrollerBg:setFillColor(100, 100, 100)
	scrollerBg.strokeWidth = 2
	scrollerBg:setStrokeColor(255, 147, 19)
	
	local features = {
		"25+ Levels with Exciting game play.",
		"New bugs to devour. Yummy!",
		"Stronger and More Poisonous bugs than ever!",
		"Power-Ups to aid you on your quest."
	}
	
	local featureText = display.newText("", 0, 0, native.systemFont, 15)
	featureText.x, featureText.y = scrollerBg.x, scrollerBg.y
	featureText.alpha = 0
	
	featureText.text = features[1]
	
	local textPos = 1
	function fadeIn()
		transition.to(featureText, {time = 500, alpha = 1, onComplete=function()
			timer.performWithDelay(5000, function()
				fadeOut()
			end)
		end})
	end
	function fadeOut()
		transition.to(featureText, {time = 500, alpha = 0, onComplete=function()
			textPos = textPos + 1
			if textPos > #features then textPos = 1 end
			featureText.text = features[textPos]
			fadeIn()
		end})
	end
	fadeIn()
end
