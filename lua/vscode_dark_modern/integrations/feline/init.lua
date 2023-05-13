local colors = require("vscode_dark_modern.palette")

local M = {}

M.palette = function()
    return {
        bg = colors.bg_01,
        fg = colors.fg_11,
        vi_mode_bg = "#0078d4",
        separator = "#2a2a2a",
    }
end

local diagnostic = {
    error = colors.red_04,
    warn = colors.yellow_03,
    info = colors.blue_07,
    hint = colors.green_05,
}

local git = {
    added = colors.green_01,
    deleted = colors.red_05,
    changed = colors.blue_01,
}

M.components = function()
    local components = { active = {}, inactive = {} }

    local vi_mode_utils = require("feline.providers.vi_mode")

    components.active[1] = {
        {
            provider = " ",
            hl = { bg = "vi_mode_bg" },
        },
        {
            provider = "vi_mode",
            hl = function()
                return {
                    name = vi_mode_utils.get_mode_highlight_name(),
                    style = "NONE",
                    bg = "vi_mode_bg",
                }
            end,
            icon = "",
        },
        {
            provider = " ",
            hl = { bg = "vi_mode_bg" },
        },
        {
            provider = function()
                local msg = "LSP inactive"
                local buf = vim.api.nvim_get_current_buf()
                local buf_clients = vim.lsp.get_active_clients({ bufnr = buf })
                if next(buf_clients) == nil then
                    return msg
                end

                local buf_client_names = {}
                for _, client in pairs(buf_clients) do
                    if client.name ~= "null-ls" then
                        table.insert(buf_client_names, client.name)
                    end
                end

                local unique_client_names = vim.fn.uniq(buf_client_names)
                return table.concat(unique_client_names, " ")
            end,
            left_sep = " ",
        },
        {
            provider = function()
                local buf_clients = vim.lsp.get_active_clients()

                if next(buf_clients) == nil then
                    return ""
                end

                local null_ls_running = false

                for _, client in pairs(buf_clients) do
                    if client.name == "null-ls" then
                        null_ls_running = true
                    end
                end

                if not null_ls_running then
                    return ""
                end

                local filetype = vim.bo.filetype

                local ok, sources = pcall(require, "null-ls.sources")
                if not ok then
                    return ""
                end

                local available_sources = sources.get_available(filetype)

                local sources_registered = {}
                for _, source in ipairs(available_sources) do
                    table.insert(sources_registered, source.name)
                end

                return table.concat(sources_registered, " ")
            end,
            left_sep = " ",
            right_sep = " ",
        },
        {
            provider = "diagnostic_errors",
            icon = " ",
            hl = { fg = diagnostic.error },
            left_sep = " ",
            right_sep = " ",
        },
        {
            provider = "diagnostic_warnings",
            icon = " ",
            hl = { fg = diagnostic.warn },
            left_sep = " ",
            right_sep = " ",
        },
        {
            provider = "diagnostic_hints",
            icon = " ",
            hl = { fg = diagnostic.hint },
            left_sep = " ",
            right_sep = " ",
        },
        {
            provider = "diagnostic_info",
            icon = " ",
            hl = { fg = diagnostic.info },
            left_sep = " ",
            right_sep = " ",
        },
        {
            provider = function()
                local lsp = vim.lsp.util.get_progress_messages()[1]

                if lsp then
                    local msg = lsp.message or ""
                    local percentage = lsp.percentage or 0
                    local title = lsp.title or ""

                    local spinners = { "", "󰀚", "" }

                    local success_icon = { "", "", "" }

                    local ms = vim.loop.hrtime() / 1000000
                    local frame = math.floor(ms / 120) % #spinners

                    if percentage >= 70 then
                        return string.format(" %%<%s %s %s (%s%%%%)", success_icon[frame + 1], title, msg, percentage)
                    end

                    return string.format(" %%<%s %s %s (%s%%%%)", spinners[frame + 1], title, msg, percentage)
                end

                return ""
            end,
            hl = { fg = diagnostic.info },
        },
    }
    components.active[2] = {
        {
            provider = "git_diff_added",
            icon = " +",
            hl = { fg = git.added },
        },
        {
            provider = "git_diff_changed",
            icon = " ~",
            hl = { fg = git.changed },
        },
        {
            provider = "git_diff_removed",
            icon = " -",
            hl = { fg = git.deleted },
        },
        {
            provider = "git_branch",
            icon = { str = "󰘬 ", hl = { fg = colors.orange_03 } },
            left_sep = "  ",
            right_sep = { str = " | ", hl = { fg = "separator" } },
        },
        { provider = "line_percentage" },
        {
            provider = function()
                local total_lines = vim.fn.line("$")
                local total_visible_lines = vim.fn.line("w$")

                if total_lines <= total_visible_lines then
                    return ""
                end

                return total_lines .. " lines"
            end,
            icon = " ",
            left_sep = { str = " | ", hl = { fg = "separator" } },
        },
        {
            provider = { name = "file_info", opts = { file_readonly_icon = " ", file_modified_icon = "" } },
            left_sep = { str = " | ", hl = { fg = "separator" } },
        },
        {
            provider = function()
                local word = vim.bo.expandtab and "Spaces" or "Tab Size"
                return word .. ": " .. ((vim.bo.tabstop ~= "" and vim.bo.tabstop) or vim.o.tabstop)
            end,
            left_sep = { str = " | ", hl = { fg = "separator" } },
        },
        {
            provider = function()
                return ((vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc):upper()
            end,
            left_sep = { str = " | ", hl = { fg = "separator" } },
        },
        {
            provider = function()
                local fileformat = ((vim.bo.fileformat ~= "" and vim.bo.fileformat) or vim.o.fileformat)
                if fileformat == "unix" then
                    return "LF"
                else
                    return "CRLF"
                end
            end,
            left_sep = { str = " | ", hl = { fg = "separator" } },
        },
        {
            -- provider = "file_type",
            provider = function()
                local ft = vim.bo.filetype

                if ft == "" then
                    ft = vim.fn.expand("%:e")

                    if ft == "" then
                        local buf = vim.api.nvim_get_current_buf()
                        local bufname = vim.api.nvim_buf_get_name(buf)

                        if bufname == vim.loop.cwd() then
                            return "Directory"
                        end
                    end
                end

                local filetypes = require("vscode_dark_modern.integrations.feline.filetypes")
                return filetypes[ft]
            end,
            left_sep = { str = " | ", hl = { fg = "separator" } },
            right_sep = "  ",
        },
    }
    components.inactive[1] = {
        {
            provider = " ",
            hl = { bg = "vi_mode_bg" },
        },
        {
            provider = "file_type",
            hl = { bg = "vi_mode_bg" },
        },
        {
            provider = " ",
            hl = { bg = "vi_mode_bg" },
            right_sep = { " " },
        },
    }
    components.inactive[2] = {}

    return components
end

return M
