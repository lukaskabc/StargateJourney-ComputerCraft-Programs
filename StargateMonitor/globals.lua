MONITOR_CONFIG_FILE = shell.resolve("./config/monitor_config.json")
MODULES_CONFIG_FILE = shell.resolve("./config/modules_config.cnf")
MODULES_CONFIG_FILE_backup = shell.resolve("./config/modules_config_backup.cnf")
MODULES_FOLDER = "modules" -- dont touch that (used in require which does not really works with paths)
-- dialing milkyway stargate will use three step symbol encoding (open, encode, close)
THREE_STEP_ENCODE = true
-- will skip delays in dialing sequence (if possible)
QUICK_DIAL = true
-- allow skipping milkyway gate rotation when possible
DIRECT_ENGAGE = true
-- delay used between encode steps with milkyway gate
CHEVRON_ENCODE_DELAY = 0.5
-- how long will alerts (in cartouche/history) stay on screen
ALERT_TIMEOUT = 5 -- seconds
-- if true, script wont comply about grayscale monitors
ALLOW_NON_ADVANCED_MONITORS = false