vim.g.mapleader = " "                 -- leader = space (set before mappings)
vim.g.maplocalleader = " "            -- local leader = space

vim.keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "netrw" })  -- file explorer
