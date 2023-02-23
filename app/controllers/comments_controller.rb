class CommentsController < AuthenticatedController
  before_action :set_comment, only: [:update, :destroy]
  before_action :set_mindmap

  def create
    @comment = Comment.create(comment_params)
    ActionCable.server.broadcast( "web_comments_channel#{@comment.mindmap.id}", {message: "Comment Created", comment: @comment})
    respond_to do |format|
      format.json { render json: {comment: @comment} }
      format.html { }
    end
  end

  def update
    if @comment.update(comment_params)
      ActionCable.server.broadcast( "web_comments_channel#{@comment.mindmap.id}", {message: "Comment Updated", comment: @comment})
      respond_to do |format|
        format.json { render json: {comment: @comment} }
        format.html { }
      end
    end
  end

  def index
    @comments = Comment.where(mindmap_id: params[:mindmap_id])
    respond_to do |format|
      format.json { render json: {comments: @comments} }
      format.html { }
    end
  end

  def destroy
    if @comment.destroy
      delete_child_comments Comment.where(parent_comment: @comment.id)
      ActionCable.server.broadcast( "web_comments_channel#{@comment.mindmap.id}", {message: "Comment Deleted", comment: @comment} )
      respond_to do |format|
        format.json { render json: {success: true} }
        format.html { }
      end
    else
      respond_to do |format|
        format.json { render json: {success: false} }
        format.html { }
      end
    end
  end

  private

  def set_mindmap
    @mindmap = Mindmap.find_by_id(params[:mindmap_id])
  end

  def set_comment
    @comment = Comment.find_by_id(params[:id])
  end

  def delete_child_comments comments
    return if comments.length == 0

    comments.each do |com|
      delete_child_comments Comment.where(parent_comment: com.id)
      com.destroy
    end
  end
  def comment_params
    params.require(:comment).permit(
      :message,
      :feedback,
      :status,
      :parent_comment,
      :user_name,
      :mindmap_id
    )
  end
end
