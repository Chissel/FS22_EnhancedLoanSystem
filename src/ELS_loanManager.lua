-- Name: ELS_loanManager
-- Author: Chissel

ELS_loanManager = {}
ELS_loanManager.loans = {}

ELS_loanManager.minLoanInterest = 1.0
ELS_loanManager.maxLoanInterest = 10.0
ELS_loanManager.loanInterestSteps = 0.1

local ELS_loanManager_mt = Class(ELS_loanManager, AbstractManager)

function ELS_loanManager.new(customMt)
	local self = ELS_loanManager:superClass().new(customMt or ELS_loanManager_mt)

    self.loans = {}
    self.loanInterest = 3.5

	return self
end

function ELS_loanManager:loadMap()
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
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
    g_els_loanManager:updateLoanInterest()
end

function ELS_loanManager:updateLoanInterest()
    local downUp = math.random(1,2)

    if downUp == 1 then
        self.loanInterest = self.loanInterest + ELS_loanManager.loanInterestSteps

        if self.loanInterest > ELS_loanManager.maxLoanInterest then
            self.loanInterest = ELS_loanManager.maxLoanInterest
        end
    else
        self.loanInterest = self.loanInterest - ELS_loanManager.loanInterestSteps

        if self.loanInterest < ELS_loanManager.minLoanInterest then
            self.loanInterest = ELS_loanManager.minLoanInterest
        end
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
            xmlFile:setFloat(key.."#loanInterest", g_els_loanManager.loanInterest)

            local farmIndex = 0
            for farmId, farmLoans in pairs(g_els_loanManager.loans) do
                local farmKey = string.format(key..".farmId(%d)", farmIndex)
                xmlFile:setInt(farmKey.."#farmId", farmId)
                local loanIndex = 0
                for _, loan in pairs(farmLoans) do
                    local loanKey = string.format(farmKey..".loan(%d)", loanIndex)
                    xmlFile:setInt(loanKey.."#farmId", loan.farmId)
                    xmlFile:setInt(loanKey.."#amount", loan.amount)
                    xmlFile:setFloat(loanKey.."#interest", loan.interest)
                    xmlFile:setInt(loanKey.."#duration", loan.duration)
                    xmlFile:setInt(loanKey.."#restDuration", loan.restDuration)
                    xmlFile:setBool(loanKey.."#paidOff", loan.paidOff)
                    xmlFile:setInt(loanKey.."#restAmount", loan.restAmount)

                    loanIndex = loanIndex + 1
                end
            end

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

function ELS_loanManager:loadFromXMLFile(mission)
    local savegameDirectory = g_currentMission.missionInfo.savegameDirectory

    if savegameDirectory ~= nil then
        local filename = savegameDirectory.."/els_loans.xml"
        local key = "loans"
        local xmlFile = XMLFile.loadIfExists("els_loans", filename, key)

        if xmlFile ~= nil then
            local loanInterest = xmlFile:getFloat(key.."#loanInterest")
            g_els_loanManager.loanInterest = tonumber(string.format("%.2f", loanInterest))

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

                    local currentFarmId = xmlFile:getInt(loanKey.."#farmId")
                    local amount = xmlFile:getInt(loanKey.."#amount")
                    local interest = xmlFile:getFloat(loanKey.."#interest")
                    local duration = xmlFile:getInt(loanKey.."#duration")
                    local restDuration = xmlFile:getInt(loanKey.."#restDuration")
                    local paidOff = xmlFile:getBool(loanKey.."#paidOff")
                    local restAmount = xmlFile:getInt(loanKey.."#restAmount")

                    table.insert(currentFarmLoans, ELS_loan.recovery(currentFarmId, amount, interest, duration, restDuration, paidOff, restAmount))
                    loanIndex = loanIndex + 1
                end

                g_els_loanManager.loans[farmId] = currentFarmLoans
                farmIndex = farmIndex + 1
            end

            xmlFile:delete()
        end
    end
end

function ELS_loanManager:readFromServerStream(streamId)
    print("This is readFromServerStream")
	local loanInterest = streamReadFloat32(streamId)
    g_els_loanManager.loanInterest = loanInterest

    local numFarms = streamReadInt32(streamId)

	for i = 1, numFarms do
        local farmId = streamReadInt32(streamId)

        local numLoans = streamReadInt32(streamId)

        local farmLoans = {}
        for i = 1, numLoans do
            local currentFarmId = streamReadInt32(streamId)
            local amount = streamReadInt32(streamId)
            local interest = streamReadFloat32(streamId)
            local duration = streamReadInt32(streamId)
            local restDuration = streamReadInt32(streamId)
            local paidOff = streamReadBool(streamId)
            local restAmount = streamReadInt32(streamId)

            table.insert(farmLoans, ELS_loan.recovery(currentFarmId, amount, interest, duration, restDuration, paidOff, restAmount))
        end

        g_els_loanManager.loans[farmId] = farmLoans
	end
end

function ELS_loanManager:writeToClientStream(streamId)
    print("This is writeToClientStream")
    streamWriteFloat32(streamId, g_els_loanManager.loanInterest)

    streamWriteInt32(streamId, #g_els_loanManager.loans)

	for farmId, farmLoans in pairs(g_els_loanManager.loans) do
        streamWriteInt32(streamId, farmId)

        streamWriteInt32(streamId, #farmLoans)
        for _, loan in pairs(farmLoans) do
            streamWriteInt32(streamId, loan.farmId)
            streamWriteInt32(streamId, loan.amount)
            streamWriteFloat32(streamId, loan.interest)
            streamWriteInt32(streamId, loan.duration)
            streamWriteInt32(streamId, loan.restDuration)
            streamWriteBool(streamId, loan.paidOff)
            streamWriteInt32(streamId, loan.restAmount)
        end
    end
end

g_els_loanManager = ELS_loanManager.new()