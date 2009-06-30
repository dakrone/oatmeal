class CreateCommitedFile < ActiveRecord::Migration
  def self.up
    create_table :commitedfiles do |t|
      t.timestamps

      t.column :path, :string, :null => false
      t.column :bits, :float, :null => false
      t.column :tokens, :integer, :null => false
      t.column :types, :integer, :null => false

      t.belongs_to :commit
    end
  end

  def self.down
    drop_table :commitedfiles
  end
end
