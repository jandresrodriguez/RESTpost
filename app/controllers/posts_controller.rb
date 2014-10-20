class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  protect_from_forgery with: :null_session   
  skip_before_filter :verify_authenticity_token, :only => [:update, :posts_nearby]

  # GET /posts
  # GET /posts.json
  def index
    @posts = Post.all
    respond_to do |format|
      format.html
      format.json { render :json => @posts.to_json(:include => { :assets => {:only => [:file_file_name, :file_content_type],:methods => :file_url }} , :methods => [:author, :favorites_quantity])}
    end
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
    @post = Post.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render :json => @post.to_json(:include => { :assets => {:only => [:file_file_name, :file_content_type],:methods => :file_url }}, :methods => [:author, :favorites_quantity])}
    end
  end

  # GET /posts/new
  def new
    @post = Post.new
    5.times { @post.assets.build }
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
    5.times { @post.assets.build }
  end

  # POST /posts
  # POST /posts.json
  def create
    begin
      @post = Post.new(post_params)
      if @post.save
        unless params[:post][:category].nil? || params[:post][:category].empty?
          params[:post][:category].each do |category_param|
            category = Category.where(name: category_param).first
            unless category.nil?
              type = PostType.new(post_id: @post.id, category_id: category.id)
              type.save!
            end
          end
        end
        if params[:post][:images]
          params[:post][:images].each do |image|
            asset = Asset.find_by_id(image.to_i)
            @post.assets << asset
            @post.save!
          end
        end
        render json: @post, status: :ok
      else
        render json: @post.errors, status: :unprocessable_entity 
      end
    rescue
      render json: @post.errors, status: :unprocessable_entity 
    end
  end

  # POST /posts_mobile
  # POST /posts.json
  def create_mobile
    begin
      @post = Post.new(post_params)
      if @post.save
        unless params[:post][:category].nil? || params[:post][:category].empty?
          params[:post][:category].each do |category_param|
            category = Category.where(name: category_param).first
            unless category.nil?
              type = PostType.new(post_id: @post.id, category_id: category.id)
              type.save!
            end
          end
        end
        render json: @post
      else
        render json: @post.errors, status: :unprocessable_entity 
       end
    rescue
      render json: @post.errors, status: :unprocessable_entity 
    end
  end


  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    begin
      @post.update(post_params)
      if params[:assets_images]
        params[:assets_images].each { |image|
          # Crea la imagen a partir del data
          data = StringIO.new(Base64.decode64(image[:data]))
          data.class.class_eval { attr_accessor :original_filename, :content_type }
          data.original_filename = image[:filename]
          data.content_type = image[:content_type]
          @post.assets.create(file: data)
        }
      end
      render json: "Post was successfully updated.", status: :ok
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    begin
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      render json: "Post was successfully destroyed.", status: :unprocessable_entity
    end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

  #POST /posts_by_user/:user_id
  def posts_by_user
    if params[:user_id]
      posts = Post.where(user_id: params[:user_id])
      if posts.empty?
        render json: "no posts", status: :unprocessable_entity
      else
        render json: posts.to_json(:methods => :first_image), status: :ok
      end
      
    else
      render json: "error", status: :unprocessable_entity
    end
  end

   #POST /posts_nearby
  def posts_nearby
    begin
      if params[:distance] && params[:latitude] && params[:longitude]
        posts = posts_near(params[:latitude].to_f, params[:longitude].to_f, params[:distance].to_i)
        if posts.empty?
          render json: "empty", status: :unprocessable_entity
        else
          render json: posts, status: :ok
        end
      else
        render json: "error", status: :unprocessable_entity
      end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

   #GET /popular_posts/:n
  def popular_posts
    begin
      votes = Favorite.group(:post_id).count
      if votes.empty?
        render json: "no hay votos", status: :unprocessable_entity
      else
        posts_to_return = popular_posts(votes)
        render json: posts_to_return.to_json(:include => { :assets => {:only => [:file_file_name, :file_content_type],:methods => :file_url }}), status: :ok
      end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

   #GET /followers_posts/:user_id/:n
  def followers_posts
    begin
      if params[:user_id]
        params[:n] ? n=params[:n].to_i : n=10
        followers = User.find_by_id(params[:user_id]).followers.pluck(:id)
        unless followers.nil? || followers.empty?
          posts_to_return = followers_posts(followers,n)
          render json: posts_to_return.to_json(:methods => :first_image), status: :ok
        else
          render json: "no followers", status: :unprocessable_entity
        end
      else
        render json: "wrong params", status: :unprocessable_entity
      end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

  #GET /n_posts/:n
  def n_posts
    begin
      if params[:n]
        n = params[:n].to_i
        posts = last_n_posts(n)
        if posts.empty?
          render json: "empty", status: :unprocessable_entity
        else
          render json: posts, status: :ok
        end
      else
        render json: "error", status: :unprocessable_entity
      end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

  #POST /favorite
  def favorite
    begin
      if params[:user_id] && params[:post_id]
        user = User.find(params[:user_id].to_i)
        post = Post.find(params[:post_id].to_i)
        favorite = Favorite.where(user_id: params[:user_id].to_i, post_id: params[:post_id].to_i)
        if user && post && favorite.empty?
          favorite = Favorite.new({user_id: user.id, post_id: post.id})
          favorite.save!
          render json: "favorite successfully added", status: :ok
        else
          render json: "user/post not exist / favorite already exist", status: :unprocessable_entity
        end
      else
        render json: "error", status: :unprocessable_entity
      end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

  #DELETE /favorite
  def undo_favorite
    begin
      if params[:user_id] && params[:post_id]
        user = User.find(params[:user_id].to_i)
        post = Post.find(params[:post_id].to_i)
        favorite = Favorite.where(user_id: params[:user_id].to_i, post_id: params[:post_id].to_i)
        if user && post && !favorite.empty?
          favorite.first.destroy!
          render json: "favorite successfully deleted", status: :ok
        else
          render json: "user/post not exist / favorite not exist", status: :unprocessable_entity
        end
      else
        render json: "wrong params", status: :unprocessable_entity
      end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

  # POST /upload_assets
  def upload_assets
    begin
      if params[:assets_images]
        # Crea la imagen a partir del data
        data = StringIO.new(Base64.decode64(params[:assets_images][:data]))
        data.class.class_eval { attr_accessor :original_filename, :content_type }
        data.original_filename = params[:assets_images][:filename]
        data.content_type = params[:assets_images][:content_type]
        asset = Asset.new(file: data)
        asset.save!
        render json: asset.to_json(only: :id) , status: :ok 
      else
        render json: "no image attached", status: :unprocessable_entity
      end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

  # POST /assets_mobile/:id
  def assets_mobile
    begin
      @post = Post.find(params[:id].to_i)
      # Asigna los assets
      if params[:assets_attributes]
        params[:assets_attributes].each { |key, photo|
          @post.assets.create(file: photo)
        }
      else
        if params[:assets_images]
          params[:assets_images].each { |image|
            # Crea la imagen a partir del data
            data = StringIO.new(Base64.decode64(image[:data]))
            data.class.class_eval { attr_accessor :original_filename, :content_type }
            data.original_filename = image[:filename]
            data.content_type = image[:content_type]
            
            @post.assets.create(file: data)

          }
        end
      end
      render json: "assets assigned successfully", status: :ok 

    rescue
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  #POST /preferences_posts
  def preferences_posts
    begin
      preferences_posts = []
      if params[:latitude] && params[:longitude] 
        #obtener mas cercanos
        preferences_posts << posts_near(params[:latitude].to_f,params[:longitude].to_f,5)
      end
      if params[:user_id] 
        #obtener posts de tus seguidores
        followers = User.find_by_id(params[:user_id]).followers.pluck(:id)
        unless followers.nil? || followers.empty?
            preferences_posts << followers_posts(followers,n)
        end
      end
      #obtener mas populares
      votes = Favorite.group(:post_id).count
      unless votes.empty?
        preferences_posts << popular_posts(votes)
      end
      #obtener ultimos
      preferences_posts << last_n_posts(10)
      #mezclarlos randomicamente
      if params[:quantity] && params[:quantity] > preferences_posts.size
        preferences_posts.shuffle.take(params[:quantity])
      else
        preferences_posts.shuffle
      end
      #devolver
      if preferences_posts.empty?
        render json: "no hay posts suficientes", status: :unprocessable_entity
      else
        render json: preferences_posts.to_json(:include => { :assets => {:only => [:file_file_name, :file_content_type],:methods => :file_url }} , :methods => :first_image), status: :ok
      end
    rescue
      render json: "error", status: :unprocessable_entity
    end
  end

  #POST /random_tour
  def random_tour
    begin
      if params[:latitude] && params[:longitude] && params[:user_id]
        tour = Tour.new
        tour.user_id = user_id
        tour.save!
        nearby_posts = Post.near([latitude, longitude], 5, :units => :km).first(30)
        posts_to_see_unordered = nearby_posts.shuffle.take(5)
        start_point = closest(params[:latitude],params[:longitude],posts_to_see_unordered)
        posts_to_see_unordered = posts_to_see_unordered.delete(start_point)
        place_tour = PartOfTOur.create(post_id: start_point.id, tour_id: tour.id, order: 1)
        tour.posts << place_tour
        i=2
        while posts_to_see_unordered.size > 0
          closest = closest(start_point.latitude,start_point.longitude,posts_to_see_unordered)
          posts_to_see_unordered = posts_to_see_unordered.delete(closest)
          place_tour = PartOfTOur.create(post_id: start_point.id, tour_id: tour.id, order: i)
          tour.posts << place_tour
          i = i + 1
          start_point = closest
        end
        render json: tour.to_json(include: :posts), status: :ok
      else
        render json: "wrong params", status: :unprocessable_entity
      end
    rescue 
      render json: "error", status: :unprocessable_entity
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def post_params
      params.require(:post).permit(:title, :user_id, :description, :images, :date, :location, :category, :latitude, :longitude, assets_attributes: [:id, :post_id, :file])#, assets_images: [:data, :filename, :content_type]) 
      #params.require(:post).permit!
    end

    def posts_near(latitude,longitude,distance)
      posts = Post.near([latitude, longitude], distance, :units => :km)
      posts
    end

    def popular_posts(votes)
      posts_to_return = []
      popular_posts = []
      params[:n] ? n=params[:n].to_i : n=10
      votes.sort_by{ |k,v| v}.reverse.first(n).each{ |id,votes| popular_posts<<id}
      popular_posts.each do |post_id|
        posts_to_return << Post.find_by_id(post_id)
      end
      posts_to_return
    end

    def followers_posts(followers,n)
      order_followers = []
      popular_followers = Relationship.where(followed_id: followers).group(:followed_id).count
      popular_followers.sort_by{ |k,v| v}.reverse.first(n).each{ |id,followers| order_followers<<id}
      posts_to_return = []
      order_followers.each do |author|
        posts_to_return << Post.where(user_id: author).order("created_at DESC").limit(5)
      end
      posts_to_return
    end

    def last_n_posts(n)
      posts = Post.order("posts.created_at DESC").page(n).per(10)
      posts
    end

    def closest(longitude_start,latitude_start, places)
      min_distance = 100
      near_place_id = nil
      places.each do |place|
        distance = Geocoder::Calculations.distance_between([latitude_start,longitude_start], [place.latitude,place.longitude])
        if distance < min_distance
          min_distance = distance
          near_place_id = place.id
        end
      end
      Post.find_by_id(near_place_id)
    end
end
