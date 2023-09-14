-- Name: ELS_statisticNamesFix
-- Author: Chissel

local function newFinanceStats(self, superFunc, customMt)
    local self = superFunc(self, customMt)
    FinanceStats.statNamesI18n[MoneyType.LOAN.statistic] = g_i18n:getText("els_statistic_loan")
	return self
end

FinanceStats.new = Utils.overwrittenFunction(FinanceStats.new, newFinanceStats)