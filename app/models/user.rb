class User < ActiveRecord::Base

  after_initialize :set_default_password, if: :new_record?
  after_initialize :set_default_role, if: :new_record?
  after_initialize :set_default_position, if: :new_record?

  # ==================================================
  # Relation
  # ==================================================

  belongs_to :position

  has_many :active_relation, class_name: "Relation", foreign_key: "sponser_id", dependent: :destroy
  has_one :passive_relation, class_name: "Relation", foreign_key: "sponsered_id", dependent: :destroy
  has_many :downline, through: :active_relation, source: :sponsered
  has_one :upline, through: :passive_relation, source: :sponser

  attr_accessor :remember_token

  # ==================================================
  # before save
  # ==================================================

  before_save{email.downcase! unless email.nil?}
  before_save{member_code.downcase!}
  before_save{role.downcase!}

  # ==================================================
  # validates
  # ==================================================

  validates :member_code,
          presence: true,
          length: {maximum: 50},
          uniqueness: {case_sensitive: false}

  VALID_IDEN_NUM_REGEX = /\A\d{13,13}\z/
  validates :iden_num,
        presence: true,
        length: {maximum: 13},
        format: {with: VALID_IDEN_NUM_REGEX},
        uniqueness: {case_sensitive: false}

  validate :iden_num_format

  validates :f_name, presence: true, length: {maximum: 100}
  validates :l_name, presence: true, length: {maximum: 100}
  validates :address, length: {maximum: 255}
  validates :city, length: {maximum: 255}
  validates :state, length: {maximum: 255}
  validates :postal_code, length: {maximum: 10}

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, length: {maximum: 255},
        format: { with: VALID_EMAIL_REGEX },
        uniqueness: {case_sensitive: false},
        if: "!email.nil?"

  VALID_PHONE_REGEX = /\A0\d{8,}\z/
  validates :phone,
        presence: true,
        length: {maximum: 20},
        format: {with: VALID_PHONE_REGEX}

  validates :line, length: {maximum: 50}

  def self.all_role ; %w[admin mobile stock member] ; end
  validates :role, presence: true, inclusion: {in: User.all_role}, allow_nil: true

  validates :position, presence: true

  has_secure_password
    validates :password, presence: true, length: {minimum: 4}, allow_nil: true

  # validate :set_default_password

  # ==================================================
  # public function
  # ==================================================

  # Returns the hash digest of the given string.
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token.
  def self.new_token
      SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for user in persistent sessions.
  def remember
      self.remember_token = User.new_token
      update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(remember_token)
      return false if remember_digest.nil?
      BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # Forgets a user.
  def forget
      update_attribute(:remember_digest, nil)
  end

  def is_admin?
    if self.role == "admin"
      return true
    else
      return false
    end
  end

  def sponser(other_user)
    active_relation.create(sponsered_id: other_user.id)
  end

  def sponser?(other_user)
    downline.include?(other_user)
  end

  # ==================================================
  # scope
  # ==================================================

  scope :search, -> (attr, query){where("#{attr} LIKE \'%#{query.split(//).join('%')}%\'")}

  # ==================================================
  # private function
  # ==================================================

  private

    def set_default_password
      if self.password.blank? && !self.iden_num.blank?
        password = self.iden_num.split(//).last(4).join
        self.password ||= password
        self.password_confirmation ||= password
      end
    end

    def set_default_role
      self.role ||= "member"
    end

    def set_default_position
      position = Position.find_by_name("no position") || Position.first
      if position.nil?
        errors.add(:position, "ไม่สามารถเพิ่มตำแหน่งได้")
      else
        self.position = position
      end
    end

    def iden_num_format
      unless self.iden_num.blank?
        iden_num_i = self.iden_num.split(//).map(&:to_i)
        x = 0

        for i in 1..(iden_num_i.count-1)
          x += (14-i)*iden_num_i[i-1]
        end
        x = x%11

        if x <= 1
          unless iden_num_i[iden_num_i.count-1] == (1-x)
            errors.add(:iden_num, "รูปแบบไม่ถูกต้อง")
          end
        else
          unless iden_num_i[iden_num_i.count-1] == (11-x)
            errors.add(:iden_num, "รูปแบบไม่ถูกต้อง")
          end
        end

      end

    end

end
