require 'json'
require 'document.rb'
class MindmapsController < AuthenticatedController
  cattr_accessor :documents
  self.documents ||= {counter: 0}

  #before_action :authenticate_user!, except: [:index, :show, :compute_child_nodes]
  #before_action :set_access_user
  before_action :set_mindmap, only: [:update, :show, :destroy_file, :compute_child_nodes, :reset_mindmap, :destroy]
  before_action :verify_password, only: :show
  before_action :check_password_update, only: :update
  include HistoryConcern

  def index; end

  def new
    @mindmap = Mindmap.new(name: "Central Idea")
    if @mindmap.mm_type == "Notepad"
      @@documents[@mindmap.unique_key] = Document.new
    end

    respond_to do |format|
      format.json { render json: { mindmap: @mindmap.to_json, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i } }
      format.html { render action: 'index' }
    end
  end

  def create
    @mindmap = Mindmap.new(mindmap_params)
    if @mindmap.mm_type == "Notepad"
      @@documents[@mindmap.unique_key] = Document.new
    end

    if @mindmap.save
      render json: { mindmap: @mindmap.to_json, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i }
    else
      render json: { mindmap: @mindmap.to_json, messages: @mindmap.errors.full_messages, errors: @mindmap.errors.to_json }, status: :found
    end
  end

  def update
    if @mindmap.mm_type == "Notepad"
      ops = JSON.parse(mindmap_params["canvas"])
      document = @@documents[@mindmap.unique_key]
      for op in ops do
        document.merge(op)
      end
      message = password_present?
      @mindmap[:canvas] = ops.to_json
      ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: message, mindmap: @mindmap
      mindmap_params[:canvas] = document.text
      p "\n\nCurrent text for #{@mindmap.unique_key}: #{document.text}"
      @mindmap.update({canvas: document.operations.to_json})
    else
      @mindmap.update(mindmap_params)
      message = password_present?
      ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: message, mindmap: @mindmap
    end
    render json: { mindmap: @mindmap.to_json, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i }
  end

  def show
    if @mindmap
      respond_to do |format|
        format.json { render json: { mindmap: @mindmap.to_json, is_verified: @is_verified, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i } }
        format.html { render action: 'index' }
      end
    else
      respond_to do |format|
        format.json { render json: { error: 'The file you were working on was deleted by a user.' } }
        format.html { redirect_to error_404_path }
      end
    end
  end

  def destroy_nodes
    nodes = params[:nodes]
    nodes.each do |nod|
      Node.find(nod[:id]).destroy
    end if nodes.present?
    respond_to do |format|
      format.json { render json: { success: true } }
      format.html {}
    end
  end

  def find_or_create
    @mindmap = Mindmap.create_with(name: 'Central Idea').find_or_create_by(unique_key: params[:key])
    respond_to do |format|
      format.json { render json: { success: true, mindmap: @mindmap, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i } }
      format.html {}
    end
  end

  def list_all_maps
    @mindmaps = Mindmap.order('updated_at DESC')
    respond_to do |format|
      format.json { render json: { success: true, mindmaps: @mindmaps, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i } }
      format.html {}
    end
  end

  def destroy_file
    if file = @mindmap.node_files.find_by(id: file_params[:id]) and file.present?
      file.purge
      ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", { message: "Central Node file deleted", file: file }
      respond_to do |format|
        format.json { render json: { success: true } }
        format.html {}
      end
    else
      respond_to do |format|
        format.json { render json: { success: false } }
        format.html {}
      end
    end
  end

  def reset_mindmap
    @mindmap.reset_mindmap
    ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: "Reset mindmap", mindmap: @mindmap
    render json: { success: true, mindmap: @mindmap }
  end

  def undo_mindmap
    undoNode = params[:undoNode]
    unless undoNode.empty?
      myNode = undo_my_node(undoNode)
      if myNode
        ActionCable.server.broadcast "web_notifications_channel#{myNode[:mindmap_id]}", message: "undo mindmap", node: myNode
        render json: { success: true, node: myNode }
      end
    end
  end

  def redo_mindmap
    redoNode = params[:redoNode]
    myNode = redo_my_node(redoNode)
    if myNode
      ActionCable.server.broadcast "web_notifications_channel#{myNode[:mindmap_id]}", message: "redo mindmap", node: myNode
      render json: { success: true, node: myNode }
    end
  end

  def destroy
    if check_for_password && @mindmap.destroy
      ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: "Mindmap Deleted", mindmap: @mindmap
      respond_to do |format|
        format.json { render json: { success: true } }
        format.html {}
      end
    else
      respond_to do |format|
        format.json { render json: { success: false } }
        format.html {}
      end
    end
  end

  def compute_child_nodes
    respond_to do |format|
      format.json { render json: { success: true, mindmap: @mindmap.compute_child } }
      format.html {}
    end
  end

  def delete_empty_msuite
    fetched_mindmap = Mindmap.find_by(unique_key: params[:unique_key])
    if fetched_mindmap.nodes.empty? && fetched_mindmap.comments.empty?  && fetched_mindmap.title == "Title" && fetched_mindmap.name == "Central Idea" && fetched_mindmap.will_delete_at == Date.today+ENV['EXP_DAYS'].to_i.day && fetched_mindmap.password.nil? && (fetched_mindmap.canvas.nil? || fetched_mindmap.canvas == '{"version":"4.6.0","data":[], "style":{}, "width": []}' || fetched_mindmap.canvas == "{\"version\":\"4.6.0\",\"objects\":[]}")
      if fetched_mindmap.mm_type =="kanban" &&
        fetched_mindmap.stages.count == 3 && 
        fetched_mindmap.stages[0][:title] == "TO DO" &&
        fetched_mindmap.stages[0][:stage_color] == "#ebecf0" &&
        fetched_mindmap.stages[1][:title] == "IN PROGRESS" &&  
        fetched_mindmap.stages[1][:stage_color] == "#ebecf0" &&
        fetched_mindmap.stages[2][:title] == "DONE"
        fetched_mindmap.stages[2][:stage_color] == "#ebecf0" &&

        fetched_mindmap.destroy
        ActionCable.server.broadcast "web_notifications_channel#{fetched_mindmap.id}", message: "Mindmap Deleted", mindmap: fetched_mindmap
      elsif fetched_mindmap.mm_type !="kanban"
        ActionCable.server.broadcast "web_notifications_channel#{fetched_mindmap.id}", message: "Mindmap Deleted", mindmap: fetched_mindmap
        fetched_mindmap.destroy
      end
    end  
  end

  private

    def set_access_user
      Mindmap.access_user = current_user
    end

    def password_present?
      message = "Mindmap Updated"
      if params[:mindmap][:password].present?
        message              = "Password Updated"
        session[:mindmap_id] = @mindmap.unique_key + @mindmap.password
      end
      return message
    end

    def set_mindmap
      @@documents[:counter] += 1
      @mindmap = Mindmap.find_by(unique_key: params[:id])
      if @@documents[params[:id]].nil?
        @@documents[params[:id]] = Document.new
        if !@mindmap.nil?
          if !@mindmap[:canvas].nil?
            document = @@documents[params[:id]]
            ops = JSON.parse(@mindmap[:canvas])
            for op in ops do
              document.merge(op)
            end
          end
        end
      end
      updateMindmap if @mindmap
    end

    def updateMindmap
      in_active_days = @mindmap.will_delete_at.mjd - @mindmap.updated_at.to_date.mjd
      @mindmap.update(will_delete_at: in_active_days.days.from_now)
    end

    def verify_password
      @is_verified = true
      if @mindmap && @mindmap.password.present? && session[:mindmap_id] == @mindmap.unique_key + @mindmap.password
        return
      elsif @mindmap && @mindmap.password.present?
        if params[:password_check].present?
          @is_verified         = @mindmap.check_password(params[:password_check])
          session[:mindmap_id] = @mindmap.unique_key + @mindmap.password if @is_verified
        else
          @is_verified = false
        end
      end
    end

    def check_for_password
      verfied_delete = false
      if @mindmap.password.blank?
        verfied_delete = true
      elsif params[:password_check] && @mindmap.password.present?
        verfied_delete = @mindmap.check_password(params[:password_check])
      end
      verfied_delete
    end

    def check_auth
      return if current_user.try(:admin?)
      if @mindmap.only_me? && current_user.try(:id) != @mindmap.user.try(:id)
        return redirect_to root_path
      elsif @mindmap.private_link? && !@mindmap.shared_users.include?(current_user)
        return redirect_to root_path
      end
    end

    def mindmap_params
      params.require(:mindmap).permit(
        :name,
        :mm_type,
        :description,
        :password,
        :line_color,
        :image,
        :canvas,
        :title,
        :will_delete_at,
        node_files: []
      )
    end

    def file_params
      params.require(:file).permit(:id, :uri)
    end

    def check_password_update
      if params[:mindmap][:password].present?
        unless @mindmap.password.present? && @mindmap.check_password(params[:mindmap][:old_password]) || @mindmap.password.blank?
          respond_to do |format|
            format.json { render json: { error: "Password Mismatched" } }
          end
        else
          session.delete(:mindmap_id)
        end
      end
    end
end
