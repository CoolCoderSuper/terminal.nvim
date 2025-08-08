local M = {}

local term_buffers = {}
local term_order = {}

function M.create_terminal(name)
    local function create_terminal_internal(name)
        if term_buffers[name] and vim.api.nvim_buf_is_valid(term_buffers[name]) then
            return term_buffers[name]
        end

        vim.cmd('term pwsh.exe')
        local buf = vim.api.nvim_get_current_buf()
        vim.cmd('file term://' .. name)
        term_buffers[name] = buf
        table.insert(term_order, name)

        vim.api.nvim_create_autocmd('BufDelete', {
            buffer = buf,
            callback = function(ev)
                local deleted_buf = ev.buf
                local deleted_name = nil
                for name, buffer in pairs(term_buffers) do
                    if buffer == deleted_buf then
                        deleted_name = name
                        break
                    end
                end

                if deleted_name then
                    term_buffers[deleted_name] = nil
                    for i, v in ipairs(term_order) do
                        if v == deleted_name then
                            table.remove(term_order, i)
                            break
                        end
                    end
                    vim.notify('Terminal ' .. deleted_name .. ' closed.')
                end
            end,
        })

        return buf
    end

    if name then
        return create_terminal_internal(name)
    else
        vim.ui.input({ prompt = 'Terminal Name: ' }, function(name)
            if name and name ~= '' then
                local buf = create_terminal_internal(name)
                vim.cmd('buffer ' .. buf)
            end
        end)
    end
end

function M.switch_to_terminal(terminal_name)
    local buf
    if terminal_name then
        if term_buffers[terminal_name] and
            vim.api.nvim_buf_is_valid(term_buffers[terminal_name]) then
            buf = term_buffers[terminal_name]
        else
            vim.notify('Terminal ' .. terminal_name .. ' is no longer valid.')
            term_buffers[terminal_name] = nil
            for i, v in ipairs(term_order) do
                if v == terminal_name then
                    table.remove(term_order, i)
                    break
                end
            end
            return
        end
    else
        if #term_order == 0 then
            vim.notify('No terminals created yet.')
            return
        end

        vim.ui.select(
            term_order,
            { prompt = 'Switch to Terminal' },
            function(choice)
                if choice then
                    switch_to_terminal(choice)
                end
            end
        )
        return
    end

    -- Check if the buffer is in the current tab
    local windows = vim.api.nvim_tabpage_list_wins(0)
    local found = false
    for _, win in ipairs(windows) do
        if vim.api.nvim_win_get_buf(win) == buf then
            found = true
            break
        end
    end

    -- If not in the current tab, switch to the tab containing the buffer
    if not found then
        local tab_list = vim.api.nvim_list_tabpages()
        for _, tab in ipairs(tab_list) do
            local tab_windows = vim.api.nvim_tabpage_list_wins(tab)
            for _, win in ipairs(tab_windows) do
                if vim.api.nvim_win_get_buf(win) == buf then
                    vim.api.nvim_set_current_tabpage(tab)
                    found = true
                    break
                end
            end
            if found then
                break
            end
        end
    end

    vim.cmd('buffer ' .. buf)
end

function M.goto_terminal(num)
    if num > 0 and num <= #term_order then
        local terminal_name = term_order[num]
        switch_to_terminal(terminal_name)
    else
        vim.notify('No terminal at index ' .. num .. ' exists.')
    end
end

function M.close_terminal()
    local current_buf = vim.api.nvim_get_current_buf()
    local terminal_name = nil

    for name, buf in pairs(term_buffers) do
        if buf == current_buf then
            terminal_name = name
            break
        end
    end

    if terminal_name then
        vim.cmd('bdelete!')
    else
        vim.notify('Not in a managed terminal.')
    end
end

function M.setup_default()
    vim.keymap.set('n', '<leader>tp', function()
        M.switch_to_terminal()
    end, { desc = 'Switch Terminal' })

    vim.keymap.set('n', '<leader>tn', function()
        M.create_terminal(name)
    end, { desc = 'New Terminal' })

    for i = 1, 9 do
        vim.keymap.set('n', '<leader>t' .. i, function()
            M.goto_terminal(i)
        end, { desc = 'Terminal ' .. i })
    end

    vim.keymap.set('n', '<leader>tc', function()
        M.close_terminal()
    end, { desc = 'Close Terminal' })

    vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])
end

return M
