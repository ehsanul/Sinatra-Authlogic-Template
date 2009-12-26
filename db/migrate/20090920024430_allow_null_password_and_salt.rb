class AllowNullPasswordAndSalt < ActiveRecord::Migration
  def self.up
    change_column :users, :crypted_password, :string, :null => true
    change_column :users, :password_salt, :string, :null => true
  end
  def self.down
    change_column :users, :crypted_password, :string, :null => false
    change_column :users, :password_salt, :string, :null => false
  end
end