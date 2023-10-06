-- Name: ELS_loanManagerProperties
-- Author: Chissel

ELS_loanManagerProperties = {}
local ELS_loanManagerProperties_mt = Class(ELS_loanManagerProperties, Object)

InitObjectClass(ELS_loanManagerProperties, "ELS_loanManagerProperties")

ELS_loanManagerProperties.minLoanInterest = 1.0
ELS_loanManagerProperties.maxLoanInterest = 10.0
ELS_loanManagerProperties.loanInterestSteps = 0.1
ELS_loanManagerProperties.loanInterestStartValue = 3.5
ELS_loanManagerProperties.farmlandMortgagePercentage = 0.6
ELS_loanManagerProperties.loanDurationStartValue = 20
ELS_loanManagerProperties.loanDurationSteps = 5
ELS_loanManagerProperties.minLoanDurationStep = 5
ELS_loanManagerProperties.maxLoanDurationStep = 50
ELS_loanManagerProperties.operatingLoanInterestFactor = 1.75

function ELS_loanManagerProperties.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or ELS_loanManagerProperties_mt)

    self.loanInterest = ELS_loanManagerProperties.loanInterestStartValue
    self.maxLoanDuration = ELS_loanManagerProperties.loanDurationStartValue
    self.dynamicLoanInterest = true
	self.propertiesDirtyFlag = self:getNextDirtyFlag()

	return self
end

function ELS_loanManagerProperties:getLoanInterestSteps()
    local steps = {}

    for i = self.minLoanInterest, self.maxLoanInterest, self.loanInterestSteps do
        table.insert(steps, tostring(i))
    end

    return steps
end

function ELS_loanManagerProperties:getLoanDurationSteps()
    local steps = {}

    for i = self.minLoanDurationStep, self.maxLoanDurationStep, self.loanDurationSteps do
        table.insert(steps, tostring(i))
    end

    return steps
end

function ELS_loanManagerProperties:loadFromXMLFile(xmlFile, key)
    local loanInterest = xmlFile:getFloat(key.."#loanInterest") or ELS_loanManagerProperties.loanInterestStartValue
    self.loanInterest = tonumber(string.format("%.2f", loanInterest))
    self.dynamicLoanInterest = xmlFile:getBool(key.."#dynamicLoanInterest") or true
    self.maxLoanDuration = xmlFile:getInt(key.."#maxLoanDuration") or ELS_loanManagerProperties.loanDurationStartValue
    return true
end

function ELS_loanManagerProperties:saveToXMLFile(xmlFile, key)
    xmlFile:setFloat(key.."#loanInterest", self.loanInterest)
    xmlFile:setBool(key.."#dynamicLoanInterest", self.dynamicLoanInterest)
    xmlFile:setInt(key.."#maxLoanDuration", self.maxLoanDuration)
end

function ELS_loanManagerProperties:readStream(streamId, connection)
	ELS_loanManagerProperties:superClass().readStream(self, streamId, connection)

    self.loanInterest = streamReadFloat32(streamId)
    self.dynamicLoanInterest = streamReadBool(streamId)
    self.maxLoanDuration = streamReadInt32(streamId)

    g_els_loanManager.loanManagerProperties = self
end

function ELS_loanManagerProperties:writeStream(streamId, connection)
	ELS_loanManagerProperties:superClass().writeStream(self, streamId, connection)

    streamWriteFloat32(streamId, self.loanInterest)
    streamWriteBool(streamId, self.dynamicLoanInterest)
    streamWriteInt32(streamId, self.maxLoanDuration)
end

function ELS_loanManagerProperties:readUpdateStream(streamId, timestamp, connection)
    ELS_loanManagerProperties:superClass().readUpdateStream(self, streamId, timestamp, connection)

    self.loanInterest = streamReadFloat32(streamId)
    self.dynamicLoanInterest = streamReadBool(streamId)
    self.maxLoanDuration = streamReadInt32(streamId)
end

function ELS_loanManagerProperties:writeUpdateStream(streamId, connection, dirtyMask)
    ELS_loanManagerProperties:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

    streamWriteFloat32(streamId, self.loanInterest)
    streamWriteBool(streamId, self.dynamicLoanInterest)
    streamWriteInt32(streamId, self.maxLoanDuration)
end
