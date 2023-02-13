function plugindef()
    finaleplugin.RequireScore = false
    finaleplugin.RequireSelection = false
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.AdditionalMenuOptions = [[
        Apply fonts for score
    ]]
    finaleplugin.AdditionalPrefixes = [[
        setting_type = "score"
    ]]
    
    return "Apply fonts for parts", "Apply fonts for parts", "Applies font preferences for parts"
end

--[[
local json = require 'lunajson.lunajson'
local debuggee = require 'vscode-debuggee'
debuggee.start(json, { redirectPrint = true })
--]]

new_type = new_type or "parts"
current_type = new_type == "parts" and "score" or "parts"

local mixin = require('library.mixin')
local enigma_string = require('library.enigma_string')

local fcstr = function(str)
    return mixin.FCMString():SetLuaString(str)
end

function apply_house_style_fonts()
    local font_settings = {
        { name = "Tempo Marks", type = "Text", score = 18, parts = 14 },
        { name = "Tempo Marks", type = "Music", score = 16, parts = 12 },
        { name = "Tempo Marks", type = "Number", score = 16, parts = 12 },
        { name = "Tempo Alterations", type = "Text", score = 18, parts = 14 },
        { name = "Tempo Alterations", type = "Music", score = 16, parts = 12 },
        { name = "Rehearsal Marks", type = "Text", score = 18, parts = 12 },
        { name = "Section Titles", type = "Text", score = 22, parts = 18 },
    }

    local measure_number_size = { score = 14, parts = 12 }
    local page_number_size = { score = 12, parts = 10 }


    local cats = finale.FCCategoryDefs()
    cats:LoadAll()

    -- Expression categories
    for _, v in pairs(font_settings) do
        local cat = cats:FindName(fcstr(v.name))
        local font = finale.FCFontInfo()
        cat["Get" .. v.type .. "FontInfo"](cat, font)
        font.Size = v[new_type]
        cat["Set" .. v.type .. "FontInfo"](cat, font)
        cat:Save()
    end

    -- Font preferences
    local font_prefs = finale.FCFontPrefs()
    font_prefs:Load(finale.FONTPREF_MEASURENUMBER)
    local font = font_prefs:CreateFontInfo()
    font.Size = measure_number_size[new_type]
    font_prefs:SetFontInfo(font)
    font_prefs:Save()

    -- Existing measure regions
    local regions = finale.FCMeasureNumberRegions()
    for region in loadall(regions) do
        font = region:CreateStartFontInfo()
        if font.Size == measure_number_size[current_type] then 
            font.Size = measure_number_size[new_type] 
        end
        region:SetStartFontInfo(font, false)
        region:Save()
    end

    -- Page headers
    local page_texts = finale.FCPageTexts()
    for text in loadall(page_texts) do
        if text.FirstPage == 2 and text.LastPage == 0 then
            local block = text:CreateTextBlock()
            local raw_text = block:CreateRawTextString()
            font = raw_text:CreateLastFontInfo()
            if font.Name == "Minion" and font.Size == page_number_size[current_type] then
                font.Size = page_number_size[new_type]
                enigma_string.change_text_block_font(block, font)
            end
        end
    end
end

apply_house_style_fonts()