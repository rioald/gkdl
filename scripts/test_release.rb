require 'minitest/autorun'
require_relative 'release-metadata'

class ReleaseTests < Minitest::Test
  def test_release_version_and_tag_must_match
    %w[main v1.2.1 pre-v.1.2.0 ../1.2.0].each do |tag|
      assert_raises(ArgumentError) { ReleaseMetadata.new('1.2.0', tag) }
    end
    ["1.2.0\n", '1.2', '1.2.0-beta.1', '01.2.0'].each do |version|
      assert_raises(ArgumentError) { ReleaseMetadata.new(version) }
    end
    assert_equal 'gkdl-1.2.0-macos-universal.zip', ReleaseMetadata.new('1.2.0').filename
    assert_equal 'gkdl-1.2.0-pre-macos-universal.zip', ReleaseMetadata.new('1.2.0', 'pre-v1.2.0').filename
  end

  def listing(mode = '-rw-r--r--', size = 128)
    "Archive: release.zip\n#{mode}  2.0 unx #{size} b- defN 26-Oct-03 00:00 gkdl.app/Contents/Info.plist\n"
  end

  def test_release_accepts_only_its_app_directory
    assert ReleaseArchive.validate_listing!("gkdl.app/Contents/Info.plist\n", listing)
    ['', 'gksdud.app/Contents/Info.plist', '/gkdl.app/a', 'gkdl.app/../escape', 'gkdl.app/a\\b', "gkdl.app/a\rb"].each do |name|
      assert_raises(ArgumentError, name.inspect) { ReleaseArchive.validate_listing!(name, listing) }
    end
  end

  def test_rejects_links_extra_entries_and_oversized_expansion
    ['lrwxr-xr-x', 'crw-r--r--'].each do |mode|
      assert_raises(ArgumentError) { ReleaseArchive.validate_listing!('gkdl.app/a', listing(mode)) }
    end
    assert_raises(ArgumentError) { ReleaseArchive.validate_listing!("gkdl.app/a\ngkdl.app/b", listing) }
    assert_raises(ArgumentError) { ReleaseArchive.validate_listing!('gkdl.app/a', listing('-rw-r--r--', 200_000_001)) }
    assert_raises(ArgumentError) { ReleaseArchive.validate_listing!('gkdl.app/a', listing('-rw-r--r--', 0)) }
  end
end
