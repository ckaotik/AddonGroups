local addonName, addon, _ = ...

local function ShowInputBox(owner, btn, up)
	-- TODO: hide current tags
	-- owner: an entry's tags button
	local addonIndex = owner:GetParent():GetID()
	local editbox = addon.editbox
	editbox:SetAllPoints(owner)
	editbox:SetText(owner:GetText())
	editbox:Show()
end

local function InitializeAddonList()
	-- TODO: autocomplete!
	local editbox = CreateFrame('EditBox', nil, _G.AddonList)
	      editbox:Hide()
	      editbox:SetAutoFocus(true)
	      editbox:SetFontObject('GameFontHighlightSmall')
	      editbox:SetFrameStrata('DIALOG')
	editbox:SetScript('OnEscapePressed', editbox.ClearFocus)
	editbox:SetScript('OnEnterPressed',  editbox.ClearFocus)
	editbox:SetScript('OnEditFocusLost', editbox.Hide)
	addon.editbox = editbox

	for index = 1, _G.MAX_ADDONS_DISPLAYED do
		local entry = _G['AddonListEntry'..index]

		entry.Status:SetAlpha(0)  -- disabled state is obvious via checkbox/gray title
		entry.Reload:SetText('*') -- added legend for clarity
		entry.LoadAddonButton:SetText('+')

		-- change positioning of default elements
		entry.LoadAddonButton:SetWidth(26)
		entry.LoadAddonButton:ClearAllPoints()
		entry.LoadAddonButton:SetPoint('LEFT', '$parentTitle', 'RIGHT', 6, 0)
		entry.Reload:SetWidth(26)
		entry.Reload:ClearAllPoints()
		entry.Reload:SetPoint('LEFT', '$parentTitle', 'RIGHT', 6, 0)
		entry.Status:SetWidth(26)
		entry.Status:ClearAllPoints()
		entry.Status:SetPoint('LEFT', '$parentTitle', 'RIGHT', 6, 0)

		-- display our data as well as allow changing it
		local tags = CreateFrame('Button', nil, entry)
		      tags:SetSize(170, 12)
		      tags:SetPoint('LEFT', '$parentStatus', 'RIGHT', 6, 0)
		local fontString = tags:GetFontString() or tags:CreateFontString(nil, nil, 'GameFontNormalSmall')
		      fontString:SetJustifyH('LEFT')
		      fontString:SetAllPoints(tags)
		tags:SetFontString(fontString)
		tags:SetScript('OnClick', ShowInputBox)
		entry.Tags = tags
	end
end

local function UpdateAddonList()
	for index = 1, _G.MAX_ADDONS_DISPLAYED do
		local addonIndex = index + AddonList.offset
		local entry = _G['AddonListEntry'..index]

		-- local ... = GetAddOnDependencies(addonIndex)
		-- local ... = GetAddOnOptionalDependencies(addonIndex)
		-- @see http://wowprogramming.com/docs/api/GetAddOnInfo
		-- local name, title, notes, enabled, loadable, notLoadedReason, security = GetAddOnInfo(addonIndex)
		-- @see http://wowpedia.org/TOC_format
		-- local author   = GetAddOnMetadata(addonIndex, 'Author')

		local groups = _G.GRAY_FONT_COLOR_CODE..'- no groups -'
		-- TODO: read tags and display
		entry.Tags:SetText(groups)
	end
end

local function UpdateAddonTooltip(owner)
	local tooltip = _G.AddonTooltip
	local addonIndex = owner:GetID()

	local r, g, b = owner.Status:GetTextColor()
	tooltip:AddLine(owner.Status:GetText(), r, g, b)

	local author   = GetAddOnMetadata(addonIndex, 'Author')
	local category = GetAddOnMetadata(addonIndex, 'X-Category')
	local date     = GetAddOnMetadata(addonIndex, 'X-Date')
	local website  = GetAddOnMetadata(addonIndex, 'X-Website')
	local feedback = GetAddOnMetadata(addonIndex, 'X-Feedback')

	-- tooltip:AddLine(' ')
	-- tooltip:AddLine(strjoin('|n', category or '', author or '', date or '', website or '', feedback or ''), nil, nil, nil, true)
end

local function OnDropDownClick(self)
	-- TODO: enable/disable via AddonList_Enable(addonIndex, isEnabled) or EnableAddon(addonIndex, character) -- true for all
	-- UIDropDownMenu_SetSelectedValue(AddonGroupDropDown, self.value)
end

local data = {
	['Author'] = {},
	['X-Category'] = {},
}
-- ignore capitalization
local function SortValues(a, b) return a:lower() < b:lower() end
local function InitializeDropdown(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	      info.func = OnDropDownClick
	      info.isNotRadio = true

	if level == 1 then
		info.isTitle = true
		info.hasArrow = true
		info.notCheckable = true

		for property, values in pairs(data) do wipe(values) end
		for addonIndex = 1, GetNumAddOns() do
			for property, values in pairs(data) do
				local value = GetAddOnMetadata(addonIndex, property)
				      value = value and string.trim(value)
				if value and value ~= '' and not tContains(values, value) then
					table.insert(values, value)
				end
			end
		end

		-- TODO: localize
		info.text = 'Author'
		info.menuList = data['Author']
		-- info.menuTable = data['Author']
		UIDropDownMenu_AddButton(info, level)

		info.text = 'Category'
		info.menuList = data['X-Category']
		-- info.menuTable = data['X-Category']
		UIDropDownMenu_AddButton(info, level)

		-- info.text = 'Tags'
		-- info.menuList = 'Tags'
		-- UIDropDownMenu_AddButton(info, level)
	elseif type(menuList) == 'table' then
		info.keepShownOnClick = true
		table.sort(menuList, SortValues)
		for _, value in ipairs(menuList) do
			info.text  = value
			info.value = value
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

local function OnEnable()
	local legend = _G.AddonList:CreateFontString(nil, nil, 'GameFontNormalSmall')
	      legend:SetText('* requires reload')
	      legend:SetTextColor(255, 0, 0)
	      legend:SetPoint('TOPLEFT', 5, -7)

	local dropDown = CreateFrame('Frame', 'AddonGroupDropDown', _G.AddonList, 'UIDropDownMenuTemplate')
	      dropDown:SetPoint('LEFT', 'AddonCharacterDropDown', 'RIGHT', 100, 0)
	      dropDown.initialize = InitializeDropdown
	UIDropDownMenu_SetWidth(dropDown, 120)
	UIDropDownMenu_SetText(dropDown, 'Addon Groups')

	InitializeAddonList()
	hooksecurefunc('AddonList_Update', UpdateAddonList)
	hooksecurefunc('AddonTooltip_Update', UpdateAddonTooltip)
end

-- for now we don't care about saved vars
OnEnable()
