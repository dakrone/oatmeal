require 'activerecord'
require 'find'

module Oatmeal
  class Repository < ActiveRecord::Base
    has_many :commits

    attr_reader :url, :user, :project, :project_dir

    def initialize(url, base_dir = File.dirname(__FILE__) + "/../git-storage")
      raise "Git URL invalid" if url.nil?
      m = url.match(/git:\/\/github\.com\/(\w+)\/(.*)\.git/)
      @url = m[0]
      @user = m[1]
      @project = m[2]

      @gitstorage = base_dir
      @project_dir = @gitstorage + "/" + @user + "/" + @project
      Dir.mkdir(@gitstorage) unless File.exist?(@gitstorage)

      raise "#{@gitstorage} is not a directory" unless File.directory?(@gitstorage)
      raise "Unable to parse git URL" if (@url.nil? or @user.nil? or @project.nil?)
    end

    def clone(base_dir = @gitstorage)
      user_dir = base_dir + "/" + @user
      FileUtils.rm_rf(user_dir) if File.exist?(user_dir)
      Dir.mkdir(user_dir)

      Dir.chdir(user_dir) do
        system("git clone --quiet #{@url}")
        return nil unless $? == 0
      end
      self
    end

    # Return an array of all globbed files. Glob is checked on _basename_ of a
    # file, not full path
    def find_files(glob = '*.rb')
      files = []
      Find.find(@project_dir) do |path|
        if File.basename(path) =~ /#{glob}/
          puts "Found a file: #{path}"
          files << path
        end
      end
      files
    end

    class Commit < ActiveRecord::Base
      has_many :committedfiles
      belongs_to :repository
    end

    class CommittedFile < ActiveRecord::Base
      belongs_to :repository
    end
  end
end
