-- Name: ELS_inGameMenuLoanSystem
-- Author: Chissel


local modDirectory = g_currentModDirectory

ELS_inGameMenuLoanSystem = {}
local ELS_inGameMenuLoanSystem_mt = Class(ELS_inGameMenuLoanSystem, TabbedMenuFrameElement)

ELS_inGameMenuLoanSystem.CONTROLS = {
    "mainBox",
	"tableHeaderBox",
    "textInputLoanAmount",
    "loanTable",
    "currentLoanInterest"
}

function ELS_inGameMenuLoanSystem.new(i18n, messageCenter)
	local self = ELS_inGameMenuLoanSystem:superClass().new(nil, ELS_inGameMenuLoanSystem_mt)

	self:registerControls(ELS_inGameMenuLoanSystem.CONTROLS)
    g_currentMission.inGameMenu.frameLoanSystem = self

	self.hasCustomMenuButtons = true
    self.messageCenter = messageCenter
    self.i18n = i18n

	return self
end

function ELS_inGameMenuLoanSystem:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}

	self.takeLoanButton = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.i18n:getText("els_ui_takeLoan"),
		callback = function ()
			self:onTakeLoanButton()
		end
	}

    self.specialRedemptionPayment = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = self.i18n:getText("els_ui_specialRedemptionPayment"),
		callback = function ()
			self:onSpecialRedemptionPaymentButton()
		end
	}

    local info = {
		self.backButtonInfo,
        self.takeLoanButton,
        self.specialRedemptionPayment
	}

    self.menuButtons = info

    self:setMenuButtonInfo(self.menuButtons)
end

function ELS_inGameMenuLoanSystem:onGuiSetupFinished()
    print("onGuiSetupFinished")
	ELS_inGameMenuLoanSystem:superClass().onGuiSetupFinished(self)
	self.loanTable:setDataSource(self)
	self.loanTable:setDelegate(self)


    self.takeLoanDialog = ELS_takeLoanDialog.new(self, nil, self.i18n)
    self.specialRedemptionDialog = ELS_specialRedemptionPaymentDialog.new(self, nil, self.i18n)
    g_gui:loadGui(modDirectory .. "gui/ELS_takeLoanDialog.xml", "ELS_takeLoanDialog", self.takeLoanDialog)
    g_gui:loadGui(modDirectory .. "gui/ELS_specialRedemptionPaymentDialog.xml", "ELS_specialRedemptionPaymentDialog", self.specialRedemptionDialog)
end

function ELS_inGameMenuLoanSystem:onFrameOpen(element)
	ELS_inGameMenuLoanSystem:superClass().onFrameOpen(self)
	
	self:setButtons()
    self:updateContent()

    if self.currentLoan ~= nil and not self.currentLoan.paidOff then
        self.specialRedemptionPayment.disabled = false
    else
        self.specialRedemptionPayment.disabled = true
    end

    self.currentLoanInterest:setText(string.format("%s: %s", self.i18n:getText("els_ui_inGameMenuLoanInterest"), string.format("%.1f", g_els_loanManager.loanManagerProperties.loanInterest)))

    self:setMenuButtonInfoDirty()
    FocusManager:setFocus(self.loanTable)
end

function ELS_inGameMenuLoanSystem:updateContent()
    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    self.paidOffLoans = g_els_loanManager:paidOffLoans(farm.farmId)
    self.currentLoans = g_els_loanManager:currentLoans(farm.farmId)
    self.loanTable:reloadData()
end

function ELS_inGameMenuLoanSystem:onListSelectionChanged(list, section, index)
    local loan = {}

    if section == 1 then
        loan = self.currentLoans[index]
    else
        loan = self.paidOffLoans[index]
    end

    if loan == nil then
        return
    end

    self.currentLoan = loan
    self.specialRedemptionPayment.disabled = loan.paidOff
    self:setMenuButtonInfoDirty()
end

