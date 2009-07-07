require 'active_record'
require 'yaml'

task :default => :migrate

desc "Migrate the database through scripts in db/migrate. Target a specific version through VERSION=x"
task :migrate do
    dbconfig = YAML::load(File.open('db/env.yml'))
    ActiveRecord::Base.colorize_logging = false
    ActiveRecord::Base.establish_connection(dbconfig['development'])
    ActiveRecord::Base.logger = Logger.new(File.open('db/dev.log', 'a'))

    version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
    ActiveRecord::Migrator.migrate('db/migrate', version)
end

desc "Delete the database"
task :dropdb do
    dbconfig = YAML::load(File.open('db/env.yml'))
    File.delete(dbconfig['development']['database'])
end
