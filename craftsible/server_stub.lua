ORG = "zyuiop"
REPO = "CCPrograms"
BRANCH = "master"
FILE = "craftsible/server.lua"

url = "https://raw.githubusercontent.com/" .. ORG .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE

path = shell.getRunningProgram()
fs.delete(path)
shell.run("wget", url, path)