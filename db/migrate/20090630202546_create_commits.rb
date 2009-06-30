class CreateCommits < ActiveRecord::Migration
  def self.up
    create_table :commits do |t|
      t.timestamps

      t.column :commitid, :string, :limit => 40, :null => false
      t.column :commitdate, :datetime, :null => false
      t.belongs_to :repository
    end
  end

  def self.down
      drop_table :commits
  end
end
