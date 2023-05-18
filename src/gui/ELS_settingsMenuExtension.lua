-- Name: ELS_settingsMenuExtension
-- Author: Chissel

ELS_settingsMenuExtension = {}

function ELS_settingsMenuExtension:onFrameOpen()
    if self.els_initSettingsMenuDone then
        return
    end

    local target = ELS_settingsMenuExtension

    self.els_dynamicLoanInterest = self.checkHelperRefillFuel:clone()
    self.els_dynamicLoanInterest.target = target
    self.els_dynamicLoanInterest.id = "els_dynamicLoanInterest"
    self.els_dynamicLoanInterest:setCallback("onClickCallback", "onDynamicLoanInterestChanged")

    self.els_dynamicLoanInterest.elements[4]:setText(g_i18n:getText("els_settingsMenu_dynamicLoanInterestTitle"))
    self.els_dynamicLoanInterest.elements[6]:setText(g_i18n:getText("els_settingsMenu_dynamicLoanInterestDescription"))

    self.els_dynamicLoanInterestValue = self.checkHelperRefillFuel:clone()
    self.els_dynamicLoanInterestValue.target = target
    self.els_dynamicLoanInterestValue.id = "els_dynamicLoanInterestValue"
    self.els_dynamicLoanInterestValue:setCallback("onClickCallback", "onDynamicLoanInterestValueChanged")

    self.els_dynamicLoanInterestValue.elements[4]:setText(g_i18n:getText("els_settingsMenu_dynamicLoanInterestValueTitle"))
    self.els_dynamicLoanInterestValue.elements[6]:setText(g_i18n:getText("els_settingsMenu_dynamicLoanInterestValueDescription"))

    self.els_loanDurationValue = self.checkHelperRefillFuel:clone()
    self.els_loanDurationValue.target = target
    self.els_loanDurationValue.id = "els_loanDurationValue"
    self.els_loanDurationValue:setCallback("onClickCallback", "onLoanDurationValueChanged")

    self.els_loanDurationValue.elements[4]:setText(g_i18n:getText("els_settingsMenu_loanDurationValueTitle"))
    self.els_loanDurationValue.elements[6]:setText(g_i18n:getText("els_settingsMenu_loanDurationValueDescription"))

    local title = TextElement.new()
    title:applyProfile("settingsMenuSubtitle", true)
    title:setText(g_i18n:getText("els_settingsMenu_sectionTitle"))

    self.boxLayout:addElement(title)
    self.boxLayout:addElement(self.els_dynamicLoanInterest)
    self.boxLayout:addElement(self.els_dynamicLoanInterestValue)
    self.boxLayout:addElement(self.els_loanDurationValue)

    self.els_dynamicLoanInterest:setTexts({g_i18n:getText("ui_on"), g_i18n:getText("ui_off")})
    ELS_settingsMenuExtension.els_steps = g_els_loanManager.loanManagerProperties:getLoanInterestSteps()
    self.els_dynamicLoanInterestValue:setTexts(ELS_settingsMenuExtension.els_steps)

    ELS_settingsMenuExtension.els_durationSteps = g_els_loanManager.loanManagerProperties:getLoanDurationSteps()
    self.els_loanDurationValue:setTexts(ELS_settingsMenuExtension.els_durationSteps)

    self.els_initSettingsMenuDone = true
    ELS_settingsMenuExtension:updateELSSettings(g_gui.currentGui.target.currentPage)
end

function ELS_settingsMenuExtension:updateGameSettings()
    if not self.els_initSettingsMenuDone then
        return
    end

    ELS_settingsMenuExtension:updateELSSettings(self)
end

function ELS_settingsMenuExtension:updateELSSettings(currentPage)
    if currentPage.els_dynamicLoanInterest == nil or currentPage.els_dynamicLoanInterestValue == nil then
        return
    end

    if g_els_loanManager.loanManagerProperties.dynamicLoanInterest then
        currentPage.els_dynamicLoanInterest:setState(1)
        currentPage.els_dynamicLoanInterestValue:setDisabled(true)
    else
        currentPage.els_dynamicLoanInterest:setState(2)
        currentPage.els_dynamicLoanInterestValue:setDisabled(false)
    end

    for index, value in pairs(ELS_settingsMenuExtension.els_steps) do
        if tonumber(value) == g_els_loanManager.loanManagerProperties.loanInterest then
            currentPage.els_dynamicLoanInterestValue:setState(index)
        end
    end

    for index, value in pairs(ELS_settingsMenuExtension.els_durationSteps) do
        if tonumber(value) == g_els_loanManager.loanManagerProperties.maxLoanDuration then
            currentPage.els_loanDurationValue:setState(index)
        end
    end
end

function ELS_settingsMenuExtension:onDynamicLoanInterestChanged(state)
    g_els_loanManager:toggleDynamicLoanInterest()
    ELS_settingsMenuExtension:updateELSSettings(g_gui.currentGui.target.currentPage)
end

function ELS_settingsMenuExtension:onDynamicLoanInterestValueChanged(state)
    local loanInterestValue = tonumber(ELS_settingsMenuExtension.els_steps[state])
    g_els_loanManager:setLoanInterestValue(loanInterestValue)
    ELS_settingsMenuExtension:updateELSSettings(g_gui.currentGui.target.currentPage)
end

function ELS_settingsMenuExtension:onLoanDurationValueChanged(state)
    local loanDurationValue = tonumber(ELS_settingsMenuExtension.els_durationSteps[state])
    g_els_loanManager:setMaxLoanDurationValue(loanDurationValue)
    ELS_settingsMenuExtension:updateELSSettings(g_gui.currentGui.target.currentPage)
end

function init()
    InGameMenuGameSettingsFrame.updateGameSettings = Utils.appendedFunction(InGameMenuGameSettingsFrame.updateGameSettings, ELS_settingsMenuExtension.updateGameSettings)
    InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, ELS_settingsMenuExtension.onFrameOpen)
end

init()