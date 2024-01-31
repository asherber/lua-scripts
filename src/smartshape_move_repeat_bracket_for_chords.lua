function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Michael McClennan"
    finaleplugin.Copyright = "©2021 Michael McClennan"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "May 22, 2021"
    finaleplugin.AuthorEmail = "info@michaelmcclennan.com"
    return "Move Repeat Brackets for Chords", "Move Repeat Brackets for Chords", ""
end

local region = finenv.Region()
for measure = region.StartMeasure, region.EndMeasure do
    local baseline = finale.FCBaseline()
    baseline:LoadDefaultForMode(3)
    local bracket_position = baseline.VerticalOffset - 145
    local offset = 72 -- sets how far above the chord baseline the brackets should go (in EVPUs)

    local repeat_ending = finale.FCEndingRepeat()
    if repeat_ending:Load(measure) then
        repeat_ending.VerticalTopBracketPosition = bracket_position + offset -- adjusts bracket height
        repeat_ending.VerticalRightBracketPosition = bracket_position + offset -- adjusts bracket height
        repeat_ending.VerticalTextPosition = bracket_position + offset + 25 -- **height of repeat text
        repeat_ending:Save()
    end

    for measure = region.StartMeasure, region.EndMeasure do   -- luacheck: ignore measure
        local backwards_repeat = finale.FCBackwardRepeat()
        if backwards_repeat:Load(measure) then
            backwards_repeat.TopBracketPosition = bracket_position + offset -- adjusts backwards repeat bracket height
            backwards_repeat:Save()
        end
    end
end
