require 'nissh/mock_command'
require 'nissh/response'

module Nissh

  class ExecutedUndefinedCommand < StandardError; end

  class MockSession

    attr_reader :executed_commands

    def initialize
      @mocked_commands = {}
      @executed_commands = []
      @written_data = []
      @closed = false
    end

    def command(matcher, &block)
      command = Nissh::MockCommand.new(matcher)
      block.call(command)
      @mocked_commands[matcher] = command
    end

    def execute!(commands, options = {})
      mocked_command, match_data = match_command(commands)
      response = Response.new
      response.stdout = evaluate(mocked_command.stdout || "", match_data)
      response.stderr = evaluate(mocked_command.stderr || "", match_data)
      response.exit_code = evaluate(mocked_command.exit_code || 0, match_data)
      return response
    end

    def execute_with_timeout!(commands, timeout = 30, options = {})
      if timeout.is_a?(Hash)
        options = timeout
        timeout = 30
      end

      mocked_command, _ = match_command(commands)
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
      @closed = true
    end

    def closed?
      @closed == true
    end

    def write_data(path, data, options = {})
      @written_data << [path, data]
      data.bytesize
    end

    private

    def match_command(commands)
      commands = [commands] unless commands.is_a?(Array)
      command = commands.join(' && ')

      for matcher, mocked_command in @mocked_commands
        if (matcher.is_a?(Regexp) ? matcher =~ command : matcher == command)
          @executed_commands << command
          return [mocked_command, $~]
        end
      end

      raise ExecutedUndefinedCommand, "Tried to run '#{command}' but was not defined in mock session"
    end

    def evaluate(block_or_value, matches)
      if block_or_value.is_a?(Proc)
        block_or_value.call(matches)
      else
        block_or_value
      end
    end

  end
end
