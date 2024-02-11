function plugindef()    
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.0"
    finaleplugin.Date = "May 17, 2022"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        This script beams together any notes or rests in the selected region that can
        be beamed together and breaks beams that cross into or out of the selected
        region at the boundaries of the selected region. The beam options in Finale’s
        Document Settings determine whether rests can be included at the start or end of a beam.
        If you select multiple staves vertically, you can create the same beaming pattern
        across all the staves with a single invocation of the script.

        It does *not* create beams over barlines.

        By default, the plugin installs two menu options, one to beam the selected region and
        the other to unbeam the selected region. You can instead unbeam all notes in the selected region
        by invoking the "Beam Selected Region" menu option with the Option key pressed (macOS) or
        the Shift key pressed. This is identical to invoking the "Unbeam Selected Region" menu option.

        This script could be particularly useful if you assign it a keystroke using a keyboard macro utility.
    ]]
    finaleplugin.AdditionalMenuOptions = [[
        Unbeam Selected Region
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Unbeam Selected Region
    ]]
    finaleplugin.AdditionalPrefixes = [[
        do_unbeam = true
    ]]
    return "Beam Selected Region", "Beam Selected Region", "Beam Selected Region"
end

local note_entry = require("library.note_entry")

function beam_selected_region()

    local first_in_beam = true
    local first_in_beam_v2 = false
    local curr_staff = 0
    local curr_layer = -1

    for entry in eachentrysaved(finenv.Region()) do
        if (curr_staff ~= entry:GetStaff()) or (curr_layer ~= entry:GetLayerNumber()) then
            first_in_beam = true
            first_in_beam_v2 = true
            curr_staff = entry:GetStaff()
            curr_layer = entry:GetLayerNumber()
        end
        local isV2 = entry:GetVoice2()
        if not isV2 then
            first_in_beam_v2 = true
        end
        if entry:GetDuration() < finale.QUARTER_NOTE then -- less than quarter note duration
            if do_unbeam then
                entry:SetBeamBeat(true)
            elseif (not isV2 and first_in_beam) or (isV2 and first_in_beam_v2) then
                entry:SetBeamBeat(true)
                if not isV2 then
                    first_in_beam = false
                else
                    first_in_beam_v2 = false
                end
            else
                entry:SetBeamBeat(false)
            end
            local next_entry = note_entry.get_next_same_v(entry)
            if (nil ~= next_entry) and (next_entry:GetDuration() < finale.QUARTER_NOTE) and not finenv.Region():IsEntryPosWithin(next_entry) then
                next_entry:SetBeamBeat(true)
            end
        end
    end
end

if do_unbeam == nil then
    do_unbeam = finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT)
end
beam_selected_region()
