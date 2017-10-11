require 'ostruct'

FactoryGirl.define do
  factory :fat, class: OpenStruct do
    recording_path "spec/cassettes/template.yml"

    mount_point "/mnt"

    root_dir ["a", "b", "d1", "d2"]

    glob_dir ['d1/c', 'd1/d', 'd1/s3']

    boot_size 2048

    recording_root { "spec/virtual/" }

    recorder {
      r = VirtFS::CamcorderFS::FS.new(recording_path)
      r.root = recording_root
      r
    }

    path { "#{recording_root}/fat.fs" }
  end
end
