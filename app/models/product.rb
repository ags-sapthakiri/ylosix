# == Schema Information
#
# Table name: products
#
#  appears_in_categories :boolean          default(TRUE)
#  appears_in_search     :boolean          default(TRUE)
#  appears_in_tag        :boolean          default(TRUE)
#  barcode               :string
#  control_stock         :boolean          default(FALSE)
#  created_at            :datetime
#  description           :text
#  enabled               :boolean          default(FALSE)
#  id                    :integer          not null, primary key
#  image_content_type    :string
#  image_file_name       :string
#  image_file_size       :integer
#  image_updated_at      :datetime
#  meta_description      :string
#  meta_keywords         :string
#  name                  :string
#  publication_date      :datetime         default(Thu, 01 Jan 2015 00:00:00 UTC +00:00), not null
#  reference_code        :string
#  retail_price          :decimal(10, 2)   default(0.0), not null
#  retail_price_pre_tax  :decimal(10, 5)   default(0.0), not null
#  short_description     :string
#  slug                  :string           not null
#  stock                 :integer          default(0)
#  tax_id                :integer
#  unpublication_date    :datetime
#  updated_at            :datetime
#
# Indexes
#
#  index_products_on_tax_id  (tax_id)
#

class Product < ActiveRecord::Base
  translates :name, :short_description, :description
  has_attached_file :image, styles: {thumb: '100x100>', medium: '300x300>'}

  IMAGE_SIZES = [:thumb, :medium, :original]

  validates_attachment_content_type :image, content_type: %r{\Aimage/.*\Z}

  belongs_to :tax
  has_many :products_categories
  has_many :categories, through: :products_categories

  has_many :products_tags
  has_many :tags, through: :products_tags

  has_many :product_translations
  has_many :shopping_carts_products

  accepts_nested_attributes_for :products_categories, allow_destroy: true
  accepts_nested_attributes_for :products_tags, allow_destroy: true
  accepts_nested_attributes_for :product_translations

  before_save :set_defaults

  scope :search_by_text, lambda { |text|
                         joins(:product_translations)
                             .where('product_translations.name LIKE ? OR product_translations.description LIKE ?', "%#{text}%", "%#{text}%")
                       }

  scope :in_frontend, lambda { |category|
                      joins(:products_categories)
                          .where(products_categories: {category_id: category.id},
                                 appears_in_categories: true)
                          .where('publication_date >= ?', DateTime.now)
                    }

  def admin_translations
    Utils.array_translations(ProductTranslation, product_id: id)
  end

  def clone
    product = dup
    # TODO: need to fix nested attributes.
    # product.products_tags = self.products_tags
    # product.products_categories = self.products_categories

    product
  end

  def retrieve_main_image(type = :original)
    image_src = 'http://placehold.it/800x300'

    # TODO add fixed sizes as small, large, original, etc.
    case type
      when :thumb
        image_src = 'http://placehold.it/160x75'
      when :medium
        image_src = 'http://placehold.it/320x150'
    end

    image_src = image.url(type) if image.file?
    image_src
  end

  def to_liquid
    helpers = Rails.application.routes.url_helpers
    s_short_description = ''
    s_short_description = short_description.html_safe unless short_description.blank?

    s_description = ''
    s_description = description.html_safe unless description.blank?

    liquid = {
        'name' => name,
        'short_description' => s_short_description,
        'description' => s_description,
        'retail_price' => retail_price,
        'href' => helpers.show_slug_products_path(slug),
        'add_cart_href' => helpers.add_to_shopping_cart_products_path(self),
        'delete_cart_href' => helpers.delete_from_shopping_cart_products_path(self)
    }

    append_images(liquid)
  end

  private

  def append_images(hash)
    IMAGE_SIZES.each do |size|
      hash["image_#{size}_src"] = retrieve_main_image(size)
    end

    hash
  end

  def set_defaults
    self.publication_date = Time.now if publication_date.nil?

    if slug.blank?
      self.slug = 'needs-to-be-changed'
      if product_translations.any? && !product_translations.first.name.blank?
        self.slug = URI.encode(product_translations.first.name)
      end
    end
  end
end
