class Node < ApplicationRecord
  belongs_to :mindmap, optional: true
  has_many_attached :node_files

  def to_json
    attach_files = []
    if self.node_files.attached?
      attach_files = self.node_files.map do |file| 
        {
          id: file.id, 
          uri: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
        }
      end
    end
    self.as_json.merge(attach_files: attach_files).as_json
  end
end
