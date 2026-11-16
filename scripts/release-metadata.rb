# Modified for gkdl; upstream DMG naming is adapted under Apache-2.0 (see LICENSE).
# Shared tag validation and asset naming for the release workflow and verifier.
class ReleaseMetadata
  attr_reader :version, :tag

  def initialize(version, tag = "v#{version}")
    raise ArgumentError, 'Expected 3 to 5 numeric version fields' unless version.match?(/\A(0|[1-9]\d*)(\.(0|[1-9]\d*)){2,4}\z/)
    if version.split('.').length > 3 && version.split('.').last == '0'
      raise ArgumentError, 'Prerelease and canary sequence numbers start at 1'
    end
    unless tag == "v#{version}"
      raise ArgumentError, 'Tag must be vVERSION and match the release version'
    end
    @version = version
    @tag = tag
  end

  def prerelease?
    channel != 'stable'
  end

  def channel
    { 3 => 'stable', 4 => 'prerelease', 5 => 'canary' }.fetch(version.split('.').length)
  end

  def asset_version
    version
  end

  def filename
    "gkdl-#{asset_version}-macos-universal.zip"
  end

  def dmg_filename
    "gkdl-#{asset_version}.dmg"
  end

  def outputs
    { version: version, tag: tag, channel: channel, prerelease: prerelease?,
      asset_version: asset_version, filename: filename, dmg_filename: dmg_filename }
  end
end

module ReleaseArchive
  def self.validate_listing!(names, listing)
    entries = names.split("\n")
    valid = !entries.empty? && entries.length <= 5000 && entries.all? do |name|
      name.start_with?('gkdl.app/') && !name.include?('\\') && !name.include?("\r") && !name.split('/').include?('..')
    end
    raise ArgumentError, 'Unexpected ZIP paths' unless valid
    modes = listing.lines.select { |line| line.match?(/\A.[rwxstST-]{9}\s/) }
    raise ArgumentError, 'ZIP links or unexpected entries' unless modes.length == entries.length && modes.all? { |line| %w[- d].include?(line[0]) }
    sizes = modes.map { |line| Integer(line.split.fetch(3)) }
    raise ArgumentError, 'Invalid expanded ZIP size' unless sizes.all? { |size| size >= 0 } && sizes.sum.between?(1, 200_000_000)
    true
  end
end

module ReleaseDiskImage
  def self.validate_contents!(volume)
    entries = Dir.children(volume)
    # macOS can recreate its filesystem event directory while detaching a writable image.
    events = File.join(volume, '.fseventsd')
    entries.delete('.fseventsd') if File.directory?(events) && !File.symlink?(events)
    applications = File.join(volume, 'Applications')
    valid = entries.sort == ['.DS_Store', '.VolumeIcon.icns', '.background.tiff', 'Applications', 'gkdl.app'] &&
      File.symlink?(applications) && File.readlink(applications) == '/Applications'
    raise ArgumentError, 'Unexpected disk image contents' unless valid
    true
  end
end

if $PROGRAM_NAME == __FILE__
  abort 'Usage: ruby scripts/release-metadata.rb VERSION TAG' unless ARGV.length == 2
  begin
    ReleaseMetadata.new(*ARGV).outputs.each { |key, value| puts "#{key}=#{value}" }
  rescue ArgumentError => e
    abort e.message
  end
end
