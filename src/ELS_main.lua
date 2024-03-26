-- Name: ELS_main
-- Author: Chissel

local modDirectory = g_currentModDirectory

source(g_currentModDirectory .. "src/ELS_loanManager.lua")
source(g_currentModDirectory .. "src/ELS_loan.lua")
source(g_currentModDirectory .. "src/ELS_loanManagerProperties.lua")
source(g_currentModDirectory .. "src/gui/ELS_inGameMenuLoanSystem.lua")
source(g_currentModDirectory .. "src/gui/ELS_takeLoanDialog.lua")
source(g_currentModDirectory .. "src/gui/ELS_specialRedemptionPaymentDialog.lua")
source(g_currentModDirectory .. "src/gui/ELS_settingsMenuExtension.lua")
source(g_currentModDirectory .. "src/events/ELS_addRemoveMoneyEvent.lua")
source(g_currentModDirectory .. "src/ELS_statisticNamesFix.lua")

addModEventListener(ELS_loanManager)

g_els_settingsMenuExtension = {}

function loadedMission()
    g_gui:loadProfiles(modDirectory.."gui/ELS_guiProfiles.xml")

	local guiLoanSystem = ELS_inGameMenuLoanSystem.new(g_i18n, g_messageCenter)
	g_gui:loadGui(modDirectory.."gui/ELS_inGameMenuLoanSystem.xml", "InGameMenuLoanSystem", guiLoanSystem, true)
		
    fixInGameMenu(guiLoanSystem, "InGameMenuLoanSystem", {0,0,1024,1024}, 3, nil)

	guiLoanSystem:initialize()
end

function onStartMission()
    if g_currentMission:getIsServer() then
        convertIngameLoans()
    end
end

function convertIngameLoans()
    for _, farm in pairs(g_farmManager:getFarms()) do
        if farm.loan > 0 then
            local farmId = farm.farmId
            local amount = farm.loan
            local loan = ELS_loan.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
            loan:init(farmId, amount, g_els_loanManager.loanManagerProperties.loanInterest, 3)

            loan:register()
            local farmLoans = g_els_loanManager.loans[loan.farmId] or {}
            table.insert(farmLoans, loan)
            g_els_loanManager.loans[loan.farmId] = farmLoans

            farm.loan = 0
        end
    end
end

function convertIngameLoansOnCreate(self, superFunc, name, color, password, farmId)
    local returnValue = superFunc(self, name, color, password, farmId)
    convertIngameLoans()
    return returnValue
end

function hasPlayerLoanPermission()
    return false
end

function fixInGameMenu(frame, pageName, uvs, position, predicateFunc)
	local inGameMenu = g_gui.screenControllers[InGameMenu]

	-- remove all to avoid warnings
	for k, v in pairs({pageName}) do
		inGameMenu.controlIDs[v] = nil
	end

	inGameMenu:registerControls({pageName})

	
	inGameMenu[pageName] = frame
	inGameMenu.pagingElement:addElement(inGameMenu[pageName])

	inGameMenu:exposeControlsAsFields(pageName)

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.elements, i)
			table.insert(inGameMenu.pagingElement.elements, position, child)
			break
		end
	end

	for i = 1, #inGameMenu.pagingElement.pages do
		local child = inGameMenu.pagingElement.pages[i]
		if child.element == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.pages, i)
			table.insert(inGameMenu.pagingElement.pages, position, child)
			break
		end
	end

	inGameMenu.pagingElement:updateAbsolutePosition()
	inGameMenu.pagingElement:updatePageMapping()
	
	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
	local iconFileName = Utils.getFilename('images/menuIcon.dds', modDirectory)
	inGameMenu:addPageTab(inGameMenu[pageName],iconFileName, GuiUtils.getUVs(uvs))
	inGameMenu[pageName]:applyScreenAlignment()
	inGameMenu[pageName]:updateAbsolutePosition()

	for i = 1, #inGameMenu.pageFrames do
		local child = inGameMenu.pageFrames[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pageFrames, i)
			table.insert(inGameMenu.pageFrames, position, child)
			break
		end
	end

	inGameMenu:rebuildTabList()
end

function init()
    table.insert(FinanceStats.statNames, MoneyType.LOAN.statistic)
    FinanceStats.statNameToIndex[MoneyType.LOAN.statistic] = #FinanceStats.statNames
    MoneyType.LOAN.title = "ui_loan"

    Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)
    Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, onStartMission)
    Mission00.loadItemsFinished = Utils.appendedFunction(Mission00.loadItemsFinished, ELS_loanManager.loadFromXMLFile)
    FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, ELS_loanManager.saveToXMLFile)
    Mission00.loadAdditionalFilesFinished = Utils.appendedFunction(Mission00.loadAdditionalFilesFinished, ELS_loanManager.loadMapData)
    InGameMenuFinancesFrame.hasPlayerLoanPermission = Utils.appendedFunction(InGameMenuFinancesFrame.hasPlayerLoanPermission, hasPlayerLoanPermission)
    FarmManager.createFarm = Utils.overwrittenFunction(FarmManager.createFarm, convertIngameLoansOnCreate)
end

init()