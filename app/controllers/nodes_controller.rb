class NodesController < ApplicationController
  before_action :set_node, only: [:show, :edit, :update, :destroy, :hide_children, :destroy_file]


  def create
    # get nested children
    @node = Node.create(node_params)
    dup_nodes = Node.where(parent_node: params[:duplicate_child_nodes]).where.not(id: @node.id) if params[:duplicate_child_nodes].present?
    
    duplicate_child_nodes(dup_nodes, @node.id) if dup_nodes.present?
    ActionCable.server.broadcast "web_notifications_channel#{@node.mindmap_id}", message: "This is Message"
    respond_to do |format|
      format.json { render json: {node: @node.to_json}}
      format.html { }
    end
  end

  def update
    @node.update(node_params)
    update_child_nodes_disabelity(Node.where(parent_node: @node.id), @node.is_disabled)
    ActionCable.server.broadcast "web_notifications_channel#{@node.mindmap_id}", message: "This is Message"
    respond_to do |format|
      format.json { render json: {node: @node.to_json}}
      format.html { }
    end
  end

  def destroy
    if @node.destroy
      delete_child_nodes Node.where(parent_node: @node.id)
      ActionCable.server.broadcast "web_notifications_channel#{@node.mindmap_id}", message: "This is Message"
      respond_to do |format|
        format.json { render json: {success: true}}
        format.html { }
      end
    else
      respond_to do |format|
        format.json { render json: {success: false}}
        format.html { }
      end
    end
  end

  def destroy_file
    if @node.node_files.find_by(id: file_params[:id]).purge
      ActionCable.server.broadcast "web_notifications_channel#{@node.mindmap_id}", message: "This is Message"
      respond_to do |format|
        format.json { render json: {success: true}}
        format.html { }
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
    ActionCable.server.broadcast "web_notifications_channel#{@node.mindmap_id}", message: "This is Message"
    respond_to do |format|
      format.json { render json: {success: true}}
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

  def duplicate_child_nodes(nodes, new_parent)
    return if nodes.length == 0

    nodes.each do |nod|
      temp_node = nod.dup
      temp_node.position_x += 50
      temp_node.position_y -= 30
      temp_node.parent_node = new_parent

      temp_node.save

      duplicate_child_nodes(Node.where(parent_node: nod.id), temp_node.id)
    end
  end

  def update_child_nodes_disabelity(nodes, flag)
    return if nodes.length == 0

    nodes.each do |nod|
      update_child_nodes_disabelity(Node.where(parent_node: nod.id), flag)
      nod.update_column('is_disabled', flag)
    end
  end

  def delete_child_nodes nodes
    return if nodes.length == 0

    nodes.each do |nod|
      delete_child_nodes Node.where(parent_node: nod.id)
      nod.destroy
    end
  end

  def set_node
    @node = Node.find_by_id(params[:id])
  end

  def node_params
    params.require(:node).permit(
      :title, 
      :position_x, 
      :position_y, 
      :parent_node, 
      :mindmap_id, 
      :is_disabled, 
      :line_color,
      :description, 
      node_files: []
    )
  end

  def file_params
    params.require(:file).permit(:id, :uri)
  end
end
