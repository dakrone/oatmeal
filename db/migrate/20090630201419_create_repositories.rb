class CreateRepositories < ActiveRecord::Migration
  def self.up
    create_table :repositories do |t|
      t.timestamps

      t.column :giturl, :string, :null => false
      t.column :shortname, :string
    end
  end

  def self.down
    drop_table :repositories
  end
end
