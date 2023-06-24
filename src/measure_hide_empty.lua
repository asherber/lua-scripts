function plugindef()
    finaleplugin.RequireScore = true
    finaleplugin.RequireSelection = true
    finaleplugin.RequireDocument = true
    finaleplugin.MinJWLuaVersion = 0.65
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.9.2"
    finaleplugin.Date = "2023-06-24"
    finaleplugin.Id = "4aebe066-d648-4111-b8b3-22ac2420c37d"
    finaleplugin.RevisionNotes = [[
        v0.9.1      First internal version
        v0.9.2      Reuse adjacent staff style assignments
                    Pick from multiple "Hide Staff" staff styles
    ]]
    finaleplugin.Notes = [[
        This script will apply a "Hide Staff" staff style to any measures in
        the selected region that do not have any entries. If you have more
        than one "Hide Staff" staff style defined, you can pick the one
        you want to use.
    ]]

    return "Hide Empty Measures", "Hide Empty Measures",
        "Applies a \"Hide Staff\" staff style to empty measures."
end


local function pick_style(styles)
    if #styles == 0 then
        finenv.UI():AlertInfo('No "Hide Staff" staff style found.', "Error")
        return
    elseif #styles == 1 then
        return next(styles)
    end

    local function make_str(str)
        local s = finale.FCString()
        s.LuaString = str
        return s
    end

    local dialog = finale.FCCustomWindow()
    dialog:SetTitle(make_str('Select "Hide Staff" Style'))

    local group = dialog:CreateRadioButtonGroup(0, 0, #styles)
    local labels = finale.FCStrings()
    local max_width = 0
    for _, style in ipairs(styles) do
        labels:AddCopy(make_str(style[2]))
        max_width = math.max(max_width, style[2]:len() * 6)
    end
    group:SetText(labels)
    group:SetWidth(max_width)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        return styles[group:GetSelectedItem() + 1]
    end
end

local function get_hide_staff_style_id()
    local hide_staff_styles = {}
    for def in loadall(finale.FCStaffStyleDefs()) do
        local str = finale.FCString()
        def:GetName(str)
        if str.LuaString:find("Hide Staff") then
            table.insert(hide_staff_styles, { def.ItemNo, str.LuaString })
        end
    end

    return pick_style(hide_staff_styles)
end

local function get_staff_style_assign(m, s, style_id)
    local assigns = finale.FCStaffStyleAssigns()
    assigns:LoadAllForItem(s)
    for a in each(assigns) do
        if a.StartMeasure <= m and a.EndMeasure >= m
                and a.StyleID == style_id then
            return a
        end
    end
end

local function hide_empty_measures()
    local hide_staff_style_id = get_hide_staff_style_id()
    if not hide_staff_style_id then
        return
    end

    local function get_hide_staff_style_assign(m, s)
        return get_staff_style_assign(m, s, hide_staff_style_id)
    end

    local function is_candidate_cell(m, s)
        local cell = finale.FCCell(m, s)
        return not cell:CalcContainsEntries()
            and not get_hide_staff_style_assign(m, s)
    end


    local document = finale.FCMusicRegion()
    document:SetFullDocument()
    local doc_measure_count = document:CalcMeasureSpan()

    local region = finenv.Region()
    for range_start, staff_id in eachcell(region) do
        if is_candidate_cell(range_start, staff_id) then
            local range_end = range_start

            while region:IsMeasureIncluded(range_end + 1) and is_candidate_cell(range_end + 1, staff_id) do
                range_end = range_end + 1
            end

            local previous_assign = range_start > 1
                and get_hide_staff_style_assign(range_start - 1, staff_id)
            local next_assign = range_end < doc_measure_count
                and get_hide_staff_style_assign(range_end + 1, staff_id)

            if previous_assign then
                previous_assign.EndMeasure = range_end
                previous_assign:Save()
            elseif next_assign then
                next_assign.StartMeasure = range_start
                next_assign:Save()
            else
                local assign = finale.FCStaffStyleAssign()
                assign.StyleID = hide_staff_style_id
                assign.StartMeasure = range_start
                assign.EndMeasure = range_end
                assign:SaveNew(staff_id)
            end

        end
    end
end


hide_empty_measures()