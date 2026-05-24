# frozen_string_literal: true

require_relative "lib/two_step/version"

Gem::Specification.new do |spec|
  spec.name = "two_step"
  spec.version = TwoStep::VERSION
  spec.authors = ["Fernand Arioja"]
  spec.email = ["wwwfernand@yahoo.com"]

  spec.summary = "TOTP multi-factor authentication for Rails"
  spec.description = "Plug-in TOTP two-factor authentication (Google Authenticator–compatible) " \
                     "with QR setup, backup codes, and host-app session hooks."
  spec.homepage = "https://github.com/Galaxy-Group-GG/two_step"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["documentation_uri"] = "https://github.com/Galaxy-Group-GG/two_step/README.md"
  spec.metadata["source_code_uri"] = "https://github.com/Galaxy-Group-GG/two_step"
  spec.metadata["bug_tracker_uri"] = "https://github.com/Galaxy-Group-GG/two_step/issues"
  spec.metadata["changelog_uri"] = "https://github.com/Galaxy-Group-GG/two_step/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "railties", "~> 7.1", ">= 7.1.0"
  spec.add_dependency "activerecord", "~> 7.1", ">= 7.1.0"
  spec.add_dependency "actionpack", "~> 7.1", ">= 7.1.0"
  spec.add_dependency "actionview", "~> 7.1", ">= 7.1.0"
  spec.add_dependency "activemodel", "~> 7.1", ">= 7.1.0"
  spec.add_dependency "rotp", "~> 6.3"
  spec.add_dependency "rqrcode", "~> 3.2"
  spec.add_dependency "bcrypt", "~> 3.1"
end
