# frozen-string-literal: true

Gem::Specification.new do |s|
  s.name          = 'himawari'
  s.version       = '0.1.2'
  s.date          = '2020-12-15'
  s.summary       = 'Grabs latest images from the himawari8 weather satellite'
  s.description   = 'Makes pretty, high-res backgrounds from the real-time photos of Earth by Himawari8, ' \
                    'or is intended for similar personal usage. Please see the readme for more!'
  s.authors       = ['engura']
  s.email         = ['engura@gmail.com']
  s.homepage      = 'https://github.com/engura/himawari'
  s.license       = 'MIT'

  s.files         = `git ls-files -- . ':!:*.png'`.split + ['lib/himawari/no_image.png']
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(tests|spec|features)/})
  s.require_paths = ['lib']

  s.metadata = {
    'homepage_uri' => 'https://github.com/engura/himawari',
    'changelog_uri' => 'https://github.com/engura/himawari/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/engura/himawari',
    'bug_tracker_uri' => 'https://github.com/engura/himawari/issues'
  }

  s.required_ruby_version = '>= 2.5'

  s.add_runtime_dependency 'httparty', '~> 0.17.3'

  s.add_development_dependency 'bundler', '~> 2.1.4'
  s.add_development_dependency 'minitest', '~> 5.14.0'
  s.add_development_dependency 'pry', '~> 0.13.1'
  s.add_development_dependency 'rake', '~> 13.0.1'
  s.add_development_dependency 'rubocop', '~> 1.6'

  s.requirements << 'Mac OSX or Linux... Windows `not supported yet` due to the lack of the following:'
  s.requirements << 'parallel, ~>20161222 (Let\'s download in parallel)'
  s.requirements << 'ImageMagick, ~>6.9.10-23 (Specifically, the `montage` utility)'
  s.requirements << 'common utilities: find, touch, crontab, curl, iwgetid, rm, bash'

  s.post_install_message = "Thanks for installing! Have fun with the amazing pics of our Home made\n" \
                           'accessible to us for FREE by NICT. And please, don\'t break their website!!'
end
