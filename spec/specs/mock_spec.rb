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
  end

  context "execute_with_timeout!" do
    it "should return a timeout response" do
      session.command("hostname") do |c|
        c.timeout!
      end
      response = session.execute_with_timeout!("hostname", 10)
      expect(response.exit_code).to eq(-255)
    end

    it "should behave normally when no timeout is needed" do
      session.command("hostname") do |c|
        c.stdout = "blah\n"
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
