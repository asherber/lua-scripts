function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "March 20, 2021"
    finaleplugin.CategoryTags = "Expression"
    return "Expression Remove Enclosure", "Expression Remove Enclosure", "Removes any enclosure on any single-staff text expression in the currently selected region."
end

local library = require("library.general_library")
local expression = require("library.expression")

function expression_remove_enclosure()
    local current_part = library.get_current_part()
    local expression_assignments = finale.FCExpressions()
    expression_assignments:LoadAllForRegion(finenv.Region())
    for expression_assignment in each(expression_assignments) do
        if not expression_assignment:IsShape() and expression_assignment:IsSingleStaffAssigned() then
            if expression.is_for_current_part(expression_assignment, current_part) then
                local expression_def = finale.FCTextExpressionDef()
                if expression_def:Load(expression_assignment.ID) then
                    if expression_def.UseEnclosure then
                        local enclosure = expression_def:CreateEnclosure()
                        if (nil ~= enclosure) then
                            enclosure:DeleteData()
                        end
                        expression_def:SetUseEnclosure(false)
                        expression_def:Save()
                    end
                end
            end
        end
    end
end

expression_remove_enclosure()
