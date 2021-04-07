expand :clean, paths: :gitignore

expand :minitest do |t|
  t.libs = ["lib", "test"]
  t.use_bundler
end

expand :minitest do |t|
  t.name = "integration"
  t.libs = ["lib", "test"]
  t.files = "test/**/integration_*.rb"
  t.use_bundler
end

expand :rubocop, bundler: true

$LOAD_PATH.unshift(File.join(File.dirname(__dir__), "lib"))
