# typed: strict
# frozen_string_literal: true

require "json"
require "formulary"
require "tap"

TAP = "superradcompany/tap"
FORMULA_NAME = "microsandbox"
FORMULA_PATH = "Formula/microsandbox.rb"

supported_platform = OS.mac? && Hardware::CPU.arm?
abort "Formula API metadata must be generated on Apple Silicon macOS" unless supported_platform

root = Pathname(__dir__).parent.expand_path
formula_path = root.join(FORMULA_PATH)
formula = Formulary.from_contents(
  FORMULA_NAME,
  formula_path,
  formula_path.read,
  tap: Tap.fetch(TAP),
)

metadata = formula.to_hash
metadata["ruby_source_path"] = FORMULA_PATH
metadata["tap_git_head"] = "HEAD"

stable_url = metadata.dig("urls", "stable", "url")
unless stable_url&.end_with?("microsandbox-darwin-aarch64.tar.gz")
  abort "Expected Apple Silicon archive, got #{stable_url.inspect}"
end

output_path = root.join("api/formula/microsandbox.json")
output_path.dirname.mkpath
output_path.write("#{JSON.pretty_generate(metadata)}\n")

puts "Generated #{output_path.relative_path_from(root)}"
