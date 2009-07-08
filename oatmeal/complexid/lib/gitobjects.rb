require 'activerecord'

module Oatmeal
  class Repository < ActiveRecord::Base
    attr_reader :url, :user, :project

    def initialize(url)
      raise "Git URL invalid" if url.nil?
      m = url.match(/git:\/\/github\.com\/(\w+)\/(.*)\.git/)
      @url = m[0]
      @user = m[1]
      @project = m[2]
      raise "Unable to parse git URL" if (@url.nil? or @user.nil? or @project.nil?)
    end

    def clone(base_dir)
      user_dir = base_dir + "/" + @user
      FileUtils.rm_rf(user_dir) if File.exist?(user_dir)
      Dir.mkdir(user_dir)

      Dir.chdir(user_dir) do
        system("git clone --quiet #{@url}")
        return nil unless $? == 0
      end
      self
    end
  end

  class Commit < ActiveRecord::Base
  end

  class CommittedFile < ActiveRecord::Base
  end
end
