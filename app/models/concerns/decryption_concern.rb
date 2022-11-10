module DecryptionConcern
  extend ActiveSupport::Concern
  
  def decrypt_msuite(msuite)
    mindmap_decryption(msuite)
  end

  def decrypt_mindmap_attr
    attr = decrypt_node(self)   if  self.class == Node
    attr = decrypt_stage(self)  if  self.class == Stage
    attr
  end

  def check_is_before_private
    return true if self.changes[:is_save] && self.changes[:is_save][0] == 'is_private' && self.changes[:is_save][1] == 'is_public'
  end

  private
  
    def decrypt_mindmap_nodes(msuite)
      msuite.nodes.each do |node|
        node[:title]       = decrypt_attr(node[:title])
        node[:description] = decrypt_attr(node[:description])
        node.save if check_is_before_private
      end
    end
    
    def mindmap_decryption(msuite)
      msuite[:name]   = decrypt_attr(msuite[:name])    
      msuite[:title]  = decrypt_attr(msuite[:title])  
      msuite[:canvas] = decrypt_attr(msuite[:canvas]) unless msuite[:canvas].nil?
      decrypt_mindmap_nodes(msuite) unless msuite.nodes.empty?
      decrypt_mindmap_stages(msuite.stages) unless msuite.stages.empty?
      msuite
    end

    def decrypt_node(node)
      node[:title]       = decrypt_attr(node[:title])
      node[:description] = decrypt_attr(node[:description])
      node
    end

    def decrypt_stage(stage)
      stage[:title]       = decrypt_attr(stage[:title])
      stage[:stage_color] = decrypt_attr(stage[:stage_color])
      stage
    end

    def decrypt_mindmap_stages(stages)
      stages.each do |stage|
        stage[:title]       = decrypt_attr(stage[:title])
        stage[:stage_color] = decrypt_attr(stage[:stage_color])
        stage.save if check_is_before_private
      end
    end

    def decrypt_attr(value)
      EncryptionService.decrypt(value)
    end
end
