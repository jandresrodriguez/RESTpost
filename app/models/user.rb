class User < ActiveRecord::Base

  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed

  has_many :reverse_relationships, foreign_key: "followed_id", class_name:  "Relationship", dependent: :destroy
  has_many :followers, through: :reverse_relationships

  has_many :favorites
  has_many :favorites_posts, through: :favorites, source: :post

  has_many :posts
	
	has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "https://s3-sa-east-1.amazonaws.com/ciudadinvisible/users/avatars/000/000/no-avatar.png"
	validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

	validates :username, presence: true
	validates :first_name, presence: true
	validates :last_name, presence: true
	validates :email,:allow_blank => true, uniqueness: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, on: :create }

	def file_url
    # Concatena la url del host mas la de la imagen
    if url_avatar.nil?
      avatar.url 
    else
      url_avatar.partition('?').first
    end
  end

  def following?(other_user)
    relationships.find_by(followed_id: other_user.id)
  end

  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy
  end

  def followers_quantity
    followers.count
  end

  def followed_quantity
    followed_users.count
  end

  def favorites_quantity
    favorites.count
  end

  def posts_quantity
    posts.count
  end
end
