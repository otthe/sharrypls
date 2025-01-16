module Sharry
  class Folder
    def self.get_files_from_folder(dir)
      Dir.entries(dir)
    end
  end
end