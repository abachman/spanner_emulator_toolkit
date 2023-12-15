require_relative "emulator_util"

# stick with ENV defaults
EmulatorUtil.logger = Logger.new("/dev/null")
EmulatorUtil.reset_all_emulator_transactions!
