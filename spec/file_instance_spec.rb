require 'spec_helper'

describe "VirtFS::FAT32::File instance methods" do
  before(:all) do
    @full_path = @fat.glob_dir.first
  end

  before(:each) do
    VirtFS::VDir.chdir(@root)
  end

  describe "#path :to_path" do
    it "should return full path when opened with full path" do
      VirtFS::VFile.open(@full_path) { |f| expect(f.path).to eq(@full_path) }
    end

    it "should return relative path when opened with relative path" do
      parent, target_file = VfsRealFile.split(@full_path)
      VirtFS::VDir.chdir(parent)
      VirtFS::VFile.open(target_file) { |f| expect(f.path).to eq(target_file) }
    end
  end
end
