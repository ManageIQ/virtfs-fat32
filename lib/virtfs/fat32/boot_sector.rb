require 'stringio'

module VirtFS::Fat32
  class BootSector
    attr_accessor :bs, :blk_device

    def initialize(blk_device)
      blk_device.seek 0
      self.blk_device = blk_device
      self.bs = BOOT_SECT.decode(blk_device.read(BOOT_SECT.size))
      validate_boot_sector!
      validate_fsinfo!
    end

    def bytes_per_sector
      @bytes_per_sector ||= bs['bytes_per_sec']
    end

    def sectors_per_cluster
      @sectors_per_cluster ||= bs['sec_per_clus']
    end

    def bytes_per_cluster
      @bytes_per_cluster ||= bytes_per_sector * sectors_per_cluster
    end

    def fsinfo_sector
      @fsinfo_sector ||= bs['fsinfo_sec']
    end

    def fsinfo
      @fsinfo ||= begin
        blk_device.seek fsinfo_sector * bytes_per_sector
        FSINFO.decode(blk_device.read(bytes_per_sector))
      end
    end

    def fsinfo?
      fsinfo['sig1'] == 'RRaA' && fsinfo['sig2'] == 'rrAa' && fsinfo['sig3'] == 0xaa550000
    end

    def free_clusters
      @free_clusters ||=  fsinfo? ? fsinfo['free_clus'] : 0
    end

    def serial_num
      @serial_num ||= bs['serial_num']
    end

    def id
      serial_num
    end

    def label
      @label ||= bs['label']
    end

    def vol_name
      label
    end

    def oem_name
      @oem_name ||= bs['oem_name']
    end

    def max_root
      @max_root ||= bs['max_root']
    end

    def fat_size32
      @fat_size32 ||= bs['fat_size32']
    end

    def fat_size32_bytes
      fat_size32 * bytes_per_sector
    end

    def fat_size
      fat_size32_bytes
    end

    def num_fats
      @num_fats ||= bs['num_fats']
    end

    def num_sec16
      @num_sec16 ||= bs['num_sec16']
    end

    def num_sec32
      @num_sec32 ||= bs['num_sec32']
    end

    def signature
      @signature ||= bs['signature']
    end

    def res_sector
      @res_sec ||= bs['res_sec']
    end

    def res_sector_bytes
      res_sector * bytes_per_sector
    end

    def fat_usage
      @fat_usage ||= bs['fat_usage']
    end

    def one_fat
      fat_usage & FU_ONE_FAT == FU_ONE_FAT
    end

    def active_fat_usage
      fat_usage & FU_MSK_ACTIVE_FAT
    end

    def active_fat
      fat_size * active_fat_usage
    end

    def root_cluster
      @root_clus ||= bs['root_clus']
    end

    def root_cluster_byte
      cluster_to_byte(root_cluster)
    end

    def root_base
      root_cluster_byte
    end

    def fat_base
      @fat_base ||= begin
        fb  = res_sector_bytes
        fb += active_fat_usage if one_fat
        fb
      end
    end

    def validate_boot_sector!
      raise "nil blk device"                             if blk_device.nil?
      raise "invalid boot sector"                        if bs.nil?
      raise "Maximum files invalid #{max_root}"          if max_root   != 0
      raise "Sectors invalid: #{fat_size32}"             if fat_size32 == 0
      raise "Unknown sectors"                            if num_sec16  == 0 &&
                                                            num_sec32  == 0
      raise "signature invalid: 0x#{'%04x' % signature}" if signature  != DOS_SIGNATURE
    end

    def validate_fsinfo!
      raise "invalid fsinfo sig1" if fsinfo['sig1'] != FSINFO_SIG1
      raise "invalid fsinfo sig2" if fsinfo['sig2'] != FSINFO_SIG2
      raise "invalid fsinfo sig3" if fsinfo['sig3'] != FSINFO_SIG3
    end

    def mountable?
      fat_base != 0 && fat_size != 0 && root_base != 0
    end

    def cluster_to_byte(cluster_id)
      raise "cluster is nil" if cluster_id.nil?
      res_sector_bytes + fat_size * num_fats + (cluster_id - 2) * bytes_per_cluster
    end

    # Get data for the requested cluster.
    def cluster(cluster_id)
      raise "cluster is nil" if cluster_id.nil?
      blk_device.seek(cluster_to_byte(cluster_id))
      blk_device.read(bytes_per_cluster)
    end

    # Get string i/o handle to specified cluster
    def cluster_io(cluster_id)
      StringIO.new(cluster(cluster_id))
    end

    # Gets next cluster id for given cluster, or nil if end
    def next_cluster_id(cluster_id)
      nxt  = fat_entry(cluster_id)
      nxt >= CC_END_OF_CHAIN ? nil : nxt
    end

    # Gets data for the next cluster given current, or nil if end.
    def next_cluster(cluster_id)
      nxt = next_cluster_id(cluster_id)
      return nil if nxt.nil?
      raise "damaged cluster" if nxt == CC_DAMAGED
      [nxt, cluster(nxt)]
    end

    # return all cluster ids
    def cluster_ids
      @cluster_ids ||= begin
        clusters = []
        clus = [root_cluster]
        while !clus.nil?
          clusters << clus.first
          clus = next_cluster(clus.first)
        end
        clusters
      end
    end

    def fat_entry(cluster_id)
      blk_device.seek(fat_base + FAT_ENTRY_SIZE * cluster_id)
      blk_device.read(FAT_ENTRY_SIZE).unpack('L')[0] & CC_VALUE_MASK
    end
  end # class BootSector
end # module VirtFS::Fat32
