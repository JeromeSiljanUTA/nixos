-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{
			"ellisonleao/gruvbox.nvim",
			priority = 1000,
			config = function()
				vim.cmd.colorscheme("gruvbox")
			end,
		},
		{
			"folke/zen-mode.nvim",
		},
		{
			"neovim/nvim-lspconfig",
		},
		{
			"junegunn/fzf.vim",
			build = "./install --bin",
		},
		{
			"junegunn/fzf.vim",
			dependencies = { "junegunn/fzf" },
		},
		{
			"mfussenegger/nvim-lint",
			config = function()
				require("lint").linters_by_ft = {
					javascript = { "eslint_d" },
					typescript = { "eslint_d" },
					javascriptreact = { "eslint_d" },
					typescriptreact = { "eslint_d" },
					python = { "flake8" },
					go = { "golangcilint" },
				}

				vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
					callback = function()
						require("lint").try_lint()
					end,
				})
			end,
		},
		{
			"stevearc/conform.nvim",
			config = function()
				require("conform").setup({
					formatters_by_ft = {
						javascript = { "prettierd", "prettier" },
						typescript = { "prettierd", "prettier" },
						javascriptreact = { "prettierd", "prettier" },
						typescriptreact = { "prettierd", "prettier" },
						json = { "prettierd", "prettier" },
						css = { "prettierd", "prettier" },
						html = { "prettierd", "prettier" },
						python = { "black", "isort" },
						go = { "goimports", "gofmt" },
						lua = { "stylua" },
					},
				})

				vim.api.nvim_create_autocmd("BufWritePre", {
					pattern = "*",
					callback = function(args)
						require("conform").format({ bufnr = args.buf, lsp_fallback = true })
					end,
				})
			end,
		},
		{
			"ojroques/nvim-osc52",
			config = function()
				local osc52 = require("osc52")

				osc52.setup({
					max_length = 0,
					silent = false,
					trim = false,
				})

				vim.api.nvim_create_autocmd("TextYankPost", {
					callback = function()
						if vim.v.event.operator == "y" then
							osc52.copy_register(vim.v.event.regname)
						end
					end,
				})
			end,
		},
		{
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			keys = {
				{ "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
			},
		},
	},
	checker = {
		enabled = true,
	},
})

vim.opt.relativenumber = true
vim.opt.number = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.shell = "bash"
vim.opt.shellcmdflag = "-i -c"

vim.api.nvim_set_keymap("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>b", ":Buffers<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>f", ":Files<CR>", { noremap = true, silent = true })

vim.lsp.enable("pyright")
vim.lsp.enable("ts_ls")
vim.lsp.enable("gopls")

vim.api.nvim_create_user_command("ProjectInit", function()
	local cwd = vim.fn.getcwd()
	local project_file = cwd .. "/.project.lua"

	if vim.fn.filereadable(project_file) == 1 then
		dofile(project_file)
	else
		print("No .project.lua found")
	end
end, {})
