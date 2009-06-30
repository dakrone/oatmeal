class CreateCommittedFile < ActiveRecord::Migration
  def self.up
    create_table :committedfiles do |t|
      t.timestamps

      t.column :path,       :string, :null => false
      t.column :rate,       :float, :null => false
      t.column :iid,        :float, :null => false
      t.column :entropy1,   :float, :null => false
      t.column :entropy2,   :float, :null => false
      t.column :tokens,     :integer, :null => false

      t.belongs_to :commit
    end
  end

  def self.down
    drop_table :commitedfiles
  end
end
