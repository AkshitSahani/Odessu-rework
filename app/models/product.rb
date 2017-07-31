class Product < ApplicationRecord
  belongs_to :store, optional: true
  has_many :order_items
  has_many :wish_list_items

  def self.get_csv_data
    require 'csv'
    csv_text = File.read('/Users/AkshitSahani/Desktop/bitmaker/projects/odessu/app/assets/voluptuousverified.csv', :encoding => 'ISO-8859-1')
    csv = CSV.parse(csv_text, :headers => true)

    csv.each do |row|
      Product.create!(row.to_hash)
    end
  end

  def get_product_colors
    self.color.split("Choose an option")[1].scan(/[[:upper:]]+[[:lower:]]+/)
  end

  def get_product_sizes
    all_sizes = self.size.split("Choose an option")[1]
    all_sizes_split = all_sizes.chars
    size_count = all_sizes_split.count / 2
    result = []
    size_count.times do result << [] end
    i = 0
    counter = 0
    all_sizes_split.each do |char|
      counter += 1
      result[i] << char
      i += 1 if counter % 2 == 0
    end
    result.map {|x| x.join('')}
  end

  def self.filter_results(filter)
    if filter == "ALL ITEMS"
      Product.all
    elsif filter == "DRESSES"
      Product.where.not(dresses: nil)
    elsif filter == "TOPS"
      Product.where.not(tops: nil)
    elsif filter == "BOTTOMS"
      Product.where.not(bottoms: nil)
    elsif filter == "JUMPSUITS"
      Product.where.not(jumpsuit: nil)
    end
  end

  def self.youtube_embed(youtube_url)
    if youtube_url[/youtu\.be\/([^\?]*)/]
      youtube_id = $1
    else
      youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
      youtube_id = $5
    end

    %Q{<iframe title="YouTube video player" width="450" height="300" src="http://www.youtube.com/embed/#{ youtube_id }" frameborder="0" allowfullscreen></iframe>}
  end

  def get_product_desc
    final_desc = []
    final_desc << self.description1 if (self.description1 != 'null' && self.description1 != nil && self.description1 != '#NAME?')
    final_desc << self.description2 if (self.description2 != 'null' && self.description2 != nil && self.description2 != '#NAME?')
    final_desc << self.description3 if (self.description3 != 'null' && self.description3 != nil && self.description3 != '#NAME?')
    final_desc << self.description4 if (self.description4 != 'null' && self.description4 != nil && self.description4 != '#NAME?')
    final_desc << self.description5 if (self.description5 != 'null' && self.description5 != nil && self.description5 != '#NAME?')
    return final_desc.join(' ')
  end

end
