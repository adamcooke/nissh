require 'timeout'
require 'net/ssh'
require 'net/sftp'
require 'nissh/response'

module Nissh
  class Session

    class CommandExecutionFailed < StandardError; end

    class << self
      attr_accessor :logger
    end

    attr_reader :session
    attr_accessor :sudo_password

    def initialize(*args)
      if args.first.is_a?(Net::SSH::Connection::Session)
        @session = args.first
      else
        @session = Net::SSH.start(*args)
      end
    end

    def close
      @session.close rescue nil
    end

    def execute!(commands, options = {})
      unless commands.is_a?(Array)
        commands = [commands]
      end

      if options[:sudo]
        commands = commands.map do |command|
          "sudo --stdin #{command}"
        end
      end

      command = commands.join(' && ')
      log :info, "\e[44;37m=> #{command}\e[0m"

      response = Nissh::Response.new
      response.command = command
      channel = @session.open_channel do |channel|
        channel.exec(command) do |_, success|
          raise CommandExecutionFailed, "Command \"#{command}\" was unable to execute" unless success
          channel.on_data do |_,data|
            response.stdout += data
            log :debug, data.gsub(/[\r]/, ''), :tab => 4
          end

          channel.on_extended_data do |_,_,data|
            response.stderr += data.gsub(/\r/, '')
            log :warn, data, :tab => 4
            if data =~ /^\[sudo\] password for/
              password = options[:sudo].is_a?(String) ? options[:sudo] : self.sudo_password
              channel.send_data "#{password}\n"
            end
          end

          channel.on_request("exit-status") do |_,data|
            response.exit_code = data.read_long
            log :info, "\e[43;37m=> Exit status: #{response.exit_code}\e[0m"
          end

          channel.on_request("exit-signal") do |_, data|
            response.exit_signal = data.read_long
          end
        end
      end
      channel.wait
      response
    end

    def execute_with_timeout!(command, timeout = 30, options = {})
      if timeout.is_a?(Hash)
        options = timeout
        timeout = 30
      end

      Timeout.timeout(timeout) do
        execute!(command, options)
      end
    rescue Timeout::Error => e
      response = Nissh::Response.new
      response.exit_code = -255
      response.stderr = "Command did not finish executing within the allowed #{timeout} seconds."
      response.command = command
      response
    end

    def execute_with_success!(command, success_code = 0, options = {})
      if success_code.is_a?(Hash)
        options = success_code
        success_code = 0
      end

      result = execute!(command, options)
      if result.exit_code == success_code
        result
      else
        false
      end
    end

    def execute_with_exception!(command, success_code = 0, options = {})
      if success_code.is_a?(Hash)
        options = success_code
        success_code = 0
      end

      result = execute!(command, options)
      if result.exit_code == success_code
        result
      else
        raise CommandExecutionFailed, result.output
      end
    end

    def write_data(path, data)
      @session.sftp.file.open(path, 'w') { |f| f.write(data) }
    end

    private

    def log(type, text, options = {})
      if self.class.logger
        prefix = "\e[45;37m[#{@session.transport.host}]\e[0m"
        tabs = " " * (options[:tab] || 0)
        text.split(/\n/).each do |line|
          self.class.logger.send(type,  prefix + tabs + line)
        end
      end
    end

  end
end
