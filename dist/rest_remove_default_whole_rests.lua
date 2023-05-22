function plugindef()
    finaleplugin.Author = "Nick Mazuk"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 26, 2022"
    finaleplugin.CategoryTags = "Rest"
    finaleplugin.MinJWLuaVersion = 0.59
    finaleplugin.Notes = [[
        This script removes all default whole rests from the entire score.
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/rest_remove_default_whole_rests.hash"
    return "Remove default whole rests", "Remove default whole rests",
           "Removes all default whole rests from the entire score"
end
function rest_remove_default_whole_rests()
    for staff in loadall(finale.FCStaves()) do
        staff:SetDisplayEmptyRests()
        staff:Save()
    end
end
rest_remove_default_whole_rests()
