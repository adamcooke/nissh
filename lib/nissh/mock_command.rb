module Nissh
  class MockCommand

    attr_accessor :stdout
    attr_accessor :stderr
    attr_accessor :exit_code

    def initialize(command)
      @command = command
    end

    def timeout!
      @timeout = true
    end

    def timeout?
      @timeout == true
    end

  end
end
