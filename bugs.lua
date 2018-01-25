_bugs = {
	-- Red Ladybug
	a = {
		bugType = 1,
		isEnemy = false,
		points = 1,
		damage = 2,		-- Damage for hitting the ground, not the enemy
		image = "a.png",
		size = {40, 36}
	},
	-- Brown Six-Legger Bug
	b = {
		bugType = 2,
		isEnemy = false,
		points = 5,
		damage = 2,
		image = "b.png",
		size = {40, 46}
	},
	-- Blue Six-Legger Bug
	c = {
		bugType = 3,
		isEnemy = false,
		points = 7,
		damage = 2,
		image = "c.png",
		size = {40, 46}
	},
	-- Bumble Bee
	d = {
		bugType = 4,
		isEnemy = false,
		points = 100,
		damage = 5,
		image = "d.png",
		size = {40, 33}
	},
	-- Yellow Butterfly
	e = {
		bugType = 5,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "e.png",
		size = {40, 40}
	},
	-- Green Locust
	f = {
		bugType = 6,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "f.png",
		size = {40, 36}
	},
	-- Bumble Twat
	g = {
		bugType = 7,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "g.png",
		size = {40, 39}
	},
	-- Pink Butterfly
	h = {
		bugType = 8,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "h.png",
		size = {40, 37}
	},
	-- Green Worm
	i = {
		bugType = 9,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "i.png",
		size = {40, 36}
	},
	-- Bee Top
	j = {
		bugType = 10,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "j.png",
		size = {40, 32}
	},
	-- Gray Hover
	k = {
		bugType = 11,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "k.png",
		size = {40, 42}
	},
	-- Blue Butterfly
	l = {
		bugType = 12,
		isEnemy = false,
		points = 10,
		damage = 3,
		image = "l.png",
		size = {40, 28}
	},
	-- Colorful Worm
	m = {
		bugType = 13,
		isEnemy = false,
		points = 10,
		damage = 3,
		image = "m.png",
		size = {40, 19}
	},
	-- Green Ladybug
	n = {
		bugType = 14,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "n.png",
		size = {40, 46}
	},
	-- Blue Ladybug
	o = {
		bugType = 15,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "o.png",
		size = {40, 46}
	},
	-- Props
	-- 2X
	p = {
		bugType = 16,
		isEnemy = false,
		points = 0,
		damage = 5,
		image = "p.png",
		size = { 40, 40}
	},
	-- Heart
	q = {
		bugType = 17,
		isEnemy = false,
		points = 0,
		damage = 30,
		image = "q.png",
		size = {40, 36}
	},
	-- Hamburger
	r = {
		bugType = 18,
		isEnemy = false,
		points = 10,
		damage = 5,
		image = "r.png",
		size = {40, 40}
	},
	-- Enemies
	-- Red Tic
	s = {
		bugType = 19,
		isEnemy = true,
		points = 10,
		damage = 10,
		image = "s.png",
		size = {40, 46}
	},
	-- Atom Bug
	t = {
		bugType = 20,
		isEnemy = true,
		points = 0,
		damage = 15,
		image = "t.png",
		size = {40, 46}
	},
	-- Death Mosquito
	u = {
		bugType = 21,
		isEnemy = true,
		points = 10,
		damage = 10,
		image = "u.png",
		size = {40, 34}
	},
	-- Green Viper
	v = {
		bugType = 22,
		isEnemy = true,
		points = 10,
		damage = 15,
		image = "v.png",
		size = {40, 54}
	},
	-- Black Tic
	w = {
		bugType = 23,
		isEnemy = true,
		points = 10,
		damage = 12,
		image = "w.png",
		size = {40, 46}
	},
	-- Red Spider
	x = {
		-- Red tic
		bugType = 24,
		isEnemy = true,
		points = 0,
		damage = 10,
		image = "x.png",
		size = {40, 40}
	},
	-- Another Spider
	y = {
		bugType = 25,
		isEnemy = true,
		points = 0,
		damage = 7,
		image = "y.png",
		size = {55, 31}
	},
	-- Red/Yello Venom
	z = {
		bugType = 26,
		isEnemy = true,
		points = 0,
		damage = 5,
		image = "z.png",
		size = {40, 44}
	}
}

local bugTimer = nil

local bugWidth = 40
local currentRow = 1
local dashSpace = 0
local startY = -100
local levelTable = nil
local levelProperties = nil			-- Stores property values from the first line of the level file.
lastBugs = {}						-- Store last bugs to be removed on restart.	
rowInterval = 0

local function rowLevel(n)
	local levelName = "level" .. tostring(n) ..  ".txt"
	local path = system.pathForFile( levelName, system.ResourceDirectory )
	local levelFile = io.open(path, "r")
	levelTable = {}
	levelProperties = {}
	for line in levelFile:lines() do
		deprint("Line length: " .. #line)
		local firstChar = line:sub(1,1)
		-- Skip comments.
		if firstChar ~= '#' then
			-- Load the settings line into levelProperties.
			if firstChar == '~' then
				-- Settings lines
				for k, v in string.gmatch(line, "(%w+)=([^,]+)") do
					levelProperties[k] = v
					deprint(k)
				end
			else
				table.insert(levelTable, line)
			end
		end
	end
	levelFile:close()

	currentRow = #levelTable
	local rowLength = #levelTable[currentRow]
	dashSpace = display.contentWidth / rowLength
	deprint("Dash space: " .. tostring(dashSpace))
	deprint("rowLength: " .. tostring(rowLength))
end

local function rowTicker()
	local row = levelTable[currentRow]
	for i = 1,#row do
		local rowItem = row:sub(i,i)
		if rowItem ~= '-' then
			local newBug = display.newImageRect(_bugs[rowItem].image, _bugs[rowItem].size[1], _bugs[rowItem].size[2])
			
			newBug.x, newBug.y = i*dashSpace - bugWidth/2, startY
			
			newBug.self = newBug
			newBug.type = "bug"
			newBug.bugType = _bugs[rowItem].bugType
			newBug.isEnemy = _bugs[rowItem].isEnemy
			newBug.points = _bugs[rowItem].points
			newBug.damage = _bugs[rowItem].damage
			-- So we know when the last bug has collided.
			newBug.isLast = currentRow == 1
			
			if newBug.isLast then
				deprint("Making the last bugs.")
				table.insert(lastBugs, newBug)
			end
			
			physics.addBody(newBug, { density=1, friction=0, bounce=0, filter={categoryBits=2, maskBits=1} })
		end
	end
	currentRow = currentRow - 1
	-- Reached the end of the level, so stop making bugs.
	if currentRow == 0 then stopBugs() end
end

function levelProp(name)
	return levelProperties[name]
end

function initBugs(n)
	lastBugs = {}
	rowLevel(n)
end

function startBugs(n)
	rowInterval = n
	bugTimer = timer.performWithDelay(n, rowTicker, -1)
end

function stopBugs()
	deprint("Killed the timer.")
	if bugTimer then
		timer.cancel(bugTimer)
	end
end
