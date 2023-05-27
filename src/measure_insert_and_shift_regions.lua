function plugindef()
    finaleplugin.RequireScore = true
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.9.1"
    finaleplugin.Date = "2023-05-27"
    finaleplugin.Id = "1fef3a2d-42c3-4ab1-a75a-6f245c6b5ec2" 
    finaleplugin.RevisionNotes = [[
        v0.9.1      First internal version
    ]]
    finaleplugin.Notes = [[
        This script will insert one or more measures and will adjust current and following
        measure number regions.
    ]]

    return "Insert Measure(s) and Shift Regions", "Insert Measure(s) and Shift Regions", 
        "Inserts one or more measures and adjusts measure number regions"
end


function measure_insert_and_shift_regions()
    local region = finenv.Region()
    local insert_pos = region.StartMeasure
    local insert_count = region:CalcMeasureSpan()

    finale.FCMeasures.Insert(insert_pos, insert_count, true)

    for r in loadall(finale.FCMeasureNumberRegions()) do
        if r.StartMeasure > insert_pos then
            r.StartMeasure = r.StartMeasure + insert_count
            
            local str = finale.FCString()
            r:GetPrefix(str)
            local prefix = str.LuaString
            
            if prefix == '' then
                r.StartNumber = r.StartNumber + insert_count
            else
                str.LuaString = prefix + insert_count
                r:SetPrefix(str)
            end
        end
        if r.EndMeasure >= insert_pos then
            r.EndMeasure = r.EndMeasure + insert_count
        end
        r:Save()
    end
end

measure_insert_and_shift_regions()