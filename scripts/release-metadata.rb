# Shared tag validation and asset naming for the release workflow and verifier.
class ReleaseMetadata
  attr_reader :version, :tag

  def initialize(version, tag = "v#{version}")
    raise ArgumentError, 'Expected numeric release version' unless version.match?(/\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)\z/)
    unless ["v#{version}", "pre-v#{version}"].include?(tag)
      raise ArgumentError, 'Tag must be vVERSION or pre-vVERSION and match the release version'
    end
    @version = version
    @tag = tag
  end

  def prerelease?
    tag.start_with?('pre-v')
  end

  def asset_version
    prerelease? ? "#{version}-pre" : version
  end

  def filename
    "gkdl-#{asset_version}-macos-universal.zip"
  end

  def outputs
    { version: version, tag: tag, prerelease: prerelease?,
      asset_version: asset_version, filename: filename }
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

if $PROGRAM_NAME == __FILE__
  abort 'Usage: ruby scripts/release-metadata.rb VERSION TAG' unless ARGV.length == 2
  begin
    ReleaseMetadata.new(*ARGV).outputs.each { |key, value| puts "#{key}=#{value}" }
  rescue ArgumentError => e
    abort e.message
  end
end
