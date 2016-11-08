Gem::Specification.new do |s|
  s.name = 'subnet_calc'
  s.version = '0.3.2'
  s.summary = 'A subnet calculator (only tested for class C and class B networks)'
  s.authors = ['James Robertson']
  s.files = Dir['lib/subnet_calc.rb']
  s.add_runtime_dependency('kvx', '~> 0.6', '>=0.6.1')
  s.add_runtime_dependency('table-formatter', '~> 0.4', '>=0.4.0')
  s.signing_key = '../privatekeys/subnet_calc.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/subnet_calc'
end
