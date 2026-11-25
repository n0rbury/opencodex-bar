-- Run from repository root: lua tests/test_panel_provider_order.lua
local file = assert(io.open("panel.luau"))
local source = file:read("*a")
file:close()
local fn = assert(source:match("(local function enabledProviders%(%)[%s%S]-\nend)"))
local config = {}
local env = setmetatable({noctalia={getConfig=function(k) return config[k] end}}, {__index=_G})
env.common = assert(loadfile("common.luau","t",env))()
env.currentSnapshot = {providers={
  {id="openai",enabled=true},
  {id="opencode-go",enabled=true},
  {id="deepseek",enabled=true},
  {id="disabled",enabled=false},
}}
local enabled = assert(load(fn.."\nreturn enabledProviders","panel providers","t",env))()
local function check(list, hidden, expected)
  config.panel_providers, config.hidden_providers = list, hidden
  local ids = {}
  for _, provider in ipairs(enabled()) do ids[#ids+1] = provider.id end
  assert(table.concat(ids,",") == expected, table.concat(ids,","))
end
check(nil,nil,"openai,opencode-go,deepseek")
check("",nil,"openai,opencode-go,deepseek")
check(" , ",nil,"openai,opencode-go,deepseek")
check("opencode-go, openai",nil,"opencode-go,openai")
check("CODEX, openai, opencode-go, opencode-go",nil,"openai,opencode-go")
check("disabled, unknown, deepseek",nil,"deepseek")
check("openai, opencode-go","codex","opencode-go")
check("unknown",nil,"")
print("Panel provider order tests passed")
