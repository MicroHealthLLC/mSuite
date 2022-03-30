class AddFieldsToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :google_recaptcha_site_key, :text
    add_column :settings, :host_url, :text
  end
end
