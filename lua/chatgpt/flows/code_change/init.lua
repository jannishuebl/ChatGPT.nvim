local Api = require("chatgpt.api")
local Utils = require("chatgpt.utils")
local Signs = require("chatgpt.signs")
local Spinner = require("chatgpt.spinner")

local M = {}

local namespace_id = vim.api.nvim_create_namespace("ChatGPTCC")

-- Ersetze 'my_plugin' mit dem tatsächlichen Namen deines Plugins
local function extract_visual_selection()
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        
        local start_line = start_pos[2]
        local start_col = start_pos[3]
        local end_line = end_pos[2]
        local end_col = end_pos[3]
        
        local lines = vim.fn.getline(start_line, end_line)
        
        -- Bearbeite die erste Zeile, um den Anfang der Auswahl zu berücksichtigen
        lines[1] = lines[1]:sub(start_col)
        
        -- Bearbeite die letzte Zeile, um das Ende der Auswahl zu berücksichtigen
        lines[#lines] = lines[#lines]:sub(1, end_col)
        
        local selected_text = table.concat(lines, '\n')
        return selected_text
end

function open_new_buffer(contents)
    -- Create a new buffer
    local buffer = vim.api.nvim_create_buf(false, true)

    -- Set the contents of the buffer
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, contents)

    -- Open the buffer in a new vertical split window
    vim.cmd("vertical belowright sb " .. buffer)

    return buffer
end

M.change = function()
  local selected_text = extract_visual_selection()

  local Input = require("nui.input")
  
  local input = Input({
    position = "50%",
    size = {
      width = 80,
    },
    border = {
      style = "single",
      text = {
        top = "[What do to?]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    prompt = "> ",
    default_value = "",
    on_close = function()
      print("Input Closed!")
    end,
    on_submit = function(value)
	  if string.len(selected_text) < 4000 then
		  model = "gpt-4"
		  max_tokens = 4096
	  else
		  model = "gpt-4-32k"
		  max_tokens = 16000
	  end
	  Api.chat_completions({
	    model = model,
	    messages = {
	       {
		  role = "user",
		  content = value
	       },
	       {
		  role = "system",
		  content = "Antworte nur in einem codeblock!"
	       },
	       {
		  role = "system",
		  content = selected_text
	       }
	     },
	    max_tokens = max_tokens, 
	    presence_penalty = 0.6,
	  }, function(answer, usage)
	    local lines = Utils.split_string_by_line(answer)
	    open_new_buffer(lines)

	  end)
    end,
  })
  
  -- mount/open the component
  input:mount()
  
end

M.fib = function() end

return M
