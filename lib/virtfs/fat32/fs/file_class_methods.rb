module VirtFS::Fat32
  class FS
    module FileClassMethods
      def file_atime(p)
        f = get_file(p)
        raise Errno::ENOENT, "No such file or directory" if f.nil?
        f.atime
      end

      def file_blockdev?(p)
      end

      def file_chardev?(p)
      end

      def file_chmod(permission, p)
        raise "writes not supported"
      end

      def file_chown(owner, group, p)
        raise "writes not supported"
      end

      def file_ctime(p)
        f = get_file(p)
        raise Errno::ENOENT, "No such file or directory" if f.nil?
        f.ctime
      end

      def file_delete(p)
        raise "writes not supported"
      end

      def file_directory?(p)
        f = get_file(p)
        !f.nil? && f.dir?
      end

      def file_executable?(p)
      end

      def file_executable_real?(p)
      end

      def file_exist?(p)
        ["/", "\\"].include?(p) || !get_file(p).nil?
      end

      def file_file?(p)
        de = get_file(p)
        !de.nil? && !de.dir?
      end

      def file_ftype(p)
      end

      def file_grpowned?(p)
      end

      def file_identical?(p1, p2)
      end

      def file_lchmod(permission, p)
        raise "writes not supported"
      end

      def file_lchown(owner, group, p)
      end

      def file_link(p1, p2)
      end

      def file_lstat(p)
        file = get_file(p)
        raise Errno::ENOENT, "No such file or directory" if file.nil?
        VirtFS::Stat.new(VirtFS::Fat32::File.new(self, file, boot_sector).to_h)
      end

      def file_mtime(p)
        f = get_file(p)
        raise Errno::ENOENT, "No such file or directory" if f.nil?
        f.mtime
      end

      def file_owned?(p)
      end

      def file_pipe?(p)
      end

      def file_readable?(p)
      end

      def file_readable_real?(p)
      end

      def file_readlink(p)
      end

      def file_rename(p1, p2)
      end

      def file_setgid?(p)
      end

      def file_setuid?(p)
      end

      def file_size(p)
        f = get_file(p)
        raise Errno::ENOENT, "No such file or directory" if f.nil?
        f.length
      end

      def file_socket?(p)
      end

      def file_stat(p)
      end

      def file_sticky?(p)
      end

      def file_symlink(oname, p)
      end

      # FAT file systems don't do symbolic links.
      def file_symlink?(p)
        false
      end

      def file_truncate(p, len)
      end

      def file_utime(atime, mtime, p)
      end

      def file_world_readable?(p, len)
      end

      def file_world_writable?(p, len)
      end

      def file_writable?(p, len)
      end

      def file_writable_real?(p, len)
      end

      def file_new(f, parsed_args, _open_path, _cwd)
        file = get_file(f)
        raise Errno::ENOENT, "No such file or directory" if file.nil?
        File.new(self, file, boot_sector)
      end

      private

      def get_file(p)
        # return spoof dir ent if root
        return root_dir_entry if p == "/" || p == "\\"

        # preprocess path
        p = unormalize_path(p)
        dir, fil = VfsRealFile.split(p)

        begin
          dir_obj = get_dir(dir)
          return nil if dir_obj.nil?
          dir_entry = dir_obj.find_entry(fil)
          return nil if dir_entry.nil?
        rescue RuntimeError
          return nil
        end

        dir_entry
      end
    end # module FileClassMethods
  end # class FS
end # module VirtFS::Fat32
