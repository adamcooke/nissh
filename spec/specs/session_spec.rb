require 'spec_helper'
require 'nissh/session'

if ENV['IP'].nil? || ENV['USER'].nil?
  $stderr.puts "\e[31mNo IP and USER environment variables provided. Cannot test a real connection.\e[0m"
else
  describe Nissh::Session do

    before(:all) do
      @session = Nissh::Session.new(ENV['IP'], ENV['USER'])
    end

    it "should connect" do
      expect(@session).to be_a Nissh::Session
    end

    context "#execute!" do
      it "should return an session response" do
        expect(@session.execute!("whoami")).to be_a(Nissh::Response)
      end
    end

    context "#execute_with_timeout!" do
      it "should timeout" do
        response = @session.execute_with_timeout!("sleep 3", 1)
        expect(response).to be_a(Nissh::Response)
        expect(response.exit_code).to eq -255
      end
    end

    context "#execute_with_success!" do
      it "should return false on error" do
        response = @session.execute_with_success!("exit 1")
        expect(response).to be false
      end
    end

    context "#execute_with_exception!" do
      it "should raise an exception on error" do
        expect do
          @session.execute_with_exception!("exit 1")
        end.to raise_error(Nissh::Session::CommandExecutionFailed)
      end
    end


  end
end
