local JSON = require('json')
local LineEmitter = require('line-emitter')
local tls = require('tls')
local timer = require('timer')
local string = require('string')
local math = require('math')
local table = require('table')
local http = require("http")
local url = require('url')
local utils = require('utils')
local misc = require('/base/util/misc')
local fs = require('fs')
local path = require('path')
local fmt = require('string').format
local os = require('os')
local Emitter = require('core').Emitter

local fixtures = require('./fixtures')

local ports = {50041, 50051, 50061}

local function clear_timers(log, timer_ids)
  log('Clearing timers')
  for k, v in pairs(timer_ids) do
    if v._closed ~= true then
      timer.clearTimer(v)
    end
  end
end

local send_request = function(log, client, fixture)
  print('requiring', fixture)
  local request = fixtures[fixture]
  log("Sending request:" .. request)
  client:write(request .. '\n')
end

local opts = {}
local function set_option(options, name, default)
  options[name] = process.env[string.upper(name)] or default
end

set_option(opts, "send_schedule_changed_initial", 2000)
set_option(opts, "send_schedule_changed_interval", 60000)
set_option(opts, "destroy_connection_jitter", 60000)
set_option(opts, "destroy_connection_base", 60000)
set_option(opts, "listen_ip", '127.0.0.1')
set_option(opts, "perform_client_disconnect", 'true')
set_option(opts, "send_download_upgrade", 1000)

set_option(opts, "rate_limit", 3000)
set_option(opts, "rate_limit_reset", 86400) -- Reset limit in 24 hours

local TIMEOUTS = {}
TIMEOUTS[opts.send_schedule_changed_initial] = function(log, client)
  send_request(log, client, 'check_schedule.changed.request')
end
TIMEOUTS[opts.send_download_upgrade] = function(log, client)
  send_request(log, client, 'bundle_upgrade.available.request')
end
TIMEOUTS[opts.rate_limit_reset] = function(log, client)
  client.rate_limit = opts.rate_limit
end

local INTERVALS = {}
INTERVALS[opts.send_schedule_changed_interval] = function(log, client)
  send_request(log, client, 'check_schedule.changed.request')
end

local keyPem = [[
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDx3wdzpq2rvwm3Ucun1qAD/ClB+wW+RhR1nVix286QvaNqePAd
CAwwLL82NqXcVQRbQ4s95splQnwvjgkFdKVXFTjPKKJI5aV3wSRN61EBVPdYpCre
535yfG/uDysZFCnVQdnCZ1tnXAR8BirxCNjHqbVyIyBGjsNoNCEPb2R35QIDAQAB
AoGBAJNem9C4ftrFNGtQ2DB0Udz7uDuucepkErUy4MbFsc947GfENjDKJXr42Kx0
kYx09ImS1vUpeKpH3xiuhwqe7tm4FsCBg4TYqQle14oxxm7TNeBwwGC3OB7hiokb
aAjbPZ1hAuNs6ms3Ybvvj6Lmxzx42m8O5DXCG2/f+KMvaNUhAkEA/ekrOsWkNoW9
2n3m+msdVuxeek4B87EoTOtzCXb1dybIZUVv4J48VAiM43hhZHWZck2boD/hhwjC
M5NWd4oY6QJBAPPcgBVNdNZSZ8hR4ogI4nzwWrQhl9MRbqqtfOn2TK/tjMv10ALg
lPmn3SaPSNRPKD2hoLbFuHFERlcS79pbCZ0CQQChX3PuIna/gDitiJ8oQLOg7xEM
wk9TRiDK4kl2lnhjhe6PDpaQN4E4F0cTuwqLAoLHtrNWIcOAQvzKMrYdu1MhAkBm
Et3qDMnjDAs05lGT72QeN90/mPAcASf5eTTYGahv21cb6IBxM+AnwAPpqAAsHhYR
9h13Y7uYbaOjvuF23LRhAkBoI9eaSMn+l81WXOVUHnzh3ZwB4GuTyxMXXNOhuiFd
0z4LKAMh99Z4xQmqSoEkXsfM4KPpfhYjF/bwIcP5gOei
-----END RSA PRIVATE KEY-----
]]

