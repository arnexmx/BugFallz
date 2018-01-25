-- This function is called throught the game to remove elements in a table from the screen.
function clearTable(tbl)
	for k,v in pairs(tbl) do
		--if v ~= nil and v.parent ~= nil then
		if v ~= nil and type(v) == "table" then
			--v.parent:remove(v)
			v:removeSelf()
		end
		v = nil
	end
	tbl = nil
end

-- Clears a display group.
function clearGroup(grp)
	if grp == nil then return end
	while grp.numChildren ~= 0 do
		local child = grp[1]
		child:removeSelf()
		grp:remove(child)
		child = nil
	end
	grp:removeSelf()
	grp = nil
end

function clearGroups(tbl)
	for i=1,#tbl do
		local group = tbl[i]
		clearGroup(group)
	end
	tbl = nil
end

-- Creates a text shadow effect and returns it in a group.
function newTextShadow(text, size, colors, offset)
	local g = display.newGroup()
	
	local textShadow = display.newText("", 0, 0, native.systemFont, size)
	textShadow.text = text
	textShadow:setTextColor(colors[2][1], colors[2][2], colors[2][3])
	textShadow.x, textShadow.y = textShadow.x + offset, textShadow.y + offset
	
	local textOver = display.newText("", 0, 0, native.systemFont, size)
	textOver.text = text
	textOver:setTextColor(colors[1][1], colors[1][2], colors[1][3])
	
	g:insert(textShadow)
	g:insert(textOver)
	
	return g
end

-- Facilitates changing text shadow text.
function setTextShadow(grp, text)
	grp[1].text = text
	grp[2].text = text
end
