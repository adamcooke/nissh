# Nissh

A wrapper for `net/ssh` to make running commands and getting the data you need nicer.

## Installation

As always, just add Nissh to your Gemfile and run `bundle install`.

```ruby
gem 'nissh'
```

## Usage

Nissh is designed to be very easy to use and get started with.

### Connecting

To start a session, just create an object using the same properties that you would
pass to a `Net::SSH.start` method.

```ruby
session = Nissh::Session.new('185.22.208.5', 'root')
```

### Running a simple command

Run a command using the `execute!` method which will return an object containing
the response. This method will run in the foreground so the call will block until
the server finishes.

```ruby
result = ssh.execute!("hostname")
result.success?     # => Was the command successfully executed?
result.exit_code    # => Exit code
result.stdout       # => Full contents of stdout
result.stderr       # => Full contents of stderr
```

### Logging

If you want to log all commands which are executed to a file, you can do this by
just setting a logger for all sessions. Once enabled, it will log all commands
which are run along with their full output, exit code and the server they were
executed on. This is likely only required in development.

```ruby
Nissh::Session.logger = Logger.new("ssh.log")
```

### Sudo Passwords

If the user you are authenticating with needs to run a `sudo` command and provide
a password, Nissh can help. Just pass the `:sudo` option when calling execute.
You do not need to add the `sudo` keyword before your command.

```ruby
# Just provide the password as an option when running your command
session.execute!("cat /etc/passwd", :sudo => "yourpassword")

# Alternative, you can provide it to the session and just pass true.
session.sudo_password = "yourpassword"
session.execute!("cat /etc/passwd", :sudo => true)
```

### Timing out

If you want to only wait a specific length of time for a command to complete, you
can use the `execute_with_timeout` method.

```ruby
result = session.execute_with_timeout!("something-slow", 5)
result.success?     # => false
result.exit_code    # => -255
```

## Events & Callbacks

You can register events with any sessions which will be executed at appropriate
times. You can register events with the session using the `will` and `did` method
that are available.

The following events are available:

* `connect` - called before and after connection
* `close` - called before and after the connection is closed
* `execute` - called before and after a command is executed
* `write_file` - called before and after a file is written

```ruby
session.will :execute do |command|
  puts "About to execute '#{command}'"
end

session.did :execute do |response|
  puts "Got #{response.exit_code} back from command."
end
```

## Usage in tests

Nissh provides a mocked session which can be used when testing commands to external servers.
You can pre-create a session object with the responses you wish to provide when
commands are executed.

```ruby
mocked_session = Nissh::MockedSession.new

# Specifies that whenever the hostname command is executed, it should return "myhostname"
mocked_session.command "hostname" do |c|
  c.stdout = "myhostname\n"
end

mocked_session.execute!("hostname").stdout    #=> "myhostname\n"

# You can also use regex in the command name and provide blocks to execute rather than
# literal values for stdout, stderr and exit_code.
mocked_session.command /\Aapt install (\w+)" do |c|
  c.stdout do |matches|
    "Installed package #{matches[0]}"
  end
end
```

