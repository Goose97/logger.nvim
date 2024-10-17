local M = {}
local assert = require("luassert")

---Setup a buffer with the given input and filetype.
---@param lines string[]
---@param cursor {[1]: number, [2]: number}
---@param filetype string
local function setup_buffer(lines, cursor, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
  vim.api.nvim_command("buffer " .. buf)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
  vim.api.nvim_win_set_cursor(0, cursor)
end

---Assert the output of the current buffer.
---@param lines string[]
local function assert_buf_output(lines)
  local output = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert.are.same(lines, output)
end

---Trim the redundant whitespaces from the input lines.
---@param input string
---@return string[], {[1]: number, [2]: number}
local function parse_input(input)
  local lines = vim.split(input, "\n")
  local biggest_indent = 0

  for _, line in ipairs(lines) do
    -- Count the number of leading whitespaces
    local leading_whitespaces = line:match("^%s*")
    biggest_indent = math.max(biggest_indent, #leading_whitespaces)
  end

  local cursor

  for i, line in ipairs(lines) do
    line = line:sub(biggest_indent + 1)

    local start_index = line:find("|")
    if start_index then
      cursor = { i, start_index - 2 }
      line = line:sub(1, cursor[2] + 1) .. line:sub(cursor[2] + 3)
    end

    lines[i] = line
  end

  return lines, cursor
end

---@class Scenario
---@field input string
---@field filetype string
---@field action function
---@field expected string

---Given an input, execute a callback, and assert the expected output.
---The input supports specifying the cursor position with a pipe character.
---The cursor will be on the letter before the pipe character.
---In this example, the cursor is at position {1, 7} (at the first o in foo)
---  const fo|o = "bar"
---  const bar = "baz"
---@param scenario Scenario
function M.assert_scenario(scenario)
  local input_lines, cursor = parse_input(scenario.input)
  setup_buffer(input_lines, cursor, scenario.filetype)
  scenario.action()

  local expected_lines = parse_input(scenario.expected)
  assert_buf_output(expected_lines)
end

return M
