#!/usr/bin/env ruby
# Verify a signed, stapled release locally. Never publishes or changes system settings.
# DMG verification adapted from gksdud and modified for gkdl; see LICENSE (Apache-2.0).
require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'
require_relative 'release-metadata'

def capture!(*args)
  output, status = Open3.capture2e(*args)
  abort output unless status.success?
  output.strip
end

abort 'Usage: ruby scripts/prepare-release.rb archive.zip [installer.dmg]' unless ARGV.length.between?(1, 2)
root = File.expand_path('..', __dir__)
version = capture!('/usr/libexec/PlistBuddy', '-c', 'Print :CFBundleShortVersionString', "#{root}/Info.plist")
metadata = ReleaseMetadata.new(version)
archive = File.expand_path(ARGV[0])
abort 'Missing release archive' unless File.file?(archive)
abort "Release asset must be named #{metadata.filename}" unless File.basename(archive) == metadata.filename
requirement = '=identifier "com.zzune.gkdl" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] exists and certificate leaf[field.1.2.840.113635.100.6.1.13] exists and certificate leaf[subject.OU] = "KTC97BHY7R"'
code_hashes = lambda do |app|
  %w[arm64 x86_64].map do |arch|
    capture!('/usr/bin/codesign', '-d', '--verbose=4', '--arch', arch, app)[/^CDHash=(\h+)$/, 1] or abort 'No CDHash'
  end
end
archive_hashes = nil
verify_beta = lambda do |app|
  helper = "#{app}/Contents/PlugIns/하이 Beta 입력기.app"
  if metadata.channel == 'canary'
    abort 'Canary build marker missing' unless capture!('/usr/libexec/PlistBuddy', '-c', 'Print :GKDLChannel', "#{app}/Contents/Info.plist") == 'canary'
    helper_requirement = requirement.sub('"com.zzune.gkdl"', '"com.zzune.gkdl.beta.inputmethod"')
    capture!('/usr/bin/codesign', '--verify', '--strict', '--all-architectures', '-R', helper_requirement, helper)
    %w[CFBundleShortVersionString CFBundleVersion].each do |key|
      abort "Input method #{key} differs from parent" unless
        capture!('/usr/libexec/PlistBuddy', '-c', "Print :#{key}", "#{helper}/Contents/Info.plist") ==
        capture!('/usr/libexec/PlistBuddy', '-c', "Print :#{key}", "#{app}/Contents/Info.plist")
    end
    abort 'Expected Universal input method' unless capture!('/usr/bin/lipo', '-archs', "#{helper}/Contents/MacOS/HiBetaInput").split.sort == %w[arm64 x86_64]
    signature = capture!('/usr/bin/codesign', '-d', '--verbose=4', helper)
    abort 'Input method needs timestamp and hardened runtime' unless signature.match?(/^Timestamp=/) && signature.match?(/flags=.*\(runtime\)/)
    capture!('/usr/bin/xcrun', 'stapler', 'validate', helper)
    capture!('/usr/sbin/spctl', '--assess', '--type', 'execute', '--verbose=2', helper)
    upstream = "#{root}/ThirdParty/Araso"
    notices = ["#{upstream}/NOTICE.txt", "#{upstream}/LICENSE", *Dir["#{upstream}/Notices/*"].sort].map { |path| File.binread(path) }.join
    [app, helper].each do |bundle|
      abort 'Araso license notices differ from source' unless File.binread("#{bundle}/Contents/Resources/ThirdPartyNotices.txt") == notices
    end
    JSON.parse(File.read("#{upstream}/UPSTREAM.json")).fetch('files').each do |name, info|
      next unless name.start_with?('Data/')
      abort "Araso data differs: #{name}" unless Digest::SHA256.file("#{helper}/Contents/Resources/#{File.basename(name)}").hexdigest == info.fetch('sha256')
    end
  else
    abort 'Araso beta must only ship on canary' if File.exist?(helper)
  end
end

