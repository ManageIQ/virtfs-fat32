require 'ostruct'

FactoryGirl.define do
  factory :fat, class: OpenStruct do
    virtual_root ''

    mount_point "/mnt"

    path { "#{virtual_root}/images/fat.fs" }

    root_dir ["a", "b", "d1", "d2"]

    glob_dir ['d1/c', 'd1/d', 'd1/s3']

    boot_size 2048
  end
end