local certPem = [[
-----BEGIN CERTIFICATE-----
MIIDXDCCAsWgAwIBAgIJAKL0UG+mRkSPMA0GCSqGSIb3DQEBBQUAMH0xCzAJBgNV
BAYTAlVLMRQwEgYDVQQIEwtBY2tuYWNrIEx0ZDETMBEGA1UEBxMKUmh5cyBKb25l
czEQMA4GA1UEChMHbm9kZS5qczEdMBsGA1UECxMUVGVzdCBUTFMgQ2VydGlmaWNh
dGUxEjAQBgNVBAMTCWxvY2FsaG9zdDAeFw0wOTExMTEwOTUyMjJaFw0yOTExMDYw
OTUyMjJaMH0xCzAJBgNVBAYTAlVLMRQwEgYDVQQIEwtBY2tuYWNrIEx0ZDETMBEG
A1UEBxMKUmh5cyBKb25lczEQMA4GA1UEChMHbm9kZS5qczEdMBsGA1UECxMUVGVz
dCBUTFMgQ2VydGlmaWNhdGUxEjAQBgNVBAMTCWxvY2FsaG9zdDCBnzANBgkqhkiG
9w0BAQEFAAOBjQAwgYkCgYEA8d8Hc6atq78Jt1HLp9agA/wpQfsFvkYUdZ1YsdvO
kL2janjwHQgMMCy/Njal3FUEW0OLPebKZUJ8L44JBXSlVxU4zyiiSOWld8EkTetR
AVT3WKQq3ud+cnxv7g8rGRQp1UHZwmdbZ1wEfAYq8QjYx6m1ciMgRo7DaDQhD29k
d+UCAwEAAaOB4zCB4DAdBgNVHQ4EFgQUL9miTJn+HKNuTmx/oMWlZP9cd4QwgbAG
A1UdIwSBqDCBpYAUL9miTJn+HKNuTmx/oMWlZP9cd4ShgYGkfzB9MQswCQYDVQQG
EwJVSzEUMBIGA1UECBMLQWNrbmFjayBMdGQxEzARBgNVBAcTClJoeXMgSm9uZXMx
EDAOBgNVBAoTB25vZGUuanMxHTAbBgNVBAsTFFRlc3QgVExTIENlcnRpZmljYXRl
MRIwEAYDVQQDEwlsb2NhbGhvc3SCCQCi9FBvpkZEjzAMBgNVHRMEBTADAQH/MA0G
CSqGSIb3DQEBBQUAA4GBADRXXA2xSUK5W1i3oLYWW6NEDVWkTQ9RveplyeS9MOkP
e7yPcpz0+O0ZDDrxR9chAiZ7fmdBBX1Tr+pIuCrG/Ud49SBqeS5aMJGVwiSd7o1n
dhU2Sz3Q60DwJEL1VenQHiVYlWWtqXBThe9ggqRPnCfsCRTP8qifKkjk45zWPcpN
-----END CERTIFICATE-----
]]

local Server = Emitter:extend()
function Server:initialize(options)
  self.port = 0
  self.options = misc.merge({
    cert = certPem,
    key = keyPem,
    includeTimeouts = true,
  }, options)
  self.server = tls.createServer(self.options, utils.bind(self._onClient, self))
  self.log = utils.bind(self._defaultLog, self)()
end

function Server:_defaultLog()
  return function(...)
    print(self.port .. ": " .. ...)
  end
end

