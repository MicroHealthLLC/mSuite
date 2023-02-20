class NodesController < AuthenticatedController
  include NodeConcern
  before_action :set_node, only: [:update, :destroy, :hide_children, :update_export_order, :update_all_colors]
  before_action :set_mSuite, only: [:index]
  $deleted_child_nodes = []

  def create
    # get nested children
    @node = Node.new(node_params)
    @node.save
    @node = @node.decryption
    update_node_parent(@node) if @node.mindmap.mm_type == 'todo'
    duplicate_child_nodes if params[:duplicate_child_nodes].present?
    ActionCable.server.broadcast( "web_notifications_channel#{@node.mindmap_id}", { message: "Node is created", node: @node } )
    respond_to do |format|
      format.json { render json: {node: @node}}
      format.html { }
    end
  end

  def update
    previous_title = @node.title
    previous_title = EncryptionService.decrypt(previous_title) if @node.mindmap.is_private?
    @node.update(update_node_params)
    update_node_parent(@node) if @node.mindmap.mm_type == 'todo' && params[:node][:title] == previous_title
    @node = @node.decryption
    update_worker(@node) if @node.mindmap.mm_type == 'calendar' || @node.mindmap.mm_type == 'todo'
    ActionCable.server.broadcast( "web_notifications_channel#{@node.mindmap_id}", { message: "Node is updated", node: @node} )
    respond_to do |format|
      format.json { render json: {node: @node}}
      format.html { }
    end
  end

  def index
    @nodes = @mindmap.nodes.map(&:decryption)
    respond_to do |format|
      format.json { render json: {nodes: @nodes.map(&:to_json)}}
      format.html { }
    end
  end

  def destroy
    if @node
      delNodes = []
      delNodes = delete_child_nodes @node.children if @node.children
      delNodes = @node if @node.mindmap.mm_type == 'calendar'
      $deleted_child_nodes = []
      update_node_parent(@node) if @node.mindmap.mm_type == 'todo'
      del_worker(@node) if @node.mindmap.mm_type == 'calendar' || @node.mindmap.mm_type == 'todo'
      if @node.destroy
        ActionCable.server.broadcast( "web_notifications_channel#{@node.mindmap_id}", { message: "Node is deleted", node: @node })
        respond_to do |format|
          format.json { render json: {success: true, node: delNodes}}
          format.html { }
        end
      end
    else
      respond_to do |format|
        format.json { render json: {success: false}}
        format.html { }
      end
    end
  end

  def hide_children
    @flag = params[:flag]
    @node.update_column('hide_children', @flag)
    hide_show_nested_children(Node.where(parent_node: @node.id))
    ActionCable.server.broadcast( "web_notifications_channel#{@node.mindmap_id}", { message: "Node is updated", node: @node, mindmap: @mindmap})
    respond_to do |format|
      format.json { render json: {success: true, node: @node}}
      format.html { }
    end
  end

  def update_export_order
    # will broadcast the message 'export order changed'
    @node.update_export_order(params[:old_index], params[:new_index])
    respond_to do |format|
      format.json { render json: {success: true}}
      format.html { }
    end
  end

  def update_all_colors
    @node.update_all_colors(params[:line_color])
    ActionCable.server.broadcast( "web_notifications_channel#{@node.mindmap_id}", { message: "Node is updated", node: @node, mindmap: @mindmap})
    respond_to do |format|
      format.json { render json: {success: true, node: @node}}
      format.html { }
    end
  end

  private

  def hide_show_nested_children(nodes)
    return if nodes.length == 0
    nodes.each do |nod|
      nod.update_column('hide_self', @flag)
      unless nod.hide_children == true
        hide_show_nested_children(Node.where(parent_node: nod.id))
      end
    end
  end

  def delete_child_nodes nodes
    nodes.each do |nod|
      delete_child_nodes nod.children unless nod.children.empty?
      $deleted_child_nodes.push(nod)
    end
    return $deleted_child_nodes
  end

  def set_node
    @node = Node.find_by_id(params[:id])
    set_mindmap if @node
  end

  def set_mindmap
    @mindmap = @node.mindmap
  end

  def set_mSuite
    @mindmap = Mindmap.find_by_id(params[:mindmap_id])
  end

  def update_node_params
    params.require(:node).permit(
      :id,
      :title,
      :position_x,
      :position_y,
      :parent_node,
      :stage_id,
      :mindmap_id,
      :is_disabled,
      :line_color,
      :hide_children,
      :description,
      :position,
      :node_width,
      :duedate,
      :startdate,
      :element_type,
      :element_width,
      :element_height,
      node_files: []
    )
  end

  def node_params
    params.require(:node).permit(
      :title,
      :position_x,
      :position_y,
      :parent_node,
      :stage_id,
      :mindmap_id,
      :is_disabled,
      :hide_children,
      :line_color,
      :description,
      :position,
      :node_width,
      :startdate,
      :duedate,
      :hide_self,
      :element_type,
      :element_width,
      :element_height,
      node_files: []
    )
  end

end