function ELS_inGameMenuLoanSystem:setButtons()
	local info = {
		self.backButtonInfo,
        self.takeLoanButton,
        self.specialRedemptionPayment
	}

    self.menuButtons = info

	self:setMenuButtonInfoDirty()
end

function ELS_inGameMenuLoanSystem:onTakeLoanButton()
    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    self:showTakeLoanDialog({callback=self.takeLoanCallback, target=self, maxLoanAmount=g_els_loanManager:maxLoanAmountForFarm(farm.farmId), loanInterest=g_els_loanManager.loanManagerProperties.loanInterest})
end

function ELS_inGameMenuLoanSystem:showTakeLoanDialog(args)
    local dialog = g_gui.guis.ELS_takeLoanDialog

    if dialog ~= nil and args ~= nil then
        local target = dialog.target

        target:setCallback(args.callback, args.target)
        target:setAvailableProperties(args.maxLoanAmount, args.loanInterest)

        g_gui:showDialog("ELS_takeLoanDialog")
    end
end

function ELS_inGameMenuLoanSystem:takeLoanCallback(success, amount, duration)
    if success then
        local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
        local loan = ELS_loan.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
        loan:init(farm.farmId, amount, g_els_loanManager.loanManagerProperties.loanInterest, duration)

        g_els_loanManager:addLoan(loan)

        self:updateContent()
    end
end

function ELS_inGameMenuLoanSystem:showSpecialRedemptionPaymentDialog(args)
    local dialog = g_gui.guis.ELS_specialRedemptionPaymentDialog

    if dialog ~= nil and args ~= nil then
        local target = dialog.target

        target:setCallback(args.callback, args.target)
        target:setAvailableProperties(args.restAmount, args.currentMoney)

        g_gui:showDialog("ELS_specialRedemptionPaymentDialog")
    end
end

function ELS_inGameMenuLoanSystem:onSpecialRedemptionPaymentButton()
    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    self:showSpecialRedemptionPaymentDialog({callback=self.specialRedemptionPaymentCallback, target=self, restAmount=self.currentLoan.restAmount, currentMoney=farm.money})
end

function ELS_inGameMenuLoanSystem:specialRedemptionPaymentCallback(success, amount)
    if success then
        g_els_loanManager:specialRedemptionPayment(self.currentLoan, amount)

        self:updateContent()
    end
end

-- DataSource

function ELS_inGameMenuLoanSystem:getNumberOfSections()
	return 2
end

function ELS_inGameMenuLoanSystem:getNumberOfItemsInSection(list, section)
    if section == 1 then
        return #self.currentLoans
    else
        return #self.paidOffLoans
    end
end

function ELS_inGameMenuLoanSystem:getTitleForSectionHeader(list, section)
	if section == 1 then
        return self.i18n:getText("els_ui_currentLoanSectionHeader")
    else
        return self.i18n:getText("els_ui_paidOffLoanSectionHeader")
    end
end

function ELS_inGameMenuLoanSystem:populateCellForItemInSection(list, section, index, cell)
    local loan = {}

    if section == 1 then
        loan = self.currentLoans[index]
    else
        loan = self.paidOffLoans[index]
    end

    if loan == nil then
        return
    end

    self:createCellWithLoan(cell, loan)
end

function ELS_inGameMenuLoanSystem:createCellWithLoan(cell, loan)
    local loanPeriodRate = loan:calculateAnnuity()

    cell:getAttribute("amount"):setText(g_i18n:formatMoney(loan.amount))
	cell:getAttribute("interest"):setText(g_i18n:formatNumber(loan.interest, 2))
	cell:getAttribute("periodRate"):setText(g_i18n:formatMoney(loanPeriodRate))
	cell:getAttribute("duration"):setText(g_i18n:formatNumber(loan.duration * 12))
	cell:getAttribute("restDuration"):setText(g_i18n:formatNumber(loan.restDuration))
	cell:getAttribute("restAmount"):setText(g_i18n:formatMoney(loan.restAmount))	
end