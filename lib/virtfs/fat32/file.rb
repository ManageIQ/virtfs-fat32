module VirtFS::Fat32
  class File
    attr_accessor :fs

    def initialize(fs, dir_entry, boot_sector)
      @fs = fs
      @bs = boot_sector
      @de = dir_entry
    end

    def size
      @de.length
    end

    def close
      # noop
    end

    def to_h
      { :directory? => @de.dir?,
        :file?      => @de.file?,
        :symlink?   => @de.symlink? }
    end
  end # class File
end # module VirtFS::Fat32
