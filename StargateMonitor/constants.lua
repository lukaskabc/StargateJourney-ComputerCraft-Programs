MONITOR_CONFIG_FILE = shell.resolve("./config/monitor_config.json")
MODULES_CONFIG_FILE = shell.resolve("./config/modules_config.json")
MODULES_FOLDER = "modules" -- dont touch that (used in require which does not really works with paths)
-- dialing milkyway stargate will use three step symbol encoding (open, encode, close)
THREE_STEP_ENCODE = true
-- delay used between encode steps with milkyway gate
CHEVRON_ENCODE_DELAY = 0.5