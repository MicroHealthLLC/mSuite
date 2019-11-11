class MindmapsController < ApplicationController
  before_action :set_mindmap, only: [:update, :show, :destroy_file]
  
  def index; end

  def new
    @mindmap = Mindmap.new(name: "Central Idea", unique_key: generate_random_key)
    respond_to do |format|
      format.json { render json: {mindmap: @mindmap.to_json}}
      format.html { render action: 'index' }
    end
  end

  def create
    @mindmap = Mindmap.create(mindmap_params)
    respond_to do |format|
      format.json { render json: {mindmap: @mindmap.to_json}}
      format.html { }
    end
  end

  def update
    @mindmap.update(mindmap_params)
    ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: "This is Message"
    respond_to do |format|
      format.json { render json: {mindmap: @mindmap.to_json}}
      format.html { }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: {mindmap: @mindmap.to_json}}
      format.html { render action: 'index' }
    end
  end

  def destroy_nodes
    nodes = params[:nodes]
    nodes.each do |nod| 
      Node.find(nod[:id]).destroy
    end if nodes.present?
    respond_to do |format|
      format.json { render json: {success: true}}
      format.html { }
    end
  end

  def find_or_create
    @mindmap = Mindmap.create_with(name: 'Central Idea').find_or_create_by(unique_key: params[:key])
    respond_to do |format|
      format.json { render json: {success: true, mindmap: @mindmap}}
      format.html { }
    end
  end

  def list_all_maps
    @mindmaps = Mindmap.order('updated_at DESC')
    respond_to do |format|
      format.json { render json: {success: true, mindmaps: @mindmaps}}
      format.html { }
    end
  end

  def destroy_file
    if file = @mindmap.node_files.find_by(id: file_params[:id]) and file.present?
      file.purge
      ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", {message: "Central Node file deleted", file: file}
      respond_to do |format|
        format.json {render json: {success: true}}
        format.html {}
      end
    else
      respond_to do |format|
        format.json {render json: {success: false}}
        format.html {}
      end
    end
  end

  private

  def set_mindmap
    @mindmap = Mindmap.find_by(unique_key: params[:id])
  end

  def mindmap_as_json(mindmap)
    mindmap.as_json.merge(
      nodes: mindmap.nodes.map(&:to_json)
    ).as_json
  end

  def generate_random_key
    o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    string = (0...10).map { o[rand(o.length)] }.join
  end

  def mindmap_params
    params.require(:mindmap).permit(
      :name, 
      :unique_key,
      :description,
      node_files: []
    )
  end

  def file_params
    params.require(:file).permit(:id, :uri)
  end
end
