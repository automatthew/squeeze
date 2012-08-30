Gem::Specification.new do |s|
  s.name = "squeeze"
  s.version = "0.1.0"
  s.authors = ["Matthew King"]
  s.homepage = "https://github.com/automatthew/squeeze"
  s.summary = "Tools for working with nested data structures in Ruby"

  s.files = %w[
    LICENSE
    README.md
    lib/squeeze/hash_tree.rb
    lib/squeeze/traversable.rb
    lib/squeeze/matcher.rb
    lib/squeeze.rb
  ]
  s.require_path = "lib"

  #s.add_dependency("consolize", ">=0.2.0")
  s.add_development_dependency("riot", ">=0.12.5")
end


