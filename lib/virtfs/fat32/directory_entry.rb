module VirtFS::Fat32
  class DirectoryEntry
    attr_accessor :buffer, :dir_entry, :name, :unused

    attr_accessor :dirty, :parent_cluster, :parent_offset

    def initialize(buffer=nil)
      return create if buffer.nil?
      self.buffer = buffer
      #validate_checksum!
      gen_name
    end

    def dirty!
      self.dirty = true
    end

    def clean!
      self.dirty = false
    end

    def create
      dirty!
      now_hms, now_day = to_dos_time(Time.now)
      self.dir_entry = { 'name'       => 'FILENAMEEXT',
                         'attributes' => FA_ARCHIVE,
                         'ctime_tos'  => 0,
                         'ctime_hms'  => now_hms,
                         'ctime_day'  => now_day,
                         'atime_day'  => now_day,
                         'mtime_hms'  => now_hms,
                         'mtime_day'  => now_day }
      self.magic         = 0
      self.length        = 0
      self.first_cluster = 0
      self
    end

    def dir_entry
      @dir_entry.nil? ? lfn_entries : @dir_entry
    end

    def atime
      @atime ||= from_dos_time(dir_entry['atime_day'], 0)
    end

    def ctime
      @ctime ||= from_dos_time(dir_entry['ctime_day'], dir_entry['ctime_hms'])
    end

    def mtime
      @mtime ||= from_dos_time(dir_entry['mtime_day'], dir_entry['mtime_hms'])
    end

    def checksum
      @checksum ||= dir_entry['checksum']
    end

    def calc_checksum
      name = dir_entry['name']
      csum = 0
      0.upto(10) {|i|
        n = i > (name.size-1) ? 0 : name[i].ord
        csum = ((csum & 1 == 1 ? 0x80 : 0) + (csum >> 1) + n) & 0xff
      }
      csum
    end

    def validate_checksum!
      raise "checksum error" if checksum != calc_checksum
    end

    def magic=(magic)
      dirty!
      dir_entry['reserved1'] = magic
    end

    def magic
      dir_entry['reserved1']
    end

    def length=(len)
      dirty!
      dir_entry['file_size'] = len
    end

    def length
      @length ||= dir_entry['file_size']
    end

    def first_cluster=(cluster)
      dirty!
      dir_entry['first_clus_hi'] = (cluster >> 16)
      dir_entry['first_clus_lo'] = (cluster  & 0xffff)
    end

    def set_attribute(attrib, set = true)
      dirty!
      if set
        dir_entry['attributes'] |= attrib
      else
        dir_entry['attributes'] &= (~attrib)
      end
    end

    def attributes
      @attributes ||= dir_entry['attributes']
    end

    def zero_time!
      dirty!
      dir_entry['atime_day'] = 0
      dir_entry['ctime_tos'] = 0
      dir_entry['ctime_hms'] = 0
      dir_entry['ctime_day'] = 0
      dir_entry['mtime_hms'] = 0
      dir_entry['mtime_day'] = 0
    end

    def unused_io
      StringIO.new(unused)
    end

    def self.lfn_fa?(attributes)
      attributes == FA_LFN
    end

    def lfn_fa?(attributes)
      self.class.lfn_fa?(attributes)
    end

    def dir?
      (attributes & FA_DIRECTORY) != 0
    end

    def file?
      (attributes & FA_DIRECTORY) == 0
    end

    def self.lfn_last?(flags)
      flags & AF_LFN_LAST == AF_LFN_LAST
    end

    def self.lfn_ignore?(seq_num)
      seq_num == AF_DELETED || seq_num == AF_NOT_ALLOCATED
    end

    def lfn_ignore?(seq_num)
      self.class.lfn_ignore?(seq_num)
    end

    def self.skip?(flags)
      flags == AF_DELETED
    end

    def self.stop?(flags)
      flags == AF_NOT_ALLOCATED
    end

    def lfn_entries
      @lfn_entries ||= begin
        self.name = ''
        data      = StringIO.new(buffer)
        checksum  = nil

        entries = []
        loop do
          entry = data.read(DIR_ENT_SIZE)
          if entry.nil?
            self.unused = ""
            return
          end

          entry      = entry.unpack('C*')
          lfn_fa     = lfn_fa?(entry[ATTRIB_OFFSET])
          dir_entry  = lfn_fa ? DIR_ENT_LFN.decode(buffer) : DIR_ENT_SFN.decode(buffer)
          lfn_ignore = lfn_ignore?(dir_entry['seq_num'])

          if !lfn_fa
            self.dir_entry = dir_entry
            break

          elsif lfn_ignore
            self.name   = dir_entry['seq_num']
            self.unused = data.read
            break

          elsif (checksum ||= dir_entry['checksum']) != dir_entry['checksum']
            raise "checksum mismatch"

          end

          entries << dir_entry
          self.name = entry_long_name(dir_entry) + self.name
        end

        self.unused = data.read
        entries
      end
    end

    def entry_long_name(dir_entry)
      %w(name name2 name3).collect {|name|
        next if dir_entry[name].nil?
        dir_entry[name].gsub(/\d377/, "").UnicodeToUtf8.gsub(/\d000/, "") # ?
      }.join
    end

    def short_name
      @short_name ||= begin
        name = dir_entry['name'][0, 8].strip
        ext  = dir_entry['name'][8, 3].strip
        ext.empty? ? name : (name + "." + ext)
      end
    end

    def long_name
      @long_name ||= lfn_entries.reverse.collect { |entry| entry_long_name(dir_entry) }.join
    end

    def gen_name
      self.name = short_name if !dir_entry.nil? && !dir_entry['name'].empty? && (name.nil? || name == "")
    end

    def to_dos_time(tim)
      # Time
      sec      = tim.sec;
      sec     -= 1 if sec == 60 #correction for possible leap second.
      sec      = (sec / 2).to_i #dos granularity is 2sec.
      min      = tim.min;
      hour     = tim.hour
      dos_time = (hour << 11) + (min << 5) + sec

      # Day
      day      = tim.day
      month    = tim.month
      # NOTE: This fails after 2107.
      year     = tim.year - 1980 # DOS year epoc is 1980.
      dos_day  = (year << 9) + (month << 5) + day

      return dos_time, dos_day
    end

    def from_dos_time(dos_day, dos_time)
      # Extract d,m,y,s,m,h & range check.
      day = dos_day & MSK_DAY
      day = 1 if day == 0

      month = (dos_day & MSK_MONTH) >> 5
      month = 1 if month == 0
      month = month.modulo(12) if month > 12

      year = ((dos_day & MSK_YEAR) >> 9) + 1980 #DOS year epoc is 1980.

      # Extract seconds, range check & expand granularity.
      sec  = (dos_time & MSK_SEC)
      sec  = sec.modulo(29) if sec > 29
      sec *= 2

      min  = (dos_time & MSK_MIN) >> 5
      min  = min.modulo(59) if min > 59

      hour = (dos_time & MSK_HOUR) >> 11
      hour = hour.modulo(23) if hour > 23

      # Make a Ruby time.
      return Time.mktime(year, month, day, hour, min, sec)
    end
  end # class DirectoryEntry
end # module VirtFS::Fat32
