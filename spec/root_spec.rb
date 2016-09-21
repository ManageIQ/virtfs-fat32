require 'spec_helper'
require 'fileutils'
require 'tmpdir'

describe "mount sub-dir on sub-dir" do
  before(:all) do
    reset_context

    @root = File::SEPARATOR
    @fat  = build(:fat)
    VirtFS.mount(@fat.fs, @root)
  end

  after(:all) do
    VirtFS.umount(@root)
  end

  context "Read access" do
    it "directory entries should match" do
      expect(VirtFS::VDir.entries(@fat.fs.mount_point)).to match_array(VirtFS::VDir.entries(@root))
    end
  end
end
