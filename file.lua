function fileRead()
	local path = system.pathForFile( "save.txt", system.DocumentsDirectory )
	local file = io.open(path, "r")
	local content = file:read()
	-- Load all the file properties and values in the tc table.
	local tc = {}
	while content do
		local pos = content:find(":")
		if pos ~= -1 then
			local s1 = content:sub(0, pos-1)
			local s2 = content:sub(pos+1)
			tc[s1] = tonumber(s2)
		end
		content = file:read()
	end
	io.close(file)
	return tc
end

function fileWrite(tbl)
	deprint("Writing file.")
	local path = system.pathForFile( "save.txt", system.DocumentsDirectory )
	local file = io.open( path, "w" )
	for k in pairs(tbl) do
		file:write( k, ":", tbl[k], "\n")
	end
	io.close( file )
end
