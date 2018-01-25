sounds = {
	-- delay is how long to wait before playing the sound again.
	-- isAvailable is false until the delay of last playing the sound has passed.
	zapto = { src = {"zapto.wav"}, ids = {0}, channel = 0, delay = 0, isAvailable = true},
	intro = { src = {"intro.mp3"}, ids = {0}, channel = 0, loops = 1, delay = 0, isAvailable = true},
	level = { src = {"level.mp3"}, ids = {0}, channel = 0, loops=1, delay = 0, isAvailable = true},
	eat = { src = {"wee.wav", "yeehaa.wav"}, ids = {0, 0}, channel = 0, delay = 250, isAvailable = true },
	eat_female = { src = {"wee.wav", "yah-female.wav"}, ids = {0, 0}, channel = 0, delay = 250, isAvailable = true },
	miss = { src = {"huh.wav"}, ids = {0}, channel = 0, delay = 250, isAvailable = true  },
	miss_female = { src = {"huh-female.wav"}, ids = {0}, channel = 0, delay = 250, isAvailable = true },
	hurt = { src = {"pain.wav", "pain2.wav"}, ids = {0, 0}, channel = 0, delay = 250, isAvailable = true },
	hurt_female = { src = {"pain2.wav", "pain-female.mp3"}, ids = {0, 0}, channel = 0, delay = 250, isAvailable = true },
	splat = { src = {"splat.wav", "splat2.wav", "splat3.wav"}, ids = {0, 0, 0}, channel = 0, delay = 250, isAvailable = true },
	heart = { src = {"yeehoo.wav"}, ids = {0}, channel = 0, delay = 0, isAvailable = true },
	heart_female = { src = {"scat.mp3"}, ids = {0}, channel = 0, delay = 0, isAvailable = true },
	win = { src = {"youwin.wav"}, ids = {0}, channel = 0, delay = 0, isAvailable = true },
	lost = { src = {"youlose.wav"}, ids = {0}, channel = 0, delay = 0, isAvailable = true },
	applause = { src = {"applause.mp3"}, ids = {0}, channel = 0, delay = 0, isAvailable = true}
}

-- Handles the playing of sound by reusing opened channels.
function soundPlay(name)
	local sound = sounds[name]
	if sound then
		-- Randomize the sounds
		local soundIndex = math.random(#sound.src)
		deprint("Sound Index: " .. tostring(soundIndex))
		local soundSrc = sound.src[soundIndex]
		local soundDelay = sound.delay
		local isAvailable = sound.isAvailable
		
		if isAvailable then
			deprint("Sound is available")
			local soundID = sound.ids[soundIndex]
			if soundID == 0 then soundID = audio.loadSound(soundSrc) end
			if sound.loops then
				deprint("Loop sound")
				sound.channel = audio.play(soundID, {loops = -1})
			else
				sound.channel = audio.play(soundID)
			end
				
			if soundDelay ~= nil and soundDelay > 0 then
				deprint("Disabling sound.")
				sound.isAvailable = false
				timer.performWithDelay(soundDelay, function(e)
					deprint("Re-enabling sound.")
					sound.isAvailable = true
				end)
			end
		else
			deprint("Sound is not available.")
		end
	end
end

function soundStop(name)
	local sound = sounds[name]
	local channel = sound.channel
	audio.stop(channel)
end
