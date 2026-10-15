-- Leader = space (måste sättas före mappningar)
vim.g.mapleader = " "                 -- <leader> blir mellanslag
vim.g.maplocalleader = " "            -- <localleader> (filtyp-specifika mappningar) blir också mellanslag

local o = vim.opt                     -- kortnamn så vi slipper skriva vim.opt hela tiden

-- UI
o.number = true                       -- visa radnummer
o.relativenumber = true               -- radnummer relativt markören (smidigt för t.ex. 5j, 3dd)
o.signcolumn = "yes"                  -- alltid visa teckenkolumnen så texten inte hoppar i sidled
o.cursorline = true                   -- markera raden där markören står
o.termguicolors = true                -- 24-bitars färger i terminalen
o.scrolloff = 8                       -- håll minst 8 rader synliga ovanför/under markören
o.wrap = false                        -- radbryt inte långa rader
o.splitright = true                   -- vertikala splittar öppnas till höger
o.splitbelow = true                   -- horisontella splittar öppnas nedanför

-- Indentering
o.expandtab = true                    -- Tab infogar mellanslag istället för tabbtecken
o.shiftwidth = 4                      -- >> och << flyttar 4 steg
o.tabstop = 4                         -- ett tabbtecken visas som 4 kolumner
o.smartindent = true                  -- automatisk indentering på nya rader

-- Sökning
o.ignorecase = true                   -- sök utan hänsyn till versaler/gemener...
o.smartcase = true                    -- ...utom när sökningen innehåller en versal
o.hlsearch = true                     -- markera alla sökträffar
o.incsearch = true                    -- visa träffar medan du skriver

-- Timeouts
o.timeoutlen = 300                    -- hur länge Neovim väntar på nästa tangent i en mappning (ms, standard 1000)
o.ttimeoutlen = 10                    -- hur länge Neovim väntar efter Esc på en tangentsekvens (ms)

-- Övrigt
o.clipboard = "unnamedplus"           -- använd systemets urklipp (kräver wl-clipboard)
o.undofile = true                     -- spara ångra-historik mellan sessioner
o.swapfile = false                    -- inga .swp-filer
o.updatetime = 250                    -- snabbare uppdatering av CursorHold/diagnostik (ms)
o.mouse = "a"                         -- mus fungerar i alla lägen

-- netrw
vim.g.netrw_banner = 0                -- dölj hjälptexten överst i netrw
vim.g.netrw_liststyle = 3             -- visa filer som ett träd

local map = vim.keymap.set            -- kortnamn för att skapa tangentmappningar
map("n", "<leader>e", vim.cmd.Ex, { desc = "Filutforskare (netrw)" })  -- Space+e öppnar netrw i aktuell mapp
map("n", "<Esc>", "<cmd>nohlsearch<CR>")                               -- Esc tar bort sökmarkering
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Spara" })                -- Space+w sparar
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Stäng" })                -- Space+q stänger fönstret

-- Byt fönster med Ctrl+hjkl
map("n", "<C-h>", "<C-w>h")           -- till fönstret till vänster
map("n", "<C-j>", "<C-w>j")           -- till fönstret nedanför
map("n", "<C-k>", "<C-w>k")           -- till fönstret ovanför
map("n", "<C-l>", "<C-w>l")           -- till fönstret till höger

-- Flytta markerade rader i visual mode
map("v", "J", ":m '>+1<CR>gv=gv")     -- flytta markeringen en rad ned och indentera om
map("v", "K", ":m '<-2<CR>gv=gv")     -- flytta markeringen en rad upp och indentera om

-- Markera kort det du kopierar
vim.api.nvim_create_autocmd("TextYankPost", {   -- körs varje gång du kopierar (yank)
  callback = function() (vim.hl or vim.highlight).on_yank() end,  -- blinkar den kopierade texten kort (vim.hl från 0.11)
})
