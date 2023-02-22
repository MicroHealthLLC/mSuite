require 'bcrypt'

class Mindmap < ApplicationRecord
  include ActiveModel::Dirty
  include BCrypt
  include EncryptionConcern, DecryptionConcern
  include LockoutMsuiteConcern
  
  scope :fileshare_created_before, ->(time_ago) {
    where(mm_type: "fileshare").where("created_at <= ?", time_ago)
  }

  belongs_to :user, optional: true
  belongs_to :category, optional: true

  has_many :nodes, dependent: :destroy
  has_many :stages, dependent: :destroy
  has_many :comments, dependent: :destroy

  has_many_attached :node_files, dependent: :destroy

  has_many :children, class_name: 'Mindmap', foreign_key: 'parent_id', dependent: :destroy
  belongs_to :parent, class_name: 'Mindmap', optional: true
  has_many :mindmap_users, dependent: :destroy
  has_many :shared_users, through: :mindmap_users

  accepts_nested_attributes_for :nodes, update_only: true

  before_validation :generate_random_key, on: :create
  before_validation :set_will_delete_at_date, on: :create
  validates_uniqueness_of :unique_key, uniqueness: true, case_sensitive: false
  validates :unique_key, presence: true
  validates :unique_key, length: { in: 10..20 }
  # validates_uniqueness_of :name, case_sensitive: false, if: Proc.new { |mSuite| mSuite.name != 'Central Idea' } #When Duplicating mindmap the validation was failing as the name of Mindmap was same 
  validates :name, presence: true
  validates :mm_type, presence: true
  
  enum status: { active: 0, archived: 1 }
  enum is_save: { is_public: 0, is_private: 1 }
  enum share: { only_me: 0, private_link: 1, public_link: 2 }
  enum mm_type: { simple: 0, kanban: 1, tree_map: 2, tree_chart: 3, whiteboard: 4, flowmap: 5, todo: 6, Notepad: 7, spreadsheet: 8, calendar: 9, poll: 10, pollvote: 11, venndiagram: 12, presentation: 13, fileshare: 14}

  cattr_accessor :access_user
  before_update :hash_password, if: :will_save_change_to_password?
  after_create  :pre_made_stages, if: :check_kanban
  after_create  :decrypt_attributes, if: :check_private?
  before_create :update_canvas, if: :check_mm_type
  before_create :decrypt_attributes, if: :check_poll_vote
  before_update :encrypt_attributes, if: :check_private?
  before_update :decrypt_attributes, if: :check_is_before_private

  def decrypt_attributes
    decrypt_msuite(self.parent) if check_poll_vote
    decrypt_msuite(self)
  end

  def encrypt_attributes
    encrypt_msuite
  end

  def check_private?
    return true if self.is_private? || self.changes[:is_save]
  end

  def check_poll_vote
    return self.parent && self.parent.is_private?
  end

  def update_canvas
    if check_mm_type
      self.canvas = '{"version":"4.6.0","columns":[], "data":[], "style":{}, "width": []}' unless self.is_private?
    end
  end
  
  def check_mm_type
    return self.mm_type == 'whiteboard' || self.mm_type == 'poll' || self.mm_type == 'Notepad' || self.mm_type == 'spreadsheet'
  end 

  def decrypt_fields
    self.name = EncryptionService.decrypt(name)
    self.title = EncryptionService.decrypt(title)
    self.description = EncryptionService.decrypt(description)
    self.canvas = EncryptionService.decrypt(canvas)
    # add more fields as necessary
  end

  
  def to_json
    decrypt_fields if self.is_private?
    self.as_json.merge(
      nodes: self.nodes.map(&:to_json),
      parent: self.parent,
      stages: self.stages.map(&:to_json),
      editable: true
    ).as_json
  end

  def check_validate(session_m_id, psw_check)
    is_verified = true
    if self.password.present? && session_m_id == self.unique_key + self.password
      unlock_msuite
      return [is_verified, session_m_id]
    elsif self && self.password.present?
      if psw_check.present?
        is_verified  = self.check_password(psw_check)
        session_m_id = self.unique_key + self.password if is_verified
        lock_msuite if !is_verified
      else
        is_verified = false
      end
    end
    return [is_verified, session_m_id]
  end

  def check_kanban
    return self.mm_type == 'kanban' && !self.is_private?
  end

  def check_password(password)
    Password.new(self.password) == password if password
  end

  def compute_child
    center_node = { "id"=> 0, "name"=> self.name, "children"=> [] }
    compute_child_nodes(center_node)
    center_node
  end

  def pre_made_stages
    self.stages.create([{title:'TO DO'},{title:'IN PROGRESS'},{title:'DONE'}])
  end

  def reset_mindmap
    self.nodes.destroy_all
    self.stages.destroy_all
    self.children.destroy_all
    self.node_files.map(&:purge)
    self.assign_attributes(
      name: "Central Idea",
      title: "Title",
      description: "",
      line_color: "#B3FAFF",
      canvas: '{"version":"4.6.0","columns":[], "data":[], "style":{}, "width": []}'
    )
    self.save
  end

  # def editable?
  #   access_user.try(:admin?) || (user.try(:id) === access_user.try(:id)) || (shared_users.pluck(:user_id).include?(access_user.try(:id)))
  # end

  def hash_password
    if self.password.present?
      self.password = Password.create(self.password) 
      self.is_save = "is_private"
    end
    # self.will_delete_at = ENV['DELETE_AFTER'].to_i.days.from_now if (self.will_delete_at == ENV['EXP_DAYS'].to_i.days.from_now.to_date)
  end

  def password_check
    self.update(password: nil) if self.is_save == "is_public" && self.password != nil
  end

  private

  def compute_child_nodes(node)
    node["children"] = self.nodes.where(parent_node: node["id"]).order(export_index: :asc).map(&:as_json)
    node["children"].each{ |nod| compute_child_nodes(nod) }
  end

  def set_will_delete_at_date
    self.will_delete_at = ENV['EXP_DAYS'].to_i.days.from_now
  end

  def generate_random_key
    if self.mm_type == 'pollvote' && self.name != "Central Idea"
      self.name = self.name.rstrip
      self.name = self.name.strip
      self.unique_key = self.name.squeeze(" ").gsub(/[[:space:]]/, '-')
    else
      o = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten
      self.unique_key = (0...15).map { o[rand(o.length)] }.join
    end
  end
end
