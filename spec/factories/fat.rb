require 'ostruct'
require 'virtfs/block_io'
require 'virt_disk/block_file'

FactoryGirl.define do
  factory :fat, class: OpenStruct do
    path '/home/mmorsi/workspace/cfme/virtfs-fat32/fat.fs'
    fs { VirtFS::Fat32::FS.new(VirtFS::BlockIO.new(VirtDisk::BlockFile.new(path))) }
    root_dir ["a", "b", "d1", "d2"]
    glob_dir []
    boot_size 2048
  end
end
