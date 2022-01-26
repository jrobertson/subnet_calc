Gem::Specification.new do |s|
  s.name = 'subnet_calc'
  s.version = '0.3.4'
  s.summary = 'A subnet calculator (only tested for class C and class B networks)'
  s.authors = ['James Robertson']
  s.files = Dir['lib/subnet_calc.rb']
  s.add_runtime_dependency('kvx', '~> 1.0', '>=1.0.1')
  s.add_runtime_dependency('table-formatter', '~> 0.4', '>=0.4.0')
  s.signing_key = '../privatekeys/subnet_calc.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/subnet_calc'
end
