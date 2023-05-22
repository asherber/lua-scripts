function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Jari Williamsson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.RevisionNotes = [[
        Edited by Nick Mazuk to give more detailed duration statistics
        ]]
    finaleplugin.Date = "June 26, 2020"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/note_duration_statistics.hash"
    return "Note Duration Statistics", "Note Duration Statistics",
           "Counts the number of each note value in a given region"
end
local totalnotes = 0
local durationstatistics = {}
for e in eachentry(finenv.Region()) do
    if e:IsNote() then
        if durationstatistics[e.Duration] == nil then

            durationstatistics[e.Duration] = 1
        else

            durationstatistics[e.Duration] = durationstatistics[e.Duration] + 1
        end
        totalnotes = totalnotes + 1
    end
end
local durationtable = {
    [finale.NOTE_128TH] = "128th Notes",
    [finale.SIXTYFOURTH_NOTE] = "64th Notes",
    [finale.THIRTYSECOND_NOTE] = "32th Notes",
    [finale.SIXTEENTH_NOTE] = "16th Notes",
    [finale.EIGHTH_NOTE] = "8th Notes",
    [finale.QUARTER_NOTE] = "Quarter Notes",
    [finale.HALF_NOTE] = "Half Notes",
    [finale.WHOLE_NOTE] = "Whole Notes",
    [finale.BREVE] = "Breve",
    [48] = "Dotted 128th Notes",
    [96] = "Dotted 64th Notes",
    [192] = "Dotted 32nd Notes",
    [640] = "Dotted 16th Notes",
    [760] = "Dotted 8th Notes",
    [1536] = "Dotted Quarter Notes",
    [3072] = "Dotted Half Notes",
    [6144] = "Dotted Whole Notes",
    [12288] = "Dotted Breve Notes",
}
userMessage = finale.FCString();
print("Total Count : ", totalnotes)
userMessage:AppendLuaString("Total Count : " .. totalnotes .. userMessage:GetEOL())
for key, value in pairsbykeys(durationstatistics) do
    if durationtable[key] == nil then

        print("EDU duration", key, ":", value)
        userMessage:AppendLuaString("EDU duration " .. key .. " : " .. value .. userMessage:GetEOL())
    else
        print(durationtable[key], ":", value)
        userMessage:AppendLuaString(durationtable[key] .. " : " .. value .. userMessage:GetEOL())
    end
end
local ui = finenv.UI()
ui:AlertInfo(userMessage.LuaString, "Note Durations Statistics")
