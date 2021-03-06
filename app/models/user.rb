class User < ActiveRecord::Base
  attr_accessor :password
  attr_accessible :email, :name, :password, :avatar, :avatar_cache, :remove_avatar
  
  mount_uploader :avatar, AvatarUploader
    
  validates :password, presence: true, if: "hashed_password.blank?"
  
  validates :name, presence: true,
                      length: { minimum: 4, maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true,
                        format: { with: VALID_EMAIL_REGEX },
                      uniqueness: { case_sensitive: false }
  
  has_many :micro_posts
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed

  before_save :encrypt_password
                
  def encrypt_password
    self.salt ||= Digest::SHA256.hexdigest("--#{Time.now.to_s}- -#{email}--")
    self.hashed_password = encrypt(password)
  end

  def encrypt(raw_password)
    Digest::SHA256.hexdigest("--#{salt}--#{raw_password}--")
  end
  
  # This function takes an email (as a string) and the plain_text_password
  # (as the user would have typed it in a web form), and should return:
  #   * if the email doesn't exist in the database, or the password given
  #     does not match the password for the given user, return nil
  #   * if the user with the given email has the password provided,
  #     return that user.
  # 
  # You may wish to review the slides from lecture_3, which have references
  # to using the "find" functions provided by active record so that you
  # can locate the correct user in the database.
  # def self.authenticate(email, plain_text_password)
	# user = find_by_email(email)
	# return user if user && user.authenticate(plain_text_password)
  # end
  # def authenticate(password)
	# self.hashed_password == encrypt(password)
  # end
  def has_password?(raw_password)
	hashed_password == encrypt(raw_password)
  end

  def self.authenticate(email, plain_text_password)
	user = User.find_by_email(email)
	user && user.has_password?(plain_text_password) ? user : nil
  end
  
  def feed(paginate_options={page: 1})
	micro_posts.paginate(paginate_options)
  end
  
  # Returns the Relationship object this user has with other_user
  # or nil if no relationship exists
  def following?(other_user)
	relationships.find_by_followed_id(other_user.id)
  end

  # create a Relationship object where this user is following other_user
  def follow!(other_user)
	relationships.create!(followed_id: other_user.id)
  end

  # destroy the Relationship object where this user is following other_user
  def unfollow!(other_user)
	relationships.find_by_followed_id(other_user.id).destroy
  end
  
  def feed(paginate_options={page: 1})
    followed_user_ids = followed_users.map { |u| u.id }
    MicroPost.where('user_id = ? or user_id in (?)', id, followed_user_ids)
             .order('created_at DESC')
             .paginate(paginate_options)
  end
end