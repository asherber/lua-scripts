function plugindef()
    finaleplugin.RequireScore = true
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.9.1"
    finaleplugin.Date = "2023-06-21"
    finaleplugin.Id = "4aebe066-d648-4111-b8b3-22ac2420c37d"
    finaleplugin.RevisionNotes = [[
        v0.9.1      First internal version
    ]]
    finaleplugin.Notes = [[
        This script will apply the "Hide Staff" staff style to any measures in
        the selected region that do not have any entries.
    ]]

    return "Hide Empty Measures", "Hide Empty Measures",
        "Applies the \"Hide Staff\" staff style to empty measures."
end

local function get_hide_staff_id()
    for s in loadall(finale.FCStaffStyleDefs()) do
        local str = finale.FCString()
        s:GetName(str)
        if str.LuaString:find("Hide Staff") then
            return s.ItemNo
        end
    end
end

local function cell_has_staff_style(m, s, style_id)
    for a in loadall(finale.FCStaffStyleAssigns()) do
        if a.StartMeasure <= m and a.EndMeasure >= m
                and a.Staff == s and a.StyleID == style_id then
            return true
        end
    end
    return false
end

local function hide_empty_measures()
    local hide_staff_id = get_hide_staff_id()
    local region = finenv.Region()
    for m, s in eachcell(region) do
        local cell = finale.FCCell(m, s)
        if not cell:CalcContainsEntries() and not cell_has_staff_style(m, s, hide_staff_id) then
            local assign = finale.FCStaffStyleAssign()
            assign.StyleID = hide_staff_id
            assign.StartMeasure = m
            assign.EndMeasure = m
            assign:SaveNew(s)
        end
    end
end


hide_empty_measures()