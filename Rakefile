desc "Run tests"
task "test" do
  $:.unshift("lib")
  require("test/hash_tree_test")
  require("test/squeeze_test")
end

task "build" do
  sh "gem build ./squeeze.gemspec"
end

task "clean" do
  FileList["squeeze-*.gem"].each do |file|
    rm file
  end
end

