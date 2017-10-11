require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'virtfs'
require 'virtfs-fat32'
require 'virtfs-nativefs-thick'
require 'factory_girl'

# XXX bug in camcorder (missing dependency)
require 'fileutils'
require 'virtfs-camcorderfs'

require 'virt_disk'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.find_definitions
  end

  config.before(:all) do
    VirtFS.mount(VirtFS::NativeFS::Thick.new, "/")

    @orig_dir = Dir.pwd
    @fat = build(:fat,
                 recording_path: cassette_path)

    VirtFS.mount(@fat.recorder, File.expand_path("#{@fat.recording_root}"))
    VirtFS.activate!
    VirtFS.dir_chdir(@orig_dir)

    @root     = @fat.mount_point
    block_dev = VirtDisk::Disk.new(VirtDisk::FileIo.new(@fat.path))
    fatfs     = VirtFS::Fat32::FS.new(block_dev)
    VirtFS.mount(fatfs, @fat.mount_point)
  end

  config.after(:all) do
    VirtFS.deactivate!
    VirtFS.umount(@fat.mount_point)
    VirtFS.dir_chdir("/")
    VirtFS.umount(File.expand_path("#{@fat.recording_root}"))
    VirtFS.umount("/")
  end
end
