module VirtFS::Fat32
  class File
    def initialize(dir_entry, boot_sector)
      @bs = boot_sector
      @de = dir_entry
    end

    def to_h
      { :directory? => @de.dir?,
        :file?      => @de.file?,
        :symlink?   => @de.symlink? }
    end
  end # class File
end # module VirtFS::Fat32
