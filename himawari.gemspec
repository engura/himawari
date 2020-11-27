Gem::Specification.new do |s|
  s.name          = 'himawari'
  s.version       = '1.0.0'
  s.date          = '2020-11-28'
  s.summary       = 'Grabs latest images from the himawari8 weather satellite'
  s.description   = 'Makes pretty, high-res backgrounds from the real-time photos of Earth by Himawari8,' \
                    'or is intended for similar personal usage. Please see the readme for more!'
  s.authors       = ['engura']
  s.email         = ['engura@gmail.com']
  s.homepage      = 'https://github.com/engura/himawari'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(tests|spec|features)/})
  s.require_paths = ['lib']
end
