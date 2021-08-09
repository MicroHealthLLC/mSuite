class CreateSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :settings do |t|
      t.text :office365_key
      t.text :office365_secret
      t.text :google_oauth_key
      t.text :google_oauth_secret
      t.timestamps
    end
  end
end
