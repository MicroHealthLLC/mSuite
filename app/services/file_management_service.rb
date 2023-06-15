class FileManagementService
  def initialize(filename, req)
    @filename = filename
    @req = req
  end

  def delete_file
    if @req == 'download'
      node = Node.find_by_title(@filename)
    else
      node = Node.find_by_description(@filename)
    end

    if node
      if node.destroy
        ActionCable.server.broadcast("web_notifications_channel#{node.mindmap_id}", { message: "Node is deleted", node: node })
        return true
      else
        return false
      end
    else
      return false
    end
  end
end
