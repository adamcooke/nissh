require File.expand_path('../lib/nissh/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = "nissh"
  s.description   = %q{A wrapper for net/ssh to make running commands more fun}
  s.summary       = s.description
  s.homepage      = "https://github.com/adamcooke/nissh"
  s.version       = Nissh::VERSION
  s.files         = Dir.glob("{lib}/**/*")
  s.require_paths = ["lib"]
  s.authors       = ["Adam Cooke"]
  s.email         = ["me@adamcooke.io"]
  s.licenses      = ['MIT']
  s.add_dependency "net-ssh", ">= 2"
  s.add_dependency "net-sftp", ">= 2"
end
