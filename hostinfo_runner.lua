--[[
Copyright 2014 Rackspace

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
local HostInfo = require('hostinfo')
local json = require('json')

local exports = {}

local argv = require("options")
  .usage('Usage: -x [Host Info Type]')
  .describe("x", "host info type to run")
  .argv("x:")

exports.run = function()
  if not argv.args.x then
    process.stdout:write(argv._usage .. '\n')
    process.exit(0)
  end
  process.stdout:write("HostInfo Running " .. argv.args.x .. "\n")

  local klass = HostInfo.create(argv.args.x)

  klass:run(function(err, callback)
    process.stdout:write("Serialized Results:\n" .. json.stringify(klass:serialize(), {beautify = true}))
  end)

end


return exports