Dir.mktmpdir('gkdl-release-') do |stage|
  ReleaseArchive.validate_listing!(capture!('/usr/bin/unzip', '-Z1', archive), capture!('/usr/bin/unzip', '-Z', '-l', archive))
  capture!('/usr/bin/ditto', '-x', '-k', archive, stage)
  app = "#{stage}/gkdl.app"
  license = "#{app}/Contents/Resources/LICENSE"
  abort 'Archive must include the current LICENSE' unless File.file?(license) &&
    File.binread(license) == File.binread("#{root}/LICENSE")
  capture!('/usr/bin/codesign', '--verify', '--deep', '--strict', '--all-architectures', '-R', requirement, app)
  %w[CFBundleShortVersionString CFBundleVersion CFBundleIdentifier CFBundleExecutable].each do |key|
    expected = capture!('/usr/libexec/PlistBuddy', '-c', "Print :#{key}", "#{root}/Info.plist")
    actual = capture!('/usr/libexec/PlistBuddy', '-c', "Print :#{key}", "#{app}/Contents/Info.plist")
    abort "Archive #{key} does not match source" unless expected == actual
  end
  arches = capture!('/usr/bin/lipo', '-archs', "#{app}/Contents/MacOS/gkdl").split
  abort 'Expected arm64 + x86_64' unless arches.sort == %w[arm64 x86_64]
  helper_arches = capture!('/usr/bin/lipo', '-archs', "#{app}/Contents/Helpers/gkdl").split
  abort 'Expected Universal CLI helper' unless helper_arches.sort == %w[arm64 x86_64]
  signature = capture!('/usr/bin/codesign', '-d', '--verbose=4', app)
  abort 'Secure timestamp and hardened runtime required' unless signature.match?(/^Timestamp=/) && signature.match?(/flags=.*\(runtime\)/)
  capture!('/usr/bin/xcrun', 'stapler', 'validate', app)
  capture!('/usr/sbin/spctl', '--assess', '--type', 'execute', '--verbose=2', app)
  verify_beta.call(app)
  archive_hashes = code_hashes.call(app)
end

dmg = File.expand_path(ARGV[1] || File.join(File.dirname(archive), metadata.dmg_filename))
abort 'Missing release disk image' unless File.file?(dmg)
abort "Disk image must be named #{metadata.dmg_filename}" unless File.basename(dmg) == metadata.dmg_filename
dmg_requirement = requirement.sub('"com.zzune.gkdl"', '"com.zzune.gkdl.dmg"')
capture!('/usr/bin/codesign', '--verify', '--strict', '-R', dmg_requirement, dmg)
capture!('/usr/bin/xcrun', 'stapler', 'validate', dmg)
capture!('/usr/sbin/spctl', '--assess', '--type', 'open', '--context', 'context:primary-signature', '--verbose=2', dmg)
Dir.mktmpdir('gkdl-dmg-') do |stage|
  volume = "#{stage}/volume"
  begin
    capture!('/usr/bin/hdiutil', 'attach', '-readonly', '-nobrowse', '-noautoopen', '-mountpoint', volume, dmg)
    ReleaseDiskImage.validate_contents!(volume)
    app = "#{volume}/gkdl.app"
    capture!('/usr/bin/codesign', '--verify', '--deep', '--strict', '--all-architectures', '-R', requirement, app)
    capture!('/usr/bin/xcrun', 'stapler', 'validate', app)
    verify_beta.call(app)
    abort 'Disk image app differs from the archive' unless code_hashes.call(app) == archive_hashes
  ensure
    if File.directory?(volume)
      system('/usr/bin/hdiutil', 'detach', '-quiet', volume) || system('/usr/bin/hdiutil', 'detach', '-force', '-quiet', volume)
    end
  end
end

checksum = "#{Digest::SHA256.file(archive).hexdigest}  #{metadata.filename}\n" \
  "#{Digest::SHA256.file(dmg).hexdigest}  #{metadata.dmg_filename}\n"
sums = File.join(File.dirname(archive), 'SHA256SUMS')
abort 'SHA256SUMS does not match the verified archive' unless File.file?(sums) && File.read(sums) == checksum
puts "Verified: #{metadata.filename}, #{metadata.dmg_filename} (Developer ID, Universal, matching app, notarization tickets, Gatekeeper, SHA256)"
