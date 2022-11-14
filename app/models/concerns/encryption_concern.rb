module EncryptionConcern
  extend ActiveSupport::Concern

  def encrypt_msuite
    msuite_encrypt_conditions
  end
  
  def encrypt_mindmap_attr
    mindmap_attr_encryption
  end

  def encrypt_node
    node_encrypt_conditions
  end

  def encrypt_stage
    stage_encrypt_conditions
  end
  
  private
    #general encryption method
    def encrypt_attr(value)
      return EncryptionService.encrypt(value)
    end

    #mindmap encryption methods
    def msuite_encrypt_conditions
      return encrypt_all_mindmap_attr if self.changes[:is_save] && self.changes[:is_save][1] == 'is_private'
      encrypt_msuite_attr(self.changes)
    end

    def encrypt_msuite_attr(changes)
      self[:canvas] = encrypt_attr(changes[:canvas][1]) if changes[:canvas]
      self[:title]  = encrypt_attr(changes[:title][1])  if changes[:title]
      self[:name]   = encrypt_attr(changes[:name][1])   if changes[:name]
    end

    def encrypt_all_mindmap_attr
      encrypt_mindmap_nodes unless self.nodes.empty?
      encrypt_mindmap_stages unless self.stages.empty?
      mindmap_attr_encryption
    end

    def mindmap_attr_encryption
      self[:canvas] = encrypt_attr(self[:canvas]) unless self[:canvas].nil?
      self[:title]  = encrypt_attr(self[:title])
      self[:name]   = encrypt_attr(self[:name])
    end

    #node encryption methods
    def encrypt_mindmap_nodes
      self.nodes.each do |node|
        node[:title]       = encrypt_attr(node[:title]) unless node[:title].nil?
        node[:description] = encrypt_attr(node[:description]) unless node[:description].nil?
        node.save
      end
    end

    def node_encrypt_conditions
      unless self.mindmap.changes[:is_save]
        return node_encryption if self.changes[:mindmap_id]
        update_encrypted_nodes 
      end
    end

    def node_encryption
      self[:title]       = encrypt_attr(self[:title]) unless self[:title].nil?
      self[:description] = encrypt_attr(self[:description]) unless self[:description].nil?
    end
    
    def update_encrypted_nodes
      self[:title]       = encrypt_attr(self.changes[:title][1])       if self.changes[:title]
      self[:description] = encrypt_attr(self.changes[:description][1]) if self.changes[:description]
    end
    #stage encryption methods
    def encrypt_mindmap_stages
      self.stages.each do |stage|
        stage[:title]       = encrypt_attr(stage[:title])
        stage[:stage_color] = encrypt_attr(stage[:stage_color])
        stage.save
      end
    end

    def stage_encrypt_conditions
      unless self.mindmap.changes[:is_save]
        return stage_encryption if self.changes[:mindmap_id]
        update_encrypted_stages
      end
    end

    def stage_encryption
      self[:title]       = encrypt_attr(self[:title])
      self[:stage_color] = encrypt_attr(self[:stage_color])
    end

    def update_encrypted_stages
      self[:title]       = encrypt_attr(self.changes[:title][1])       if self.changes[:title]
      self[:stage_color] = encrypt_attr(self.changes[:stage_color][1]) if self.changes[:stage_color]
    end
end  