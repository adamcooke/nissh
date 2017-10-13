module Nissh
  class MockCommand

    attr_accessor :stdout
    attr_accessor :stderr
    attr_accessor :exit_code
    attr_accessor :timeout

    def initialize(command)
      @command = command
    end

  end
end
