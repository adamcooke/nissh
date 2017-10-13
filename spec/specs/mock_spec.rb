require 'spec_helper'
require 'nissh/mock_session'
require 'nissh/session'

describe Nissh::MockSession do

  subject(:session) { Nissh::MockSession.new }

  context "an empty session" do
    it "should raise an error when running a command without a resolution" do
      expect { session.execute!("hostname") }.to raise_exception(Nissh::ExecutedUndefinedCommand)
    end
  end

  context "execute!" do
    it "should return the defined stdout" do
      session.command("hostname") do |c|
        c.stdout = "myhostname\n"
      end
      response = session.execute!("hostname")
      expect(response.stdout).to eq("myhostname\n")
    end

    it "should return the defined stderr" do
      session.command("hostname") do |c|
        c.stdout = "myhostname\n"
        c.stderr = "error\n"
      end
      response = session.execute!("hostname")
      expect(response.stderr).to eq("error\n")
    end

    it "should return the defined exit code" do
      session.command("hostname") do |c|
        c.exit_code = 50
      end
      response = session.execute!("hostname")
      expect(response.exit_code).to eq(50)
    end

    it "should evaluate blocks for stdout" do
      session.command(/\Aapt install (\w+)/) do |c|
        c.stdout do |matches|
          "Installed #{matches[1]} successfully"
        end
      end

      response = session.execute!("apt install nginx")
      expect(response.stdout).to eq "Installed nginx successfully"

      response = session.execute!("apt install varnish")
      expect(response.stdout).to eq "Installed varnish successfully"
    end

    it "should evaluate blocks for stderr" do
      session.command(/\Aapt install (\w+)/) do |c|
        c.stderr do |matches|
          "Failed to install #{matches[1]}"
        end
      end

      response = session.execute!("apt install nginx")
      expect(response.stderr).to eq "Failed to install nginx"

      response = session.execute!("apt install apache")
      expect(response.stderr).to eq "Failed to install apache"
    end

    it "should evaluate blocks for exit code" do
      session.command(/\Aapt install (\w+)/) do |c|
        c.exit_code do |matches|
          matches[1] == "nginx" ? 0 : 100
        end
      end

      response = session.execute!("apt install nginx")
      expect(response.exit_code).to eq 0

      response = session.execute!("apt install apache")
      expect(response.exit_code).to eq 100
    end
  end

  context "execute_with_timeout!" do
    it "should return a timeout response" do
      session.command("hostname") do |c|
        c.timeout = 35
      end
      response = session.execute_with_timeout!("hostname", 10)
      expect(response.exit_code).to eq(-255)
    end

    it "should behave normally when no timeout is needed" do
      session.command("hostname") do |c|
        c.stdout = "blah\n"
        c.timeout = 5
      end
      response = session.execute_with_timeout!("hostname", 10)
      expect(response.exit_code).to eq(0)
    end
  end

  context "execute_with_success!" do
    it "should return a response when successful" do
      session.command("hostname") do |c|
        c.exit_code = 0
      end
      response = session.execute_with_success!("hostname")
      expect(response).to be_a(Nissh::Response)
    end

    it "should return false when unsuccessful" do
      session.command("hostname") do |c|
        c.exit_code = 50
      end
      response = session.execute_with_success!("hostname")
      expect(response).to be(false)
    end
  end

  context "execute_with_exception!" do
    it "should return a response when successful" do
      session.command("hostname") do |c|
        c.exit_code = 0
      end
      response = session.execute_with_exception!("hostname")
      expect(response).to be_a(Nissh::Response)
    end

    it "should return false when unsuccessful" do
      session.command("hostname") do |c|
        c.exit_code = 50
      end
      expect { session.execute_with_exception!("hostname") }.to raise_exception(Nissh::Session::CommandExecutionFailed)
    end
  end

end
