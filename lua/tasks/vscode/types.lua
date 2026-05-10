--- @alias command string | string[]
--- @alias env table<string, string>

--- @class vscode.TaskOptions vscode task options
--- @field env? env map of env variable name to value that will exist for the task
--- @field cwd? string working directory for the task to run in

--- @class vscode.TaskConfig vscode task
--- @field label? string unique name for a task
--- @field type? "shell" | "process" | "npm" is the task a shell command or a process or other
--- @field command? string command to run
--- @field args? string[] args to pass to the command
--- @field options? vscode.TaskOptions extra task options
--- @field group? string | vscode.Group group info
--- @field script? string script for npm tasks

--- @class vscode.Group task group info
--- @field kind string group name
--- @field isDefault boolean if the task is the default for the group

--- @class vscode.PickOption pick option
--- @field label? string display label
--- @field value? string actual value

--- @class vscode.UserInput vscode task input
--- @field id? string unique id for input
--- @field type? "promptString" | "pickString" | "command" input type
--- @field description? string prompt to show for the input
--- @field default? string default value for the input
--- @field options? (string | vscode.PickOption)[] options for pickString
--- @field password? boolean whether to mask input for promptString
--- @field command? string command to run for command type input
--- @field args? string[] optional args for command input

--- @class vscode.LaunchConfig vscode launch config
--- @field name? string unique name for launch config
--- @field type? "node" | "python" | "debugpy" | "cppdbg" | "extensionHost" type of config
--- @field request? "launch" | "attach" request type of config
--- @field program? string absolute path to the program
--- @field runtimeExecutable? string absolute path to the program
--- @field args? string[] args to pass to the command
--- @field preLaunchTask? string config id to run first
--- @field cwd? string working directory for the config to run in
--- @field env? env map of env variable name to value that will exist for the config
--- @field console? "internalConsole" | "integratedTerminal" | "externalTerminal" where to launch the debug target

--- @class vscode.TasksJson tasks.json file schema
--- @field version? string schema version
--- @field tasks? vscode.TaskConfig[] list of task configs
--- @field inputs? vscode.UserInput[] list of inputs

--- @class vscode.LaunchJson launch.json file schema
--- @field version? string version of schema
--- @field configurations? vscode.LaunchConfig[] list of launch configs
--- @field inputs? vscode.UserInput[] list of inputs
