-- Name: ELS_loan
-- Author: Chissel

ELS_loan = {}
local ELS_loan_mt = Class(ELS_loan, Object)

function ELS_loan.new(isServer, isClient)
    local self = Object.new(isServer, isClient, ELS_loan_mt)

	self.loanDirtyFlag = self:getNextDirtyFlag()

	return self
end

function ELS_loan:init(farmId, amount, interest, duration, paidOff)
    self.farmId = farmId
    self.amount = amount
    self.interest = interest
    self.duration = duration
    self.restDuration = duration * 12
    self.paidOff = paidOff or false
    self.restAmount = amount
end

function ELS_loan:calculateTotalAmount()
    local periodRate = self:calculateAnnuity()
    local totalAmount = periodRate * (self.duration * 12)
    return totalAmount
end

function ELS_loan:calculateAnnuity()
    local annuity = (self.amount * self:calculateAnnuityFactor())
    return annuity / 12
end

function ELS_loan:calculateAnnuityFactor()
    local annuityFactor = (((1 + (self.interest / 100))^self.duration) * (self.interest / 100)) / (((1 + (self.interest / 100))^self.duration) - 1)
    return annuityFactor
end

function ELS_loan:calculateInterestPortion()
    local interestPortion = ((self.interest / 100) * self.restAmount)
    return interestPortion / 12
end

function ELS_loan:loadFromXMLFile(xmlFile, key)
    self.farmId = xmlFile:getInt(key.."#farmId")
    self.amount = xmlFile:getInt(key.."#amount")
    self.interest = xmlFile:getFloat(key.."#interest")
    self.duration = xmlFile:getInt(key.."#duration")
    self.restDuration = xmlFile:getInt(key.."#restDuration")
    self.paidOff = xmlFile:getBool(key.."#paidOff")
    self.restAmount = xmlFile:getInt(key.."#restAmount")
    return true
end

function ELS_loan:saveToXMLFile(xmlFile, key)
    xmlFile:setInt(key.."#farmId", self.farmId)
    xmlFile:setInt(key.."#amount", self.amount)
    xmlFile:setFloat(key.."#interest", self.interest)
    xmlFile:setInt(key.."#duration", self.duration)
    xmlFile:setInt(key.."#restDuration", self.restDuration)
    xmlFile:setBool(key.."#paidOff", self.paidOff)
    xmlFile:setInt(key.."#restAmount", self.restAmount)
end

function ELS_loan:readStream(streamId, connection)
	ELS_loan:superClass().readStream(self, streamId, connection)

    self.farmId = streamReadInt32(streamId)
    self.amount = streamReadInt32(streamId)
    self.interest = streamReadFloat32(streamId)
    self.duration = streamReadInt32(streamId)
    self.restDuration = streamReadInt32(streamId)
    self.paidOff = streamReadBool(streamId)
    self.restAmount = streamReadInt32(streamId)

    table.insert(g_els_loanManager.loans[self.farmId], self)
end

function ELS_loan:writeStream(streamId, connection)
	ELS_loan:superClass().writeStream(self, streamId, connection)

    streamWriteInt32(streamId, self.farmId)
    streamWriteInt32(streamId, self.amount)
    streamWriteFloat32(streamId, self.interest)
    streamWriteInt32(streamId, self.duration)
    streamWriteInt32(streamId, self.restDuration)
    streamWriteBool(streamId, self.paidOff)
    streamWriteInt32(streamId, self.restAmount)
end

function ELS_loan:readUpdateStream(streamId, timestamp, connection)
    ELS_loan:superClass().readUpdateStream(self, streamId, timestamp, connection)

    self.restDuration = streamReadInt32(streamId)
    self.paidOff = streamReadBool(streamId)
    self.restAmount = streamReadInt32(streamId)
end

function ELS_loan:writeUpdateStream(streamId, connection, dirtyMask)
    ELS_loan:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

    streamWriteInt32(streamId, self.restDuration)
    streamWriteBool(streamId, self.paidOff)
    streamWriteInt32(streamId, self.restAmount)
end
