require 'active_support/core_ext/object/try' # until we can use the safe nav operator

module VirtFS::Fat32
  class FS
    module DirClassMethods
      def dir_delete(p)
        raise "writes not supported"
      end

      def dir_entries(p)
        dir = get_dir(p)
        return nil if dir.nil?
        dir.glob_names
      end

      def dir_exist?(p)
        begin
          !get_dir(p).nil?
        rescue
          false
        end
      end

      def dir_foreach(p, &block)
        r = get_dir(p).try(:glob_names).try(:each, &block)
        block.nil? ? r : nil
      end

      def dir_mkdir(p, permissions)
        raise "writes not supported"
      end

      def dir_new(fs_rel_path, hash_args, _open_path, _cwd)
        get_dir(fs_rel_path)
      end

      private

      def get_dir(path)
        path = unormalize_path path
        if dir_cache.key?(path)
          cache_hits += 1
          return Directory.new(self, boot_sector, dir_cache[path])
        end

        # Return root if lone separator.
        return Directory.new(self, boot_sector) if path == "/" || path == "\\"

        # Get an array of directory names...
        names = path.split(/[\\\/]/)

        # ...kill off the first (always empty)
        names.shift

        # Find first cluster of target dir.
        cluster = boot_sector.root_cluster
        loop do
          break if names.empty?
          dir = Directory.new(self, boot_sector, cluster)
          de = dir.find_entry(names.shift, Directory::FE_DIR)
          raise "Can't find directory: \'#{path}\'" if de.nil?
          cluster = de.first_cluster
        end

        dir_cache[p] = cluster
        Directory.new(self, boot_sector, cluster)
      end
    end # module DirClassMethods
  end # class FS
end # module VirtFS::Fat32
