function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.MinJWLuaVersion = 0.65
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.9.1"
    finaleplugin.Date = "2023-08-05"
    finaleplugin.Id = "a75bc0cf-86fd-40e4-b25b-511ad5c9749d"
    finaleplugin.RevisionNotes = [[
        v0.9.2      Don't need to check for rests while deleting
        v0.9.1      First internal version
    ]]
    finaleplugin.Notes = [[
        This script examines all complete measures in the selected region.
        If a measure contains only rest entries, it deletes all the entries 
        and restores the default whole rest.
    ]]

    return "Use Default Rest", "Use Default Rest",
        "Deletes rest entries in selected measures if there are no note entries."
end


local function has_notes(region)
    for e in eachentry(region) do
        if e:IsNote() then
            return true
        end
    end
end

local function delete_all_entries(region)
    for e in eachentrysaved(region) do
        e.Duration = 0
    end
end

local function region_for_cell(m, s)
    local region = finale.FCMusicRegion()
    region:SetStartMeasure(m)
    region:SetEndMeasure(m)
    region:SetStartStaff(s)
    region:SetEndStaff(s)
    region:SetStartMeasurePosLeft()
    region:SetEndMeasurePosRight()
    return region
end

local function use_default_rest()
    local region = finenv.Region()

    for m, s in eachcell(region) do
        if region:IsFullMeasureIncluded(m) then
            local this_measure = region_for_cell(m, s)
            if not has_notes(this_measure) then
                delete_all_entries(this_measure)
            end
        end
    end
end


use_default_rest()