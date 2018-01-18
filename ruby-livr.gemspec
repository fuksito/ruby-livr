Gem::Specification.new do |gem|
  gem.name        = "ruby-livr"
  gem.version     = "2.0.0"
  gem.date        = "2017-12-22"
  gem.summary     = "Implementation of LIVR v2.0"
  gem.description = "Language Independent Validation Rules. Implements 2.0 specification"
  gem.authors     = ["Vitaliy Yanchuk"]
  gem.email       = 'fuksito@gmail.com'
  gem.homepage    = "https://github.com/fuksito/ruby-livr"
  gem.license     = "MIT"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency "activesupport", '~> 5'
  gem.add_development_dependency "rspec", "3.7"
end