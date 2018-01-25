require("file")
require("utils")
require("ui")

DEBUG = false

fileTable = nil

-- Count of free levels.
freeLevels = 5
-- Is it the free or pro version?
isFree = false

-- startApp is the main function that starts the app. After, initHomeScreen() is called.
-- which displays further options for the player.
local function startApp()
	display.setStatusBar(display.HiddenStatusBar)
	system.setIdleTimer(false) -- turn off device sleeping
	initSplash()
	--initHomeScreen()
end

-- Create or load file.
local function loadFile()
	-- Check first load
	local path = system.pathForFile( "save.txt", system.DocumentsDirectory )
	local file = io.open(path, "r")
	if file then
		-- Read the file and and load it's contents in a table.
		deprint("File exists.")
		fileTable = fileRead()
	else
		-- This is possibly the first run. Create the file with the predefined values.
		deprint("File doesn't exist.")
		local vibrate = 0
		local gyro = 0
		--if system.hasEventSource("gyroscope") then gyro = 1 end
		
		if isFree then
			fileTable = { settings_gyro = gyro, settings_vibrate = vibrate, settings_music = 1, settings_frogie = 0, level = 1, points = 0, level1 = 0, level2 = 0, level3 = 0, level4 = 0}
		else
			fileTable = { settings_gyro = gyro, settings_vibrate = vibrate, settings_music = 1, settings_frogie = 0, level = 1, points = 0, level1 = 0, level2 = 0, level3 = 0, level4 = 0, level5 = 0, level6 = 0, level7 = 0, level8 = 0, level9 = 0, level10 = 0, level11 = 0, level12 = 0, level13 = 0, level14 = 0, level15 = 0, level16 = 0, level17 = 0, level18 = 0, level19 = 0, level20 = 0, level21 = 0, level22 = 0, level23 = 0, level24 = 0, level25 = 0}
		end
		
		fileWrite(fileTable)
	end	
end

-- Wrapper around print.
function deprint(m)
	if DEBUG then print(m) end
end

-- Load file into fileTable.
loadFile()

-- Start the game.
startApp()


-- Handle System events.
local function resumeGame(e)
	if "clicked" == e.action then
		deprint("Game resume.")
		BugFallz:resume()
	end
end

local function systemEvent(e)
	if "applicationStart" == e.type then
		deprint("Application started.")
	elseif "applicationExit" == e.type then
		deprint("Application exited.")
		os.exit()
	elseif "applicationSuspend" == e.type then
		deprint("Application suspended.")
		if not BugFallz.isPaused then
			if _isPlaying then
				BugFallz:pause()
			else
				BugFallz:pauseSilent()
			end
		end
	elseif "applicationResume" == e.type then
		deprint("Application resumed.")
		if not _isPlaying then
			native.showAlert("Game Paused.", "Tap OK to continue.", {"OK"})
			BugFallz:resume()
		end
	end
end

Runtime:addEventListener("system", systemEvent)