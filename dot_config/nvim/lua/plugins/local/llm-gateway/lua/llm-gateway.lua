local M = {}

M.config = {
  gateway_url = "http://localhost:3009",
  default_session_id = "neovim-session",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Create user commands
  vim.api.nvim_create_user_command("DingSelect", function()
    M.select_model()
  end, { desc = "Select LLM model" })
  
  vim.api.nvim_create_user_command("DingRefreshModels", function()
    M.refresh_models()
  end, { desc = "Refresh LLM models" })
  
  vim.api.nvim_create_user_command("DingClearSession", function()
    M.clear_session()
  end, { desc = "Clear LLM session" })
end

function M.select_model()
  local curl = require("plenary.curl")
  
  -- Get available models
  curl.get({
    url = M.config.gateway_url .. "/models",
    callback = function(response)
      if response.status == 200 then
        local models_data = vim.json.decode(response.body)
        local models = models_data.models or {}
        
        vim.schedule(function()
          vim.ui.select(models, {
            prompt = "Select LLM model:",
            format_item = function(item)
              return item
            end,
          }, function(choice)
            if choice then
              M.set_default_model(choice)
            end
          end)
        end)
      else
        vim.schedule(function()
          vim.notify("Failed to fetch models: " .. response.status, vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

function M.set_default_model(model)
  local curl = require("plenary.curl")
  
  curl.post({
    url = M.config.gateway_url .. "/set-default-model",
    body = vim.json.encode({ model = model }),
    headers = { ["Content-Type"] = "application/json" },
    callback = function(response)
      vim.schedule(function()
        if response.status == 200 then
          vim.notify("Model set to: " .. model, vim.log.levels.INFO)
        else
          vim.notify("Failed to set model: " .. response.status, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

function M.refresh_models()
  local curl = require("plenary.curl")
  
  curl.get({
    url = M.config.gateway_url .. "/models",
    callback = function(response)
      vim.schedule(function()
        if response.status == 200 then
          local models_data = vim.json.decode(response.body)
          local count = #(models_data.models or {})
          vim.notify("Refreshed " .. count .. " models", vim.log.levels.INFO)
        else
          vim.notify("Failed to refresh models: " .. response.status, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

function M.clear_session()
  local curl = require("plenary.curl")
  
  curl.post({
    url = M.config.gateway_url .. "/clear?id=" .. M.config.default_session_id,
    callback = function(response)
      vim.schedule(function()
        if response.status == 200 then
          vim.notify("Session cleared", vim.log.levels.INFO)
        else
          vim.notify("Failed to clear session: " .. response.status, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return M