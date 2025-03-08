## clee.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "clee"
  spec.version = "0.4.2"
  spec.required_ruby_version = '>= 3.0'
  spec.platform = Gem::Platform::RUBY
  spec.summary = "clee #FIXME"
  spec.description = "clee #FIXME..."
  spec.license = "LicenseRef-LICENSE.md"

  spec.files =
["LICENSE.md",
 "README.md",
 "Rakefile",
 "TODO.md",
 "a.rb",
 "bin",
 "bin/clee",
 "clee.gemspec",
 "docs",
 "docs/sunwukong.md",
 "lib",
 "lib/clee",
 "lib/clee.rb",
 "lib/clee/_lib.rb",
 "test"]

  spec.executables = ["clee"]
  
  spec.require_path = "lib"

  

  spec.extensions.push(*[])

  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/clee"
end
