-- Name: ELS_loanManager
-- Author: Chissel

ELS_loanManager = {}
ELS_loanManager.loans = {}

local ELS_loanManager_mt = Class(ELS_loanManager, AbstractManager)

function ELS_loanManager.new(customMt)
	local self = ELS_loanManager:superClass().new(customMt or ELS_loanManager_mt)

    self.loans = {}

	return self
end

function ELS_loanManager:loadMap()
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
end

function ELS_loanManager:loadMapData(xmlFile)
    if g_currentMission:getIsServer() then
        g_els_loanManager.loanManagerProperties = ELS_loanManagerProperties.new(true, g_currentMission:getIsClient())
        g_els_loanManager.loanManagerProperties:register()
    end
end

function ELS_loanManager:setLoanInterestValue(value)
    self.loanManagerProperties.loanInterest = value
    self.loanManagerProperties:raiseDirtyFlags(self.loanManagerProperties.propertiesDirtyFlag)
    self.loanManagerProperties:raiseActive()
end

function ELS_loanManager:toggleDynamicLoanInterest()
    self.loanManagerProperties.dynamicLoanInterest = not self.loanManagerProperties.dynamicLoanInterest
    self.loanManagerProperties:raiseDirtyFlags(self.loanManagerProperties.propertiesDirtyFlag)
    self.loanManagerProperties:raiseActive()
end

function ELS_loanManager:paidOffLoans(farmId)
    local paidOffLoans = {}
    local allFarmLoans = self.loans[farmId] or {}

    for _, loan in pairs(allFarmLoans) do
        if loan.paidOff then
            if farmId == nil then
                table.insert(paidOffLoans, loan)
            else
                if loan.farmId == farmId then
                    table.insert(paidOffLoans, loan)
                end
            end
        end
    end

    return paidOffLoans
end

function ELS_loanManager:currentLoans(farmId)
    local currentLoans = {}
    local allFarmLoans = self.loans[farmId] or {}

    for _, loan in pairs(allFarmLoans) do
        if not loan.paidOff then
            if farmId == nil then
                table.insert(currentLoans, loan)
            else
                if loan.farmId == farmId then
                    table.insert(currentLoans, loan)
                end
            end
        end
    end

    return currentLoans
end

function ELS_loanManager:addLoan(loan)
    loan:register()
    local farmLoans = self.loans[loan.farmId] or {}
    table.insert(farmLoans, loan)
    self.loans[loan.farmId] = farmLoans

    self:addRemoveMoney(loan.amount, loan.farmId)
end

function ELS_loanManager:addRemoveMoney(amount, farmId)
    if g_currentMission:getIsServer() then
        local moneyType = MoneyType.LOAN

        if amount < 0 then
            moneyType = MoneyType.LOAN_INTEREST
        end

        g_currentMission:addMoneyChange(amount, farmId, moneyType, true)
        local farm = g_farmManager:getFarmById(farmId)
        if farm ~= nil then
            farm:changeBalance(amount, moneyType)
        end
    else
        g_client:getServerConnection():sendEvent(ELS_addRemoveMoneyEvent.new(amount, farmId))
    end
end

function ELS_loanManager:specialRedemptionPayment(loan, amount)
    if amount >= loan.restAmount then
        loan.restAmount = 0
        loan.paidOff = true
    else
        loan.restAmount = loan.restAmount - amount
    end

    loan:raiseDirtyFlags(loan.loanDirtyFlag)
    loan:raiseActive()

    self:addRemoveMoney(-amount, loan.farmId)
end

function ELS_loanManager:maxLoanAmountForFarm(farmId)
    local farm = g_farmManager:getFarmById(farmId)
    return farm.loanMax
end

-- Calculate loans on period change

function ELS_loanManager:onPeriodChanged()
    if not g_currentMission:getIsServer() then
        return
    end

    g_els_loanManager:collectLoanRate()
    g_els_loanManager:updateLoanInterestIfNeeded()
end

