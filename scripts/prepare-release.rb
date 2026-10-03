#!/usr/bin/env ruby
# Verify a signed, stapled release locally. Never publishes or changes system settings.
require 'digest'
require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative 'release-metadata'

def capture!(*args)
  output, status = Open3.capture2e(*args)
  abort output unless status.success?
  output.strip
end

abort 'Usage: ruby scripts/prepare-release.rb archive.zip' unless ARGV.length == 1
root = File.expand_path('..', __dir__)
version = capture!('/usr/libexec/PlistBuddy', '-c', 'Print :CFBundleShortVersionString', "#{root}/Info.plist")
metadata = ReleaseMetadata.new(version)
archive = File.expand_path(ARGV[0])
abort 'Missing release archive' unless File.file?(archive)
abort "Release asset must be named #{metadata.filename}" unless File.basename(archive) == metadata.filename
requirement = '=identifier "kr.twentyoz.gkdl" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists and certificate leaf[field.1.2.840.113635.100.6.1.13] exists and certificate leaf[subject.OU] = "KTC97BHY7R"'

Dir.mktmpdir('gkdl-release-') do |stage|
  ReleaseArchive.validate_listing!(capture!('/usr/bin/unzip', '-Z1', archive), capture!('/usr/bin/unzip', '-Z', '-l', archive))
  capture!('/usr/bin/ditto', '-x', '-k', archive, stage)
  app = "#{stage}/gkdl.app"
  %w[LICENSE NOTICE].each do |name|
    bundled = "#{app}/Contents/Resources/#{name}"
    abort "Archive must include the current #{name}" unless File.file?(bundled) && File.binread(bundled) == File.binread("#{root}/#{name}")
  end
  capture!('/usr/bin/codesign', '--verify', '--deep', '--strict', '--all-architectures', '-R', requirement, app)
  %w[CFBundleShortVersionString CFBundleVersion CFBundleIdentifier CFBundleExecutable].each do |key|
    expected = capture!('/usr/libexec/PlistBuddy', '-c', "Print :#{key}", "#{root}/Info.plist")
    actual = capture!('/usr/libexec/PlistBuddy', '-c', "Print :#{key}", "#{app}/Contents/Info.plist")
    abort "Archive #{key} does not match source" unless expected == actual
  end
  arches = capture!('/usr/bin/lipo', '-archs', "#{app}/Contents/MacOS/gkdl").split
  abort 'Expected arm64 + x86_64' unless arches.sort == %w[arm64 x86_64]
  signature = capture!('/usr/bin/codesign', '-d', '--verbose=4', app)
  abort 'Secure timestamp and hardened runtime required' unless signature.match?(/^Timestamp=/) && signature.match?(/flags=.*\(runtime\)/)
  capture!('/usr/bin/xcrun', 'stapler', 'validate', app)
  capture!('/usr/sbin/spctl', '--assess', '--type', 'execute', '--verbose=2', app)
end

checksum = "#{Digest::SHA256.file(archive).hexdigest}  #{metadata.filename}\n"
sums = File.join(File.dirname(archive), 'SHA256SUMS')
abort 'SHA256SUMS does not match the verified archive' unless File.file?(sums) && File.read(sums) == checksum
puts "Verified: #{metadata.filename} (TWENTYOZ Developer ID, Universal, notarization ticket, Gatekeeper, SHA256)"
