require_relative "emulator_util"

# stick with ENV defaults
EmulatorUtil.logger = Logger.new("/dev/null")
EmulatorUtil.release_all_emulator_sessions!
