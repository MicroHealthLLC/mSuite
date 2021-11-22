require 'bcrypt'

class Mindmap < ApplicationRecord
  include ActiveModel::Dirty
  include BCrypt

  belongs_to :user, optional: true
  belongs_to :category, optional: true

  has_many :nodes, dependent: :delete_all
  has_many :stages, dependent: :delete_all

  has_many_attached :node_files, dependent: :destroy

  has_many :mindmap_users, dependent: :destroy
  has_many :shared_users, through: :mindmap_users

  before_validation :generate_random_key, on: :create
  validates :unique_key, presence: true, uniqueness: true
  validates :unique_key, length: { in: 10..20 }
  validates :mm_type, :name, presence: true

  enum status: { active: 0, archived: 1 }
  enum share: { only_me: 0, private_link: 1, public_link: 2 }
  enum mm_type: { simple: 0, kanban: 1, tree_map: 2 }

  cattr_accessor :access_user
  before_update :hash_password, if: :will_save_change_to_password?

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
      editable: true
    ).as_json
  end

  def check_password(password)
    Password.new(self.password) == password
  end

  def compute_child
    center_node = { "id"=> 0, "name"=> self.name, "children"=> [] }
    compute_child_nodes(center_node)
    center_node
  end

  def reset_mindmap
    self.nodes.destroy_all
    self.stages.destroy_all if self.mm_type == 'kanban'
    self.node_files.map(&:purge) if self.mm_type == 'simple'
    self.update_columns(
      name: "Central Idea",
      description: ""
    )
  end

  # def editable?
  #   access_user.try(:admin?) || (user.try(:id) === access_user.try(:id)) || (shared_users.pluck(:user_id).include?(access_user.try(:id)))
  # end

  def hash_password
    self.password = Password.create(self.password)
  end

  private

  def compute_child_nodes(node)
    node["children"] = self.nodes.where(parent_node: node["id"]).order(export_index: :asc).map(&:as_json)
    node["children"].each{ |nod| compute_child_nodes(nod) }
  end

  def generate_random_key
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten
    self.unique_key = (0...15).map { o[rand(o.length)] }.join
  end
end
