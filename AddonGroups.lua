local addonName, addon, _ = ...
LibStub('AceEvent-3.0'):Embed(addon)

local emptyTable = {}
local noGroupsText = _G.GRAY_FONT_COLOR_CODE..'- no groups -'
local customColor  = _G.BATTLENET_FONT_COLOR_CODE

local groups = {}
local function AddMetadataProperty(checkAddon, property, useTable)
	local value = GetAddOnMetadata(checkAddon, property)
	      value = value and string.trim(value)
	if value and value ~= '' then
		for entry in value:gmatch("[^,%s][^,]*") do
			if not tContains(useTable or groups, entry) then
				table.insert(useTable or groups, entry)
			end
		end
	end
end
local function GetAddonGroups(checkAddon, includeMetadata, excludeCustom)
	if type(checkAddon) == 'number' then
		-- @see http://wowprogramming.com/docs/api/GetAddOnInfo
		checkAddon = GetAddOnInfo(checkAddon)
	end

	wipe(groups)
	if includeMetadata == true then
		-- add all relevant metadata
		AddMetadataProperty(checkAddon, 'Author')
		AddMetadataProperty(checkAddon, 'X-Category')
	elseif includeMetadata then
		-- only add specific metadata
		AddMetadataProperty(checkAddon, includeMetadata)
	end
	if not excludeCustom then
		for _, group in ipairs(addon.db[checkAddon] or emptyTable) do
			if not tContains(groups, group) then
				table.insert(groups, group)
			end
		end
	end
	return groups
end

local function ShowInputBox(owner, btn, up)
	local entry   = owner:GetParent()
	local editbox = addon.editbox
	if editbox:IsShown() then
		-- previously shown box is still active
		editbox:GetScript('OnEscapePressed')(editbox)
	end

	editbox:SetParent(entry)
	editbox:SetAllPoints(owner)
	local groupsText = owner:GetText()
	editbox:SetText(groupsText ~= noGroupsText and groupsText or '')
	editbox:Show()
	owner:Hide()
end

local function OnEnterPressed(self)
	local entry      = self:GetParent()
	local groupsText = self:GetText()
	      groupsText = string.trim(groupsText)

	-- clear old data
	local checkAddon = GetAddOnInfo(entry:GetID())
	if not addon.db[checkAddon] then addon.db[checkAddon] = {} end
	wipe(addon.db[checkAddon])
	-- add new data
	local groups = GetAddonGroups(checkAddon, 'X-Category', true)
	for group in groupsText:gmatch("[^,%s][^,]*") do
		-- prevent duplicates
		if not tContains(groups, group) and not tContains(addon.db[checkAddon], group) then
			table.insert(addon.db[checkAddon], group)
		end
	end
	if #addon.db[checkAddon] == 0 then
		addon.db[checkAddon] = nil
	end

	local owner = entry.Groups
	owner:SetText(groupsText ~= '' and groupsText or noGroupsText)
	owner:Show()
	self:ClearFocus()
	self:Hide()
end

local function OnEscapePressed(self)
	self:GetParent().Groups:Show()
	self:ClearFocus()
	self:Hide()
end

local function InitializeAddonList()
	-- TODO: autocomplete!
	local editbox = CreateFrame('EditBox', nil, _G.AddonList)
	      editbox:Hide()
	      editbox:SetAutoFocus(true)
	      editbox:SetFontObject('GameFontHighlightSmall')
	      editbox:SetFrameStrata('DIALOG')
	editbox:SetScript('OnEscapePressed', OnEscapePressed)
	editbox:SetScript('OnEnterPressed',  OnEnterPressed)
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
		entry.Reload:SetJustifyH('CENTER')
		entry.Reload:ClearAllPoints()
		entry.Reload:SetPoint('LEFT', '$parentTitle', 'RIGHT', 6, 0)
		entry.Status:SetWidth(26)
		entry.Status:SetJustifyH('CENTER')
		entry.Status:ClearAllPoints()
		entry.Status:SetPoint('LEFT', '$parentTitle', 'RIGHT', 6, 0)

		-- display our data as well as allow changing it
		local groupsBtn = CreateFrame('Button', '$parentGroups', entry, 'TruncatedButtonTemplate')
		      groupsBtn:SetSize(170, 12+4)
		      groupsBtn:SetPoint('LEFT', '$parentStatus', 'RIGHT', 6, 0)
		local fontString = groupsBtn:CreateFontString('$parentText', nil, 'GameFontNormalSmall')
		      fontString:SetJustifyH('LEFT')
		      fontString:SetAllPoints(groupsBtn)
		groupsBtn:SetFontString(fontString)
		groupsBtn:SetScript('OnClick', ShowInputBox)
		entry.Groups = groupsBtn
	end
