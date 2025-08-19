if file.Exists("sound/items/spraycan_spray.wav", "GAME") then
	local soundData = sound.GetProperties("SprayCan.Paint")
	soundData.sound = "items/spraycan_spray.wav"
	sound.Add(soundData)
end
