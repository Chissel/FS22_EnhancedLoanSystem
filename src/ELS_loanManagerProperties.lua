-- Name: ELS_loanManagerProperties
-- Author: Chissel

ELS_loanManagerProperties = {}
local ELS_loanManagerProperties_mt = Class(ELS_loanManagerProperties, Object)

InitObjectClass(ELS_loanManagerProperties, "ELS_loanManagerProperties")

ELS_loanManagerProperties.minLoanInterest = 1.0
ELS_loanManagerProperties.maxLoanInterest = 10.0
ELS_loanManagerProperties.loanInterestSteps = 0.1
ELS_loanManagerProperties.loanInterestStartValue = 3.5

function ELS_loanManagerProperties.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or ELS_loanManagerProperties_mt)

    self.loanInterest = ELS_loanManagerProperties.loanInterestStartValue
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

function ELS_loanManagerProperties:loadFromXMLFile(xmlFile, key)
    local loanInterest = xmlFile:getFloat(key.."#loanInterest") or ELS_loanManagerProperties.loanInterestStartValue
    self.loanInterest = tonumber(string.format("%.2f", loanInterest))
    self.dynamicLoanInterest = xmlFile:getBool(key.."#dynamicLoanInterest") or true
    return true
end

function ELS_loanManagerProperties:saveToXMLFile(xmlFile, key)
    xmlFile:setFloat(key.."#loanInterest", self.loanInterest)
    xmlFile:setBool(key.."#dynamicLoanInterest", self.dynamicLoanInterest)
end

function ELS_loanManagerProperties:readStream(streamId, connection)
	ELS_loanManagerProperties:superClass().readStream(self, streamId, connection)

    self.loanInterest = streamReadFloat32(streamId)
    self.dynamicLoanInterest = streamReadBool(streamId)

    g_els_loanManager.loanManagerProperties = self
end

function ELS_loanManagerProperties:writeStream(streamId, connection)
	ELS_loanManagerProperties:superClass().writeStream(self, streamId, connection)

    streamWriteFloat32(streamId, self.loanInterest)
    streamWriteBool(streamId, self.dynamicLoanInterest)
end

function ELS_loanManagerProperties:readUpdateStream(streamId, timestamp, connection)
    ELS_loanManagerProperties:superClass().readUpdateStream(self, streamId, timestamp, connection)

    self.loanInterest = streamReadFloat32(streamId)
    self.dynamicLoanInterest = streamReadBool(streamId)
end

function ELS_loanManagerProperties:writeUpdateStream(streamId, connection, dirtyMask)
    ELS_loanManagerProperties:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

    streamWriteFloat32(streamId, self.loanInterest)
    streamWriteBool(streamId, self.dynamicLoanInterest)
end