end

local function UpdateAddonList()
	for index = 1, _G.MAX_ADDONS_DISPLAYED do
		local addonIndex = index + AddonList.offset
		local entry = _G['AddonListEntry'..index]

		local groups = GetAddonGroups(addonIndex, 'X-Category')
		entry.Groups:SetText(#groups > 0 and table.concat(groups, ', ') or noGroupsText)
	end
end

local function UpdateAddonTooltip(owner)
	local tooltip = _G.AddonTooltip
	local addonIndex = owner:GetID()

	local r, g, b = owner.Status:GetTextColor()
	tooltip:AddLine(owner.Status:GetText(), r, g, b)

	local author = GetAddOnMetadata(addonIndex, 'Author')
	tooltip:AddLine(('by %s'):format(author or 'unknown'))

	-- tooltip:AddLine(' ')
	-- tooltip:AddLine(strjoin('|n', category or '', author or '', date or '', website or '', feedback or ''), nil, nil, nil, true)
end

local function OnDropDownClick(info, menuList, value)
	if not menuList or not value then return end
	-- UIDropDownMenu_SetSelectedValue(AddonGroupDropDown, info.value)
	local isChecked = info.checked
	local character = UIDropDownMenu_GetSelectedValue(AddonCharacterDropDown)

	for addonIndex = 1, GetNumAddOns() do
		-- TODO: do we want to toggle 'X-Category' when custom group w/ same name is toggled?
		local groups = GetAddonGroups(addonIndex, menuList ~= 'custom', menuList ~= 'custom')
		if tContains(groups, value) then
			if isChecked then
				PlaySound('igMainMenuOptionCheckBoxOn')
				EnableAddOn(addonIndex, character)
			else
				PlaySound('igMainMenuOptionCheckBoxOff')
				DisableAddOn(addonIndex, character)
			end
		end
	end
	AddonList_Update()
end

local data = { -- @see http://wowpedia.org/TOC_format
	['Author'] = {},
	['X-Category'] = {},
	custom = {},
}
local function UpdateKnownGroups()
	for property, values in pairs(data) do wipe(values) end
	-- load available groups
	for addonIndex = 1, GetNumAddOns() do
		for property, values in pairs(data) do
			-- metadata properties
			AddMetadataProperty(addonIndex, property, data[property])
		end
		local groups = GetAddonGroups(addonIndex)
		for _, group in pairs(groups) do
			-- user specified groups
			if not tContains(data.custom, group) then
			-- if not tContains(data['X-Category'], group) then
				table.insert(data.custom, group)
				-- table.insert(data['X-Category'], group)
			end
		end
	end
end

local function SortValues(a, b) return a:lower() < b:lower() end -- ignore capitalization
local function InitializeDropdown(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	      info.func = OnDropDownClick
	      info.isNotRadio = true

	if level == 1 then
		info.isTitle = true
		info.hasArrow = true
		info.notCheckable = true

		-- TODO: in theory, we'd only need to do this when player changes groups
		UpdateKnownGroups()

		-- TODO: localize
		info.text = 'Author'
		info.menuList = 'Author'
		UIDropDownMenu_AddButton(info, level)

		info.text = _G.CATEGORY
		info.menuList = 'X-Category'
		UIDropDownMenu_AddButton(info, level)

		if #data.custom > 0 then
			info.text = _G.CHANNEL_CATEGORY_CUSTOM
			info.menuList = 'custom'
			UIDropDownMenu_AddButton(info, level)
		end
	elseif menuList and data[menuList] then
		-- TODO: use tristate for all/some in group enabled/disabled
		info.keepShownOnClick = true
		table.sort(data[menuList], SortValues)
		for _, value in ipairs(data[menuList]) do
			info.text = value
			info.arg1 = menuList
			info.arg2 = value
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function addon:OnEnable()
	if not _G[addonName..'DB'] then
		_G[addonName..'DB'] = {}
	end
	self.db = _G[addonName..'DB']

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

addon:RegisterEvent('ADDON_LOADED', function(self, event, arg1)
	if arg1 ~= addonName then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:OnEnable()
end, addon)
