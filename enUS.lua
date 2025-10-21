-- enUS.lua
-- UTF-8, UNIX newlines
-- Baseline locale. Exists at addon root to avoid path mismatches.

GnerdHUD_L = {
  ADDON_NAME = "GnerdHUD",
  CMD_HELP_HEADER = "GnerdHUD commands:",
  CMD_HELP_1 = "/ghud help - Show this help",
  CMD_HELP_2 = "/ghud options - Open options",
  CMD_HELP_3 = "/ghud lock - Lock frames",
  CMD_HELP_4 = "/ghud unlock - Unlock frames",
  CMD_HELP_5 = "/ghud diag - Print state",
  CMD_HELP_6 = "/ghud rebuild - Recreate layout",
  PRINT_PREFIX = "|cFF55CCFFGnerdHUD:|r ",
  OPTS_TITLE = "GnerdHUD Options",
  OPTS_LOCK = "Locked",
  OPTS_SCALE = "Scale",
  OPTS_ALPHA_IDLE = "Alpha: Idle",
  OPTS_ALPHA_COMBAT = "Alpha: In Combat",
  OPTS_ALPHA_TARGET = "Alpha: Has Target",
  STATE_LOCKED = "Locked",
  STATE_UNLOCKED = "Unlocked",
  STATE_REBUILT = "Layout rebuilt.",
  STATE_APPLIED = "Settings applied.",
  DIAG_SCHEMA = "Schema=%s Segments=%d Scale=%.2f Locked=%s",
  DIAG_POS = "LeftHUD x=%d y=%d  RightHUD x=%d y=%d",
  DIAG_ALPHA = "Alpha idle=%.2f combat=%.2f target=%.2f",
}
