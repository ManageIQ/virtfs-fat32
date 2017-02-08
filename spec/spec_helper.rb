$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'virtfs'
require 'virtfs-nativefs-thick'
require 'virtfs-fat32'
require 'factory_girl'

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

    @fat     = build(:fat,
                     #virtual_root: Dir.pwd)
                     virtual_root: '/home/mmorsi/workspace/cfme/virtfs-fat32')
    @root    = @fat.mount_point

    block_dev = VirtFS::BlockIO.new(VirtDisk::BlockFile.new(@fat.path))
    fatfs     = VirtFS::Fat32::FS.new(block_dev)

    VirtFS.mount(fatfs, @root)
  end

  config.after(:all) do
    VirtFS.umount(@root)
    VirtFS.umount("/")
  end
end
