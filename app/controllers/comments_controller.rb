class CommentsController < ApplicationController
  before_action :set_comment, only: [:show, :edit, :update, :destroy]  
  protect_from_forgery with: :null_session   
  skip_before_filter :verify_authenticity_token

  # GET /comments
  # GET /comments.json
  def index
    @comments = Comment.all
    render :json => @comments.to_json(:include => [:post, :user]), status: :ok
  end

  # GET /comments/1
  # GET /comments/1.json
  def show
    @comment = Comment.find(params[:id])
    render :json => @comment.to_json(:include => [:post, :user]), status: :ok
  end

  # GET /comments/new
  def new
    @comment = Comment.new
  end

  # GET /comments/1/edit
  def edit
  end

  # POST /comments
  def create
    begin
      @comment = Comment.new(comment_params)
      if @comment.save
        puts "------- DEBUGGING -------"
        puts "#{@comment}"
        puts "-------------------------"
        puts "1"
        notification = Notification.new(creator_id: @comment.user.id, receiver_id: @comment.post.user.id, post_id: @comment.post.id, notification_type: "Comment")
        puts "2"
        notification.set_notification_data()
        puts "3"
        Notifier.send_notification(notification)
        puts "4"
        render json: "comment created successfully", status: :ok
      else
        puts "5"
        render json: @comment.errors, status: :unprocessable_entity
      end
    rescue 
      puts "7"
      render json: @comment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to @comment, notice: 'Comment was successfully updated.' }
        format.json { render :show, status: :ok, location: @comment }
      else
        format.html { render :edit }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to comments_url, notice: 'Comment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def comment_params
      params.require(:comment).permit(:post_id, :user_id, :text, :likes)
    end
end
