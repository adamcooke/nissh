module Nissh
  class Response

    attr_accessor :stdout, :stderr, :exit_code, :exit_signal, :command

    def initialize
      reset_output!
    end

    def success?
      exit_code == 0
    end

    def output
      "#{stdout}\n#{stderr}"
    end

    def reset_output!
      @stdout = ""
      @stderr = ""
    end

  end
end
