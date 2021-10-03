require "make_taggable"
require 'stringex'

module Spree
  class Post < Spree::Base
    belongs_to :blog

    self.whitelisted_ransackable_associations = %w[blog]
    self.whitelisted_ransackable_attributes = %w[title]

    extend FriendlyId
    friendly_id :slug, use: [:slugged, :finders]

    make_taggable :tags

    before_save :create_slug, :set_published_at

    validates :title, :excerpt, presence: true

    if SpreeBlogs::Config[:use_action_text]
      has_rich_text :action_text_content
      validates :action_text_content, presence: true
    else
      validates :content, presence: true
    end

    default_scope { order("published_at DESC") }

    scope :visible, -> { where visible: true }
    scope :published_and_visible, -> { visible.where "published_at <= ?", DateTime.now }

    scope :recent, ->(max = 5) { published_and_visible.limit(max) }

    if Spree.user_class
      belongs_to :author, class_name: Spree.user_class.to_s, optional: true
    else
      belongs_to :author, optional: true
    end

    has_one :post_image, as: :viewable, dependent: :destroy, class_name: "Spree::PostImage"
    accepts_nested_attributes_for :post_image, reject_if: :all_blank

    def post_content
      if SpreeBlogs::Config[:use_action_text]
        action_text_content
      else
        content
      end
    end

    def author_display_name
      if author&.nickname.present?
        author.nickname
      elsif author.present?
        author.email
      else
        false
      end
    end

    def post_seo_title
      if meta_title.present?
        meta_title
      else
        title
      end
    end

    def self.by_tag(tag_name)
      tagged_with(tag_name, on: :tags)
    end

    def live?
      published_at <= DateTime.now && visible == true && blog.present?
    end

    private

    def create_slug
      self.slug = if slug.blank?
        title.to_url
      else
        slug.to_url
      end
    end

    def set_published_at
      self.published_at = DateTime.now if published_at.blank?
    end
  end
end
