require 'spec_helper'
require 'fileutils'
require 'tmpdir'

describe "mount sub-dir on sub-dir" do
  def cassette_path
    "spec/cassettes/root.yml"
  end

  context "Read access" do
    it "directory entries should match" do
      expect(VirtFS::VDir.entries(@fat.mount_point)).to match_array(VirtFS::VDir.entries(@root))
    end
  end
end
