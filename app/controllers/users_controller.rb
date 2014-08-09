class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  protect_from_forgery with: :null_session   

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    if @user
      render :json => @user.to_json(:methods => :file_url )
    else
      render json: "No existe el usuario", status: :unprocessable_entity
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

    # POST /login_facebook
  def create_facebook
    # Controla si existe el usuario, si existe retorna ok, sino lo crea
    @user = User.where(email: user_params[:email]).first
    if @user
      # Retorna el usuario
      render json: @user
    else
      @user = User.new(user_params)
      @user.login_type = "facebook"
      unless params[:avatar].empty?
        @user.avatar.url = params[:avatar]
      end
      if @user.save
        render json: @user
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    end
  end

    # POST /login_twitter
  def create_twitter
    @user = User.where(email: user_params[:email]).first
    if @user
      # Retorna el usuario
      render json: @user
    else
      @user = User.new(user_params)
      @user.login_type = "twitter"
      unless params[:avatar].empty?
        @user.avatar.url = params[:avatar]
      end
      if @user.save
        render json: @user
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    end
  end

    # POST /register_common
  def create_common
    @user = User.new(user_params)
    @user.login_type = "common"
    if params[:avatar64]
      data = StringIO.new(Base64.decode64(params[:avatar64][:data]))
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = params[:avatar64][:filename]
      data.content_type = params[:avatar64][:content_type] 
      @user.avatar = data
    end
    if @user.save
      render json: @user
    else
      render json: @user.errors, status: :unprocessable_entity 
    end 
  end

  # POST /login_common
  def login_common
    if params[:email] && params[:password]
      @user = User.where(email: params[:email], password: params[:password]).first
      if @user
        render json: @user
      else
        render json: "usuario o contrasena incorrecta", status: :unprocessable_entity 
      end
    else
      render json: "usuario o contrasena incorrecta", status: :unprocessable_entity 
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:username, :email, :first_name, :last_name, :facebook_id, :twitter_id, :city, :country, :password, :avatar)
    end
end
