require_relative 'fs/dir_class_methods'
require_relative 'fs/file_class_methods'

require 'rufus-lru'

module VirtFS::Fat32
  class FS
    include DirClassMethods
    include FileClassMethods

    attr_accessor :mount_point, :blk_device

    def self.match?(blk_device)
      # Assume FAT32 - read boot sector.
      blk_device.seek(0)
      bs = blk_device.read(512)

      # Check file system label for 'FAT32'
      bs[82, 8].unpack('a8')[0].strip == 'FAT32'
    end

    def initialize(blk_device)
      super()
      @blk_device = blk_device
    end

    def thin_interface?
      true
    end

    def umount
      @mount_point = nil
    end

    def boot_sector
      @boot_sector ||= BootSector.new(blk_device)
    end

    def drive_root
      @drive_root ||= Directory.new(boot_sector)
    end

    def root_dir_entry
      @root_dir_entry ||= begin
        de = DirectoryEntry.new
        de.set_attribute(DirectoryEntry::FA_DIRECTORY)
        de.first_cluster = 0
        de.zero_time!
        de
      end
    end

    def dir_cache
      @dir_cache ||= LruHash.new(DEF_CACHE_SIZE)
    end

    def cache_hits
      @cache_hits ||= 0
    end

    def id
      boot_sector.id
    end

    def vol_name
      boot_sector.vol_name
    end

    def free_bytes
      boot_sector.free_clusters * boot_sector.bytes_per_cluster
    end

    # Wack leading drive leter & colon.
    def unormalize_path(p)
      p[1] == 58 ? p[2, p.size] : p
    end
  end # class FS
end # module VirtFS::Fat32
