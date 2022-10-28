require 'json'
class MindmapsController < AuthenticatedController
  #before_action :authenticate_user!, except: [:index, :show, :compute_child_nodes]
  #before_action :set_access_user
  before_action :set_mindmap, only: [:update, :show, :compute_child_nodes, :reset_mindmap, :destroy, :clone_map]
  before_action :verify_password, only: :show
  prepend_before_action :check_password_update, only: :update
  include HistoryConcern, MindmapConcern

  def index; end

  def new
    @mindmap = Mindmap.new(name: "Central Idea")
    respond_to do |format|
      format.json { render json: { mindmap: @mindmap.to_json, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i } }
      format.html { render action: 'index' }
    end
  end

  def create
    @mindmap = Mindmap.new(mindmap_params)
    if @mindmap.save
      render json: { mindmap: @mindmap.to_json, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i }
    else
      render json: { mindmap: @mindmap.to_json, messages: @mindmap.errors.full_messages, errors: @mindmap.errors.to_json }, status: :found
    end
  end

  def update
    update_parent_mindmap() if @mindmap.mm_type == 'pollvote'
    @mindmap.update(mindmap_params)
    message = password_present?
    broadcast_actioncable(@mindmap,message)
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

  def reset_mindmap
    @mindmap.reset_mindmap
    broadcast_actioncable(@mindmap,'Reset mindmap')
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
    del_child_mindmap()
    if check_for_password && @mindmap.destroy
      broadcast_actioncable(@mindmap,'Mindmap Deleted')
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

  def del_child_mindmap
    if @mindmap.mm_type == 'poll' && @mindmap.child
      @child_mind_map = @mindmap.child
      if @child_mind_map && @child_mind_map.destroy
        broadcast_actioncable(@child_mind_map,'Mindmap Deleted')
      end
    end
  end

  def update_parent_mindmap
    broadcast_actioncable(@mindmap.parent,'Vote Received')
  end

  def compute_child_nodes
    respond_to do |format|
      format.json { render json: { success: true, mindmap: @mindmap.compute_child } }
      format.html {}
    end
  end

  def delete_empty_msuite
    fetched_mindmap = Mindmap.find_by(unique_key: params[:unique_key])
    if check_msuite(fetched_mindmap)
      fetched_mindmap.destroy
      broadcast_actioncable(fetched_mindmap,'Mindmap Deleted')
    end
  end

  def clone_map
    msuite_clone = dup_msuite
    if msuite_clone.save
      msuite_clone.stages.set_callback(:create, :before,:set_position) if @mindmap.mm_type == 'kanban'
      render json: { mindmap: msuite_clone.to_json, deleteAfter: ENV['DELETE_AFTER'].to_i, defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i, expDays: ENV['EXP_DAYS'].to_i }
    else
      render json: { mindmap: msuite_clone.to_json, messages: msuite_clone.errors.full_messages, errors: msuite_clone.errors.to_json }, status: :found
    end
  end

  def sendkeys; end

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
      @mindmap = Mindmap.find_by(unique_key: params[:id])
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
        :is_save,
        :parent_id,
        :will_delete_at,
      )
    end

    def check_password_update
      @mindmap = Mindmap.find_by(unique_key: params[:id])
      if params[:mindmap][:password].present?
        unless @mindmap.password.present? && @mindmap.check_password(params[:old_password]) || @mindmap.password.blank?
          render json: { error: "Password Mismatched" }
        else
          session.delete(:mindmap_id)
        end
      end
    end

  def broadcast_actioncable(mindmap,message)
    ActionCable.server.broadcast "web_notifications_channel#{mindmap.id}", message: message, mindmap: mindmap
  end
end
