require 'nissh/mock_command'
require 'nissh/response'

module Nissh

  class ExecutedUndefinedCommand < StandardError; end

  class MockSession

    attr_reader :executed_commands

    def initialize
      @mocked_commands = {}
      @executed_commands = []
    end

    def command(matcher, &block)
      command = Nissh::MockCommand.new(matcher)
      block.call(command)
      @mocked_commands[matcher] = command
    end

    def execute!(commands, options = {})
      mocked_command = match_command(commands)
      response = Response.new
      response.stdout = mocked_command.stdout || ""
      response.stderr = mocked_command.stderr || ""
      response.exit_code = mocked_command.exit_code || 0
      return response
    end

    def execute_with_timeout!(commands, timeout = 30, options = {})
      if timeout.is_a?(Hash)
        options = timeout
        timeout = 30
      end

      mocked_command = match_command(commands)
      if mocked_command.timeout && mocked_command.timeout > timeout
        response = Response.new
        response.exit_code = -255
        response.stderr = "Command did not finish executing within the allowed #{timeout} seconds."
        response
      else
        execute!(commands)
      end
    end

    def execute_with_success!(commands, success_code = 0, options = {})
      if success_code.is_a?(Hash)
        options = success_code
        success_code = 0
      end

      response = execute!(commands)
      if response.exit_code == success_code
        response
      else
        false
      end
    end

    def execute_with_exception!(commands, success_code = 0, options = {})
      if success_code.is_a?(Hash)
        options = success_code
        success_code = 0
      end

      response = execute!(commands)
      if response.exit_code == success_code
        response
      else
        raise Session::CommandExecutionFailed, response.output
      end
    end

    def close
    end

    private

    def match_command(commands)
      commands = [commands] unless commands.is_a?(Array)
      command = commands.join(' && ')

      for matcher, mocked_command in @mocked_commands
        if (matcher.is_a?(Regexp) ? matcher =~ command : matcher == command)
          @executed_commands << command
          return mocked_command
        end
      end

      raise ExecutedUndefinedCommand, "Tried to run '#{command}' but was not defined in mock session"
    end

  end
end
