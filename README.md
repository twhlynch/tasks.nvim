# tasks.nvim

Task runner for neovim, supporting `vscode` and `npm` task providers.

## Usage

Example usage for `lazy.nvim`.

```lua
return {
	"twhlynch/tasks.nvim",
	opts = {
		keybind = "<leader><CR>",
		sign_icon = "▶",
		sign_hl = "DiagnosticFloatingOk",
		providers = { "vscode", "npm" },
	},
}
```