function ELS_loanManager:updateLoanInterestIfNeeded()
    if not self.loanManagerProperties.dynamicLoanInterest then
        return
    end

    local downUp = math.random(1,3)

    if downUp == 1 then
        self.loanManagerProperties.loanInterest = self.loanManagerProperties.loanInterest + ELS_loanManagerProperties.loanInterestSteps

        if self.loanManagerProperties.loanInterest > ELS_loanManagerProperties.maxLoanInterest then
            self.loanManagerProperties.loanInterest = ELS_loanManagerProperties.maxLoanInterest
        end

        self.loanManagerProperties:raiseDirtyFlags(self.loanManagerProperties.propertiesDirtyFlag)
    elseif downUp == 2 then
        self.loanManagerProperties.loanInterest = self.loanManagerProperties.loanInterest - ELS_loanManagerProperties.loanInterestSteps

        if self.loanManagerProperties.loanInterest < ELS_loanManagerProperties.minLoanInterest then
            self.loanManagerProperties.loanInterest = ELS_loanManagerProperties.minLoanInterest
        end

        self.loanManagerProperties:raiseDirtyFlags(self.loanManagerProperties.propertiesDirtyFlag)
    end
end

function ELS_loanManager:collectLoanRate()
    for farmId, loans in pairs(self.loans) do
        self:collectLoanRateForFarm(farmId, loans)
    end
end

function ELS_loanManager:collectLoanRateForFarm(farmId, loans)
    for _, loan in pairs(loans) do
        if not loan.paidOff then
            local annuity = loan:calculateAnnuity()
            local interestPortion = loan:calculateInterestPortion()
            local repaymentPortion = annuity - interestPortion

            loan.restDuration = loan.restDuration - 1

            if repaymentPortion > loan.restAmount then
                annuity = loan.restAmount + interestPortion
                loan.restAmount = 0
                loan.restDuration = 0
                loan.paidOff = true
            else
                loan.restAmount = loan.restAmount - repaymentPortion
            end

            loan:raiseDirtyFlags(loan.loanDirtyFlag)
            loan:raiseActive()

            self:addRemoveMoney(-annuity, farmId)
        end
    end
end

function ELS_loanManager:saveToXMLFile(missionInfo)
    local savegameDirectory = g_currentMission.missionInfo.savegameDirectory

    if savegameDirectory ~= nil then
        local saveGamePath = savegameDirectory.."/els_loans.xml"
        local key = "loans"
        local xmlFile = XMLFile.create("els_loans", saveGamePath, key)

        if xmlFile ~= nil then
            g_els_loanManager.loanManagerProperties:saveToXMLFile(xmlFile, key)

            local farmIndex = 0
            for farmId, farmLoans in pairs(g_els_loanManager.loans) do
                local farmKey = string.format(key..".farmId(%d)", farmIndex)
                xmlFile:setInt(farmKey.."#farmId", farmId)


                local loanIndex = 0
                for _, loan in pairs(farmLoans) do
                    local loanKey = string.format(farmKey..".loan(%d)", loanIndex)
                    loan:saveToXMLFile(xmlFile, loanKey)
                    loanIndex = loanIndex + 1
                end

                farmIndex = farmIndex + 1
            end

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function ELS_loanManager:loadFromXMLFile()
    local savegameDirectory = g_currentMission.missionInfo.savegameDirectory

    if savegameDirectory ~= nil then
        local filename = savegameDirectory.."/els_loans.xml"
        local key = "loans"
        local xmlFile = XMLFile.loadIfExists("els_loans", filename, key)

        if xmlFile ~= nil then
            g_els_loanManager.loanManagerProperties:loadFromXMLFile(xmlFile, key)

            local farmIndex = 0
            while true do
                local farmKey = string.format(key..".farmId(%d)", farmIndex)

                if not xmlFile:hasProperty(farmKey) then
                    break
                end

                local farmId = xmlFile:getInt(farmKey.."#farmId")

                local currentFarmLoans = {}
                local loanIndex = 0

                while true do
                    local loanKey = string.format(farmKey..".loan(%d)", loanIndex)

                    if not xmlFile:hasProperty(loanKey) then
                        break
                    end

                    local loan = ELS_loan.new(true, g_client ~= nil)
                    if not loan:loadFromXMLFile(xmlFile, loanKey) then
                        loan:delete()
                    else
                        loan:register()
                        table.insert(currentFarmLoans, loan)
                    end

                    loanIndex = loanIndex + 1
                end

                g_els_loanManager.loans[farmId] = currentFarmLoans
                farmIndex = farmIndex + 1
            end

            xmlFile:delete()
        end
    end
end

g_els_loanManager = ELS_loanManager.new()