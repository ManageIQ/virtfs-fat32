require 'ostruct'

module VirtFS::Fat32
  class Directory
    attr_accessor :fs, :bs, :cluster

    def initialize(fs, bs, cluster = nil)
      raise "nil boot sector"   if bs.nil?
      cluster = bs.root_cluster if cluster.nil?

      self.bs = bs
      self.cluster = cluster == 0 ? bs.alloc_clusters(0) : cluster
      self.fs = fs
    end

    def close
    end

    def read(pos)
      return cache[pos], pos + 1
    end

    def data
      @data ||= begin
        clus = cluster
        buf = bs.cluster(clus)
        while (data = bs.next_cluster(clus)) != nil
          clus = data[0]
          buf += data[1]
        end
        buf
      end
    end

    def clusters
      @clusters ||= begin
        clus     = cluster
        clusters = [new_cluster_status(clus, 0)]
        while (data = bs.next_cluster(clus)) != nil
          clus      = data[0]
          clusters << new_cluster_status(clus, 0)
        end
        clusters
      end
    end

    def new_cluster_status(num, dirty)
      status = OpenStruct.new
      status.number = num
      status.dirty = dirty
      status
    end

    def cluster_status(offset)
      cluster[offset.divmod(bs.bytes_per_cluser)[0]]
    end

    def self.deleted?(dir_entry)
      dir_entry.name    == DirectoryEntry::AF_DELETED ||
      dir_entry.name[0] == DirectoryEntry::AF_DELETED
    end

    def deleted?(dir_entry)
      self.class.deleted?(dir_entry)
    end

    def max_entries_per_cluster
      @max_entries_per_cluster ||= bs.bytes_per_cluster / DIR_ENT_SIZE - 1
    end

    def glob_entries
      entries = []
      names   = []
      clus    = cluster
      clus_io = bs.cluster_io(clus)

      loop do
        max_entries_per_cluster.times do
          de = DirectoryEntry.new(fs, clus_io.read)
          entries << de unless de.name == "" || deleted?(de)

          clus_io = StringIO.new(de.unused)
          break if clus_io.size == 0
        end

        clus = bs.next_cluster_id(clus)
        break if clus.nil?
        clus_io = bs.cluster_io(clus)
      end
      entries
    end

    def glob_names
      glob_entries.collect { |e| e.name }.sort
    end

    def find_entry(name, flags = FE_EITHER)
      downcased = name.downcase
      skip_next = false

      0.step(data.length - 1, DIR_ENT_SIZE) do |offset|
        # check allocation status
        # (ignore if deleted, done if not allocated)
        alloc_flags = data[offset].bytes.first
        next  if DirectoryEntry.skip?(alloc_flags)
        break if DirectoryEntry.stop?(alloc_flags)

        attrib = data[offset + ATTRIB_OFFSET].bytes.first
        lfn_fa = DirectoryEntry.lfn_fa?(attrib)

        # skip LFN entries unless it's the first
        # (last iteration already chewed them all up)
        if lfn_fa && !DirectoryEntry.lfn_last?(alloc_flags)
          skip_next = true
          next
        elsif skip_next
          skip_next = false
          next
        end

        # skip entries we are not looking for
        # TODO instead look ahead and see what the base entry is.
        next if !lfn_fa && (flags == FE_DIR  && !DirectoryEntry::dir?(attrib)) ||
                           (flags == FE_FILE && !DirectoryEntry::file?(attrib))

        # potential match, stop if found.
        entry = DirectoryEntry.new(fs, data[offset, MAX_ENT_SIZE])
        found = entry.name.downcase       == downcased || # TODO handle case where name ends with a dot &
                entry.short_name.downcase == downcased    # there's another dot in the name

        if found
          parent = offset.divmod(bs.bytes_per_cluster)
          entry.parent_cluster = clusters[parent[0]].number
          entry.parent_offset  = parent[1]
          return entry
        end
      end

      nil
    end

    def mkdir(name)
    end

    def create_file(name)
    end

    def first_free_entry(num_entries = 1, behavious = GF_W98)
    end

    def count_free_entries(behaviour, buf)
    end

    def free?(alloc_status, behaviour)
    end

    private

    def cache
      @cache ||= glob_entries.to_a
    end
  end # class Directory
end # module VirtFS::Fat32
