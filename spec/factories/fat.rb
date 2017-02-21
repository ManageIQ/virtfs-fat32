require 'ostruct'
require 'virtfs/block_io'
require 'virt_disk/block_file'

FactoryGirl.define do
  factory :fat, class: OpenStruct do
    virtual_root ''

    recording_path "spec/cassettes/template.yml"

    ###

    mount_point '/mnt'

    root_dir ["a", "b", "d1", "d2"]

    glob_dir ['d1/c', 'd1/d', 'd1/s3']

    boot_size 2048

    recording_root { "#{virtual_root}/images" }

    recorder {
      rec = VirtFS::CamcorderFS::FS.new(File.expand_path(recording_path))
      rec.root = recording_root
      rec
    }

    ###

    path { "#{virtual_root}/images/fat.fs" }
  end
end
