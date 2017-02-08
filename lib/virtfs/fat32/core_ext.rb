class String
  def UnicodeToUtf8
    dup.force_encoding("UTF-16LE").encode("UTF-8")
  end
end
