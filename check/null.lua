--[[
Copyright 2012 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

local BaseCheck = require('./base').BaseCheck
local CheckResult = require('./base').CheckResult

local NullCheck = BaseCheck:extend()

function NullCheck:initialize(params)
  BaseCheck.initialize(self, params)
end

function NullCheck:getType()
  return "NULL"
end

function NullCheck:run(callback)
end

local exports = {}
exports.NullCheck = NullCheck
return exports
