class Settings < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :public_url, :string
    add_column :settings, :about_url, :string
    add_column :settings, :terms_url, :string
    add_column :settings, :privacy_url, :string
  end
end
