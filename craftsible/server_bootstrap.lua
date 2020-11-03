ORG = "zyuiop"
REPO = "CCPrograms"
BRANCH = "master"
FILE = "craftsible/server.lua"

url = "https://raw.githubusercontent.com/" .. ORG .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE

path = shell.getRunningProgram() .. ".running"
fs.delete(path)
shell.run("wget", url, path)
shell.run(path)