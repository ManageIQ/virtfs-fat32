require 'binary_struct'

module VirtFS::Fat32
  # Default directory cache size.
  DEF_CACHE_SIZE = 50

  ### Boot Sector:

  BOOT_SECT = BinaryStruct.new([
    'a3', 'jmp_boot',       # Jump to boot loader.
    'a8', 'oem_name',       # OEM Name in ASCII.
    'S',  'bytes_per_sec',  # Bytes per sector: 512, 1024, 2048 or 4096.
    'C',  'sec_per_clus',   # Sectors per cluster, size must be < 32K.
    'S',  'res_sec',        # Reserved sectors.
    'C',  'num_fats',       # Typically 2, but can be 1.
    'S',  'max_root',       # Max files in root dir - 0 FOR FAT32.
    'S',  'num_sec16',      # 16-bit number of sectors in file system (0 if 32-bits needed).
    'C',  'media_type',     # Ususally F8, but can be F0 for removeable.
    'S',  'fat_size16',     # 16-bit number of sectors in FAT, 0 FOR FAT32.
    'S',  'sec_per_track',  # Sectors per track.
    'S',  'num_heads',      # Number of heads.
    'L',  'pre_sec',        # Sectors before the start of the partition.
    'L',  'num_sec32',      # 32-bit number of sectors in the file system (0 if 16-bit num used).
    'L',  'fat_size32',     # 32-bit number of sectors in FAT.
    'S',  'fat_usage',      # Describes how FATs are used: See FU_ below.
    'S',  'version',        # Major & minor version numbers.
    'L',  'root_clus',      # Cluster location of root directory.
    'S',  'fsinfo_sec',     # Sector location of FSINFO structure .
    'S',  'boot_bkup',      # Sector location of boot sector backup.
    'a12',  'reserved1',    # Reserved.
    'C',  'drive_num',      # INT13 drive number.
    'C',  'unused1',        # Unused.
    'C',  'ex_sig',         # If 0x29, then the next three values are valid.
    'L',  'serial_num',     # Volume serial number.
    'a11',  'label',        # Volume label.
    'a8', 'fs_label',       # File system type label, not required.
    'a420', nil,            # Unused.
    'S',  'signature',      # 0xaa55
  ])

  DOS_SIGNATURE   = 0xaa55

  FSINFO = BinaryStruct.new([
    'a4', 'sig1',       # Signature - 0x41615252 (RRaA).
    'a480', nil,        # Unused.
    'a4', 'sig2',       # Signature - 0x61417272 (rrAa).
    'L',  'free_clus',  # Number of free clusters.
    'L',  'next_free',  # Next free cluster.
    'a12',  nil,        # Unused.
    'L',  'sig3',       # Signature - 0xaa550000.
  ])

  FSINFO_SIG1 = "RRaA"
  FSINFO_SIG2 = "rrAa"
  FSINFO_SIG3 = 0xaa550000

  FAT_ENTRY_SIZE  = 4

  FU_ONE_FAT        = 0x0080
  FU_MSK_ACTIVE_FAT = 0x000f

  CC_NOT_ALLOCATED  = 0
  CC_DAMAGED        = 0x0ffffff7
  CC_END_OF_CHAIN   = 0x0ffffff8
  CC_END_MARK       = 0x0fffffff
  CC_VALUE_MASK     = 0x0fffffff

  class Directory
    # Maximum LFN entry span in bytes (LFN entries *can* span clusters).
    MAX_ENT_SIZE = 640

    # Find entry flags.
    FE_DIR = 0
    FE_FILE = 1
    FE_EITHER = 2

    # Get free entry behaviors.
    # Windows 98 returns the first deleted or unallocated entry.
    # Windows XP returns the first unallocated entry.
    # Advantage W98: less allocation, advantage WXP: deleted entries are not overwritten.
    GF_W98 = 0
    GF_WXP = 1
  end # class Directory

  ### Directory Entry:

  DIR_ENT_SFN = BinaryStruct.new([
    'a11',  'name',         # If name[0] = 0, unallocated; if name[0] = 0xe5, deleted. DOES NOT INCLUDE DOT.
    'C',  'attributes',     # See FA_ below. If 0x0f then LFN entry.
    'C',  'reserved1',      # Reserved.
    'C',  'ctime_tos',      # Created time, tenths of second.
    'S',  'ctime_hms',      # Created time, hours, minutes & seconds.
    'S',  'ctime_day',      # Created day.
    'S',  'atime_day',      # Accessed day.
    'S',  'first_clus_hi',  # Hi 16-bits of first cluster address.
    'S',  'mtime_hms',      # Modified time, hours, minutes & seconds.
    'S',  'mtime_day',      # Modified day.
    'S',  'first_clus_lo',  # Lo 16-bits of first cluster address.
    'L',  'file_size',      # Size of file (0 for directories).
  ])

  DIR_ENT_LFN = BinaryStruct.new([
    'C',  'seq_num',    # Sequence number, bit 6 marks end, 0xe5 if deleted.
    'a10',  'name',     # UNICODE chars 1-5 of name.
    'C',  'attributes', # Always 0x0f.
    'C',  'reserved1',  # Reserved.
    'C',  'checksum',   # Checksum of SFN entry, all LFN entries must match.
    'a12',  'name2',    # UNICODE chars 6-11 of name.
    'S',  'reserved2',  # Reserved.
    'a4', 'name3'       # UNICODE chars 12-13 of name.
  ])

  CHARS_PER_LFN   = 13
  LFN_NAME_MAXLEN = 260
  DIR_ENT_SIZE    = 32
  ATTRIB_OFFSET   = 11

  class DirectoryEntry
    # From the UTF-8 perspective.
    # LFN name components: entry hash name, char offset, length.
    LFN_NAME_COMPONENTS = [
      ['name',   0, 5],
      ['name2',  5, 6],
      ['name3', 11, 2]
    ]
    # Name component second sub access names.
    LFN_NC_HASHNAME = 0
    LFN_NC_OFFSET   = 1
    LFN_NC_LENGTH   = 2

    # SFN failure cases.
    SFN_NAME_LENGTH   = 1
    SFN_EXT_LENGTH    = 2
    SFN_NAME_NULL     = 3
    SFN_NAME_DEVICE   = 4
    SFN_ILLEGAL_CHARS = 5

    # LFN failure cases.
    LFN_NAME_LENGTH   = 1
    LFN_NAME_DEVICE   = 2
    LFN_ILLEGAL_CHARS = 3

    # FileAttributes
    FA_READONLY   = 0x01
    FA_HIDDEN     = 0x02
    FA_SYSTEM     = 0x04
    FA_LABEL      = 0x08
    FA_DIRECTORY  = 0x10
    FA_ARCHIVE    = 0x20
    FA_LFN        = 0x0f

    # DOS time masks.
    MSK_DAY   = 0x001f  # Range: 1 - 31
    MSK_MONTH = 0x01e0  # Right shift 5, Range: 1 - 12
    MSK_YEAR  = 0xfe00  # Right shift 9, Range: 127 (add 1980 for year).
    MSK_SEC   = 0x001f  # Range: 0 - 29 WARNING: 2 second granularity on this.
    MSK_MIN   = 0x07e0  # Right shift 5, Range: 0 - 59
    MSK_HOUR  = 0xf800  # Right shift 11, Range: 0 - 23

    # AllocationFlags
    AF_NOT_ALLOCATED  = 0x00
    AF_DELETED        = 0xe5
    AF_LFN_LAST       = 0x40
  end # class DirectoryEntry
end # module VirtFS::Fat32