function Server:_enableHTTPResponder(client, server)
  http.onClient(server, client, function(req, res)
    local part, parts, file_path

    local _reply_http = function(status, data)
      status = status or 200
      data = data and tostring(data) or "hello"
      res:writeHead(status, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #data
      })
      self.log('sending reply to POST: '.. data)
      res:finish(data)
    end

    res.should_keep_alive = false

    if req.method == 'POST' then
      local recieved = 0
      req:on('data', function(d)
        recieved =  recieved + #d
      end)
      req:on('end', function()
        _reply_http(204, fmt('got %d bytes', recieved))
      end)

      return
    end

    -- path on disk
    file_path = fmt("static_files%s", req.url)
    -- split path on /
    parts = {}
    for part in file_path:gmatch("[^/]+") do
      parts[#parts + 1] = part
    end
    -- join path on the / or \\
    file_path = path.join(__dirname, unpack(parts))

    fs.readFile(file_path, function(err, data)
      local status = 200
      if err then
        self.log('got err:' .. tostring(err))
        data = err
        status = 500
      end
      return _reply_http(status, data)
    end)
  end)
end

function Server:_onLineProtocol(client, line)
  local status, err, payload
  
  status, err = pcall(function()
    payload = JSON.parse(line)
  end)

  if not status then
    self.log('Error Parsing JSON Message', err)
    return
  end

  -- skip responses to requests
  if payload.method == nil then
    return
  end

  local response = JSON.parse(fixtures[payload.method .. '.response'])

  -- Handle rate limit logic
  local destroy = false
  client.rate_limit = client.rate_limit - 1
  if client.rate_limit <= 0 then
    response = JSON.parse(fixtures['rate-limiting']['rate-limit-error'])
    destroy = true
  end

  response.target = payload.source
  response.source = payload.target
  response.id = payload.id

  local response_out = JSON.stringify(response)
  response_out:gsub("\n", " ")

  self.log("Sending response:" .. response_out)
  client:write(response_out .. '\n')

  if destroy == true then
    client:destroy()
  end
end

function Server:_enableJSONResponder(client)
  local timers = {}
  local le = LineEmitter.LineEmitter:new()

  client.rate_limit = opts.rate_limit

  client:once('end', function()
    clear_timers(self.log, timers)
  end)

  client:once('error', function(err)
    self.log('got error: ')
    p(err)
    client:destroy()
  end)

  client:pipe(le)
  le:on('data', utils.bind(self._onLineProtocol, self, client))

  if self.options.includeTimeouts then
    for timeout, f in pairs(TIMEOUTS) do
      table.insert(timers, timer.setTimeout(timeout, utils.bind(f, self.log, client)))
    end

    for timeout, f in pairs(INTERVALS) do
      table.insert(timers, timer.setInterval(timeout, utils.bind(f, self.log, client)))
    end
  end

  -- Disconnect the agent after some random number of seconds
  -- to exercise reconnect logic
  if opts.perform_client_disconnect == 'true' then
    local disconnect_time = opts.destroy_connection_base +
      math.floor(math.random() * opts.destroy_connection_jitter)
    self.log("Destroying connection after " .. disconnect_time .. "ms connected")
    table.insert(timers, timer.setTimeout(disconnect_time, function()
      self.log("Destroyed connection after " .. disconnect_time .. "ms connected")
      client:destroy()
    end))
  end
end

function Server:_onClient(client)
  client:once('data', function(data)
    local char = data:sub(0,1):lower()

    self.log(data)

    if char == "{" then
      self:_enableJSONResponder(client)
    else
      self:_enableHTTPResponder(client)
    end

    -- the server hadn't set up listeners when we got the request, so we have to reemit it
    client:emit('data', data)
  end)
end

function Server:listen(port, ip, callback)
  self.port = port
  self.ip = ip
  self.server:listen(self.port, ip, callback)
end

function Server:close()
  self.server:close()
end

local servers = {}

local function create_server(port)
  local srv = Server:new()
  srv:listen(port, opts.listen_ip)
  table.insert(servers, srv)
end

local function run()
  -- There is no cleanup code for the server here as the process for exiting is
  -- to just ctrl+c the runner or kill the process.
  for _, port in pairs(ports) do
    print("TLS fixture server listening on port " .. port)
    create_server(port)
  end
end
--
local exports = {}
exports.run = run
exports.Server = Server
return exports
