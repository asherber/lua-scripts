function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Nick Mazuk, Peter DeVita"
    finaleplugin.Version = "1.0.2"
    return "Playback - Mute Notes", "Playback - Mute Notes", "Mute all the notes in the selected region"
end

function playback_entries_mute(layers_input) -- argument optional
    layers_input = layers_input or {1, 2, 3, 4}
    local layers = {[1] = true, [2] = true, [3] = true, [4] = true}

    for _, v in ipairs(layers_input) do
        layers[v] = false
    end

    for entry in eachentrysaved(finenv.Region()) do
	    entry.Playback = layers[entry.LayerNumber]
    end
end

playback_entries_mute()