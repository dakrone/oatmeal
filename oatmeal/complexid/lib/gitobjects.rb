require 'activerecord'

module Oatmeal
  class Repository < ActiveRecord::Base
    has_many :commits

    attr_reader :url, :user, :project

    def initialize(url, base_dir = File.dirname(__FILE__) + "/../git-storage")
      raise "Git URL invalid" if url.nil?
      m = url.match(/git:\/\/github\.com\/(\w+)\/(.*)\.git/)
      @url = m[0]
      @user = m[1]
      @project = m[2]

      @gitstorage = base_dir
      Dir.mkdir(@gitstorage) unless File.exist?(@gitstorage)

      raise "Error, #{@gitstorage} is not a directory" unless File.directory?(@gitstorage)
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

    def find_files
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
