function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.2"
    finaleplugin.Date = "June 12, 2020"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.RequireSelection = true
    return "Add Augmentation Dots", "Add Augmentation Dots",
           "Add an augmentation dot to all notes and rests in selected region."
end

local note_entry = require("library.note_entry")

function note_add_augmentation_dots()
    for entry in eachentrysaved(finenv.Region()) do
        note_entry.add_augmentation_dot(entry)
    end
    finenv.Region():RebeamMusic()
end

note_add_augmentation_dots()
