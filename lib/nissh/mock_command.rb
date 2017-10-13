module Nissh
  class MockCommand

    attr_accessor :stdout
    attr_accessor :stderr
    attr_accessor :exit_code
    attr_accessor :timeout

    def initialize(command)
      @command = command
    end

    def stdout(&block)
      if block_given?
        @stdout = block
      else
        @stdout
      end
    end

    def stderr(&block)
      if block_given?
        @stderr = block
      else
        @stderr
      end
    end

    def exit_code(&block)
      if block_given?
        @exit_code = block
      else
        @exit_code
      end
    end

  end
end
