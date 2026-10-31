-- Specs replace vim functions and never put them back, so restore them after each file
local busted = require('busted')

local tables = { 'api', 'fn', 'keymap', 'ui' }
local saved = {}

local function copy(source)
  local result = {}
  for key, value in pairs(source) do
    result[key] = value
  end
  return result
end

local function restore(target, snapshot)
  for key in pairs(target) do
    if snapshot[key] == nil then
      rawset(target, key, nil)
    end
  end
  for key, value in pairs(snapshot) do
    target[key] = value
  end
end

busted.subscribe({ 'file', 'start' }, function()
  saved.vim = {
    cmd = vim.cmd,
    notify = vim.notify,
    bo = vim.bo,
    schedule = vim.schedule,
    defer_fn = vim.defer_fn,
  }
  for _, name in ipairs(tables) do
    saved[name] = { ref = vim[name], fields = copy(vim[name]) }
  end
  return nil, true
end)

busted.subscribe({ 'file', 'end' }, function()
  for key, value in pairs(saved.vim) do
    vim[key] = value
  end
  for _, name in ipairs(tables) do
    vim[name] = saved[name].ref
    restore(vim[name], saved[name].fields)
  end
  return nil, true
end)
