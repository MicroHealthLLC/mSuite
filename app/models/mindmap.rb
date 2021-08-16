class Mindmap < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :category, optional: true
  has_many :nodes, dependent: :destroy
  has_many_attached :node_files, dependent: :destroy

  has_many :mindmap_users, dependent: :destroy
  has_many :shared_users, through: :mindmap_users

  before_validation :generate_random_key, on: :create
  validates :unique_key, presence: true, uniqueness: true
  validates :unique_key, length: { in: 10..20 }

  enum status: { active: 0, archived: 1 }
  enum share: { private_link: 0, public_link: 1 }

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

    self.as_json.merge(
      nodes: self.nodes.map(&:to_json),
      attach_files: attach_files,
      editable: editable
    ).as_json
  end

  def compute_child
    center_node = { "id"=> 0, "name"=> self.name, "children"=> [] }
    compute_child_nodes(center_node)
    center_node
  end

  def reset_mindmap
    self.nodes.destroy_all
    self.node_files.map(&:purge)
    self.update_columns(
      name: "Central Idea",
      description: ""
    )
  end

  def editable
    false
  end

  private

  def compute_child_nodes(node)
    node["children"] = self.nodes.where(parent_node: node["id"]).order(export_index: :asc).map(&:as_json)
    node["children"].each{|nod| compute_child_nodes(nod)}
  end

  def generate_random_key
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten
    self.unique_key = (0...15).map { o[rand(o.length)] }.join
  end
end
