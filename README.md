# tasks.nvim

Task runner for neovim, supporting multiple task providers.

## Usage

Example usage for `lazy.nvim`.

```lua
return {
	"twhlynch/tasks.nvim",
	opts = {
		-- run command on current line
		keybind = "<leader><CR>",
		-- pick through workspace commands
		keybind_picker = "<leader>B",
		-- runnable line icon
		sign_icon = "▶",
		sign_hl = "DiagnosticFloatingOk",
		-- task providers to include
		providers = { "vscode", "npm", "make" },
		-- how to run tasks
		-- "floating", "split", "vsplit", "background"
		-- or a custom function `func(cmd: string)`
		runner = "floating",
	},
}
```

## Runner recipes

<details><summary>Run in a new tmux window</summary>

```lua
runner = function(cmd)
	vim.fn.system({
		"tmux",
		"new-window",
		"-d",
		"$SHELL -i -c " .. vim.fn.shellescape(cmd .. "; echo; read"),
	})
end,
```

</details>
