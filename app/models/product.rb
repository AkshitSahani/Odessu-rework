class Product < ApplicationRecord
  belongs_to :store, optional: true
  has_many :order_items
  has_many :wish_list_items

  def self.get_csv_data
    require 'csv'
    csv_text = File.read('app/assets/images/voluptuousverified.csv', :encoding => 'ISO-8859-1')
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

  def get_predicted_storesize(user)
    predicted_hip = user.predicted_hip
    predicted_waist = user.predicted_waist
    predicted_bust = user.predicted_bust

    #all of the products for now are from voluptuous. Every time you import a new CSV file for a new store whose products you're
    #listing, make associations that each of the new product.store = any instance of that store from the stores table.
    results_bust = Store.where(store_name: "VOLUPTUOUS", feature: 'BUST') #once the association is made, you can call self.store.store_name instead of hardcoding the store name
    results_waist = Store.where(store_name: "VOLUPTUOUS", feature: 'WAIST')
    results_hip = Store.where(store_name: "VOLUPTUOUS", feature: 'HIP')

    results_hash = {}

    results_bust.each do |result|
      if predicted_bust <= result.size_max.to_f && predicted_bust >= result.size_min.to_f
        results_hash[:bust] = result.store_size
      end
    end

    results_waist.each do |result|
      if predicted_waist <= result.size_max.to_f && predicted_waist >= result.size_min.to_f
        results_hash[:waist] = result.store_size
      end
    end

    results_hip.each do |result|
      if predicted_hip <= result.size_max.to_f && predicted_hip >= result.size_min.to_f
         results_hash[:hip] = result.store_size
      end
    end

    #for now the code for splitting the sizes to compare and decide which is bigger is only catered to the sizing format of
    #voluptuous. This needs to be modified in the future to be able to correctly do that for any store and sizing format.
    if results_hash[:hip] == results_hash[:waist] && results_hash[:hip] == results_hash[:bust] && results_hash[:bust] == results_hash[:waist]
      results_hash[:predicted_storesize] = results_hash[:hip]
      return results_hash[:predicted_storesize]

    else
      bust_split = results_hash[:bust].gsub(/\s+/, "").split('or')[1].split('/')[1]
      waist_split = results_hash[:waist].gsub(/\s+/, "").split('or')[1].split('/')[1]
      hip_split = results_hash[:hip].gsub(/\s+/, "").split('or')[1].split('/')[1]


      if self.dresses != nil
        max_size = [bust_split.to_i, waist_split.to_i, hip_split.to_i].max

        [results_hash[:bust], results_hash[:waist], results_hash[:hip]].each do |size|
          results_hash[:predicted_storesize] = size if size.include?(max_size.to_s)
        end
        return results_hash[:predicted_storesize]
      end

      if self.tops != nil
        if results_hash[:bust] == results_hash[:waist]
          results_hash[:predicted_storesize] = results_hash[:waist]
        else
          max_size = [bust_split.to_i, waist_split.to_i].max
          [results_hash[:bust], results_hash[:waist]].each do |size|
            results_hash[:predicted_storesize] = size if size.include?(max_size.to_s)
          end
        end
        return results_hash[:predicted_storesize]
      end

      if self.bottoms != nil
        if results_hash[:hip] == results_hash[:waist]
          results_hash[:predicted_storesize] = results_hash[:waist]
        else
          max_size = [hip_split.to_i, waist_split.to_i].max
          [results_hash[:hip], results_hash[:waist]].each do |size|
            results_hash[:predicted_storesize] = size if size.include?(max_size.to_s)
          end
        end
        return results_hash[:predicted_storesize]
      end

    end
  end

  def self.filter_by_body_shape(user)
    bodyShape = user.body_shape

    #TOP
    topHourglassFilter = ["off-the-shoulder", "off the shoulder", "peplum", "fit and flare", "fit & flare", "jeweled neckline", "jeweled neck", "tie waist", "drawstring", "cinched", "nipped", "crop", "cowl", "wrap", "wrapped", "fitted", "sweetheart", "boat neck", "boatneck", "bateau", "boat neckline", "sharkbite", "shark-bite", "handkerchief", "camisole", "cami", "tank", "Tube dress", "bandeau dress", "sheath dress", "shift dress", "blouson dress", "tunic dress", "pencil dress", "assymetric dress", "wrap dress", "trench dress", "hi-lo dress", "high-low dress", "empire dress", "empire waist dress", "bodycon dress", "fitted dress", "maxi dress", "midi dress", "kaftan dress", "shirt dress", "sweater dress", "cinched waist dress", "nipped waist dress", "waist paneled dress", "sash waist dress", "tie waist dress", "tie-waist dress", "peplum dress", "fringe dress", "a-line dress", "a line dress", "layered dress", "lace up dress", "denim dress", "dungaree", "pinafore dress", "cape dress", "fit and flare dress", "slit dress", "t-shirt dress", "tulle dress", "tuxedo dress", "tweed dress", "knee length dress"]

    topOvalFilter = ["peplum", "fit and flare", "empire", "wrap", "cinched peasant", "square neckline", "v-neck", "v neck", "v neckline", "v-neckline deep v", "u-neck", "u neckline", "u-neckline", "deep u", "u neck", "cowl neck", "cowl neckline", "sweetheart neckline", "hi-lo", "vertical details", "ruching", "ruched", "woven", "embroidered", "lace", "Tunic dress", "wrap dress", "trench dress", "hi-lo dress", "high-low dress", "empire dress", "empire waist dress", "maxi dress", "midi dress", "kaftan dress", "shirt dress", "denim dress", "dungaree", "pinafore dress", "cape dress", "shift dress", "slit dress", "t-shirt dress", "square neck dress", "square neckline dress", "u-neck dress", "u neck dress", "v neck dress", "scoopneck dress", "scoop neckline dress", "v-neck dress", "v neckline dress", "v-neckline dress", "cowl neck dress", "cowl neckline dress", "sweetheart neck dress", "sweetheart neckline dress", "colorblock sheath dress", "peplum dress"]

    topLeanColumnFilter = ["sweetheart", "portrait", "peplum", "fit and flare", "fit & flare", "drawstring", "cinched", "nipped", "ruffle neck", "tie neck", "tie neckline", "turtle neck", "turtle neckline", "cinched peasant", "one-shoulder", "boat neck", "bateau", "boat-neck", "boat neckline", "boat-neckline", "v-neck", "v neck", "v neckline", "v-neckline", "u neck", "u neckline", "u-neckline", "u-neck", "deep u", "deep v", "scoop neck", "scoop neckline", "lace details", "lace detailing", "lace", "halter neck", "halter neckline", "halter", "Asymmetric dress", "wrap dress", "trench dress", "hi-lo dress", "high-low dress", "empire dress", "empire waist dress", "skater dress", "maxi dress", "midi dress", "kaftan dress", "shirt dress", "cinched waist dress", "nipped waist dress", "waist paneled dress", "sash waist dress", "tie waist dress", "tie-waist dress", "peplum dress", "fringe dress", "pop over dress", "a-line dress", "a line dress", "layered dress", "lace up dress", "denim dress", "cape dress", "fit and flare dress", "shift dress", "slit dress", "t-shirt dress", "tuxedo dress", "ruffle neck dress", "ruffle-neck dress", "ruffle neckline dress", "tie neck dress", "tie neckline dress", "scoopneck dress", "scoop neckline dress", "deep u neckline dress", "u-neck dress", "u neck dress", " turtleneck dress", "boat neck dress", "boat neckline dress", "bateau neckline dress", "bateau neck dress", "v neck dress", "v-neck dress", "v neckline dress", "v-neckline dress", "one-shoulder dress", "one shoulder dress", "halter neck dress", "halter dress", "sweetheart neck dress", "sweetheart neckline dress", "lace dress", "portrait neck dress", "portrait neckline dress", "ruching dress", "ruched dress", "cinch dress", "side-cutout dress", "panel dress", "colorblock dress", "drop waist dress", "drop-waist dress", "drop-waisted dress", "princess dress", "curved darts dress"]

    topTriangleFilter = ["peplum", "fit and flare", "wrap", "surplice", "tie neckline", "tie", "v neck", "v-neck", "deep v", "puffed sleeves", "puff sleeves", "bell sleeves", "flared sleeves", "draped sleeves", "butterfly sleeves", "flare", "u-neck", "deep u", "scoop-neck", "scoop neckline", "scoop neck", "ruching", "ruched", "circle sleeves", "blouse", "flowy top", "jeweled neckline", "jeweled neck", "embelished neck", "embellished neckline", "boat neck", "boat-neck", "boat neckline", "shirred neckline", "shirred neck", "gauged neckline", "cap sleeve", "capped sleeve", "empire", " 3/4 length sleeves", "shoulder pads", "straight yoke", "breast pockets", "big collars", "angel sleeves", "circular flounce sleeves", "ruffle sleeves", "Tube dress", "bandeau dress", "blouson dress", "hi-lo dress", "high-low dress", " strapless dress", "a-line dress", "a line dress", "wrap dress", "off-the-shoulder dress", "off the shoulder dress", "princess dress", "hostess dress", "fit and flare dress", "tunic dress", "pencil dress", "asymmetric dress", "trench dress", "empire dress", "empire waist dress", "maxi dress", "midi dress", "kaftan dress", "shirt dress", "sweater dress", "cinched waist dress", "nipped waist dress", "waist paneled dress", "sash waist dress", "tie waist dress", "tie-waist dress", "peplum dress", "fringe dress", "layered dress", "lace up detail dress", "denim dress", "dungaree", "pinafore dress", "cape dress", "shift dress", "slit dress", "t-shirt dress", "tuxedo dress", "u-neck dress", "u neck dress", "v neck dress", "scoopneck dress", "scoop neckline dress", "v-neck dress", "v neckline dress", "v-neckline dress", "cowl neck dress", "cowl dress", "cowl neckline dress", "sweetheart dress", "puffed sleeve dress", "cap sleeve dress", "strapless dress", "off-the-shoulder fit and flare dress"]

    topInvertedTriangleFilter = ["cold shoulder", "open shoulder", "cut out shoulder", "shoulder cut out", "shoulder cut-out", "cut-out shoulder", "cutout shoulder", "shoulder cutout", "widestraps", "wide strap", "wide strapped", "collar less", "collar-less", "collarless", "no collar", "peplum", "fit and flare", "fit & flare", "fit", "flare", "cinched", "nipped", "cinch", "raglan", "dropped shoulder", "drop shoulder", "dropped sleeve", "drop sleeve", "dart drop sleeve", "sharkbite", "handkerchief", "u-neck", "v-neck", "deep u neckline", "deep v neckline", "shawl lapel", "shawl collar", "empire", "shoulder slits", "collarless", "collar less", "collar-less", "dolman sleeves", "dolman", "kimono", "v-neck dress", "belted dress", "trench dress", "fit and flare dress", "flare-hemmed dress", "wrap dress", "empire dress", "empire waist dress", "cinched waist dress", "nipped waist dress", "waist paneled dress", "sash waist dress", "tie waist dress", "tie-waist dress", "blouson dress", "princess dress", "shirt dress", "skimmer dress", "a-line dress", "a line dress", "tunic dress", "hi-lo dress", "high-low dress", "skater dress", "maxi dress", "midi dress", "kaftan dress", "denim dress", "dungaree", "pinafore dress", "cape dress", "shift dress", "slit dress", "t-shirt dress", "simple straight line dress", "pleat dress", "pleated dress"]

    #BOTTOM
    bottomHourglassFilter = ["classic pleated", "flat front", "drop-waisted", "drop-waist", "drop waist", "skinny jeans", "skinny-fit", "cargo", "military", "flare", "fit and flare", "fit & flare", "culottes", "culotte", "mid-rise", "straight", "high-waisted", "high-waist", "bootcut", "boot-cut", "sash", "straight", "palazzo", "straight-legged", "capri", "3/4", "d-ring", "pleated", "pleats", "classic pleats", "classic pleated belted", "flat front", "flat-front", "cargo", "utility", "military", "sailor", "retro", "a-line", "a line", "scallop", "scalloped", "tie-waist", "tie waist", "sash", "drawstring", "tailored", "high-waisted", "high waisted", "highwaisted", "high waist", "high-waist", "high-waisted", "mid-rise", "sash", "relaxed fit", "boyfriend", "colour-block", "colour block", "color-block", "color block", "vertical stripes", "vertical pattern", "prints", "print", "printed", "patterned", "pattern", "textured", "texture", "eyelet short", "assymetric print", "assymetrical print", "abstract print", "polka dot shorts", "polka-dot shorts", "polka dot print shorts", "tribal print", "floral print", "tile print", "foliage print", "aztec print", "flower", " exposed pockets", "embellished", "textured", "texture", "straight leg", "straight-legged shorts", "straight-cut", "Maxi skirt", "midi skirt", "slit skirt", "high waisted skirt", "high-waisted skirt", "high waist skirt", "high-waist skirt", "a-line skirt", "a line skirt", "flounce skirt", "empire skirt", "gore skirt", "sheath skirt", "wrap skirt", "trumpet skirt", "tunic skirt", "circular skirt", "soft pleat skirt", "soft pleated skirt", "full skirt", "pencil skirt", "lace skirt", "knee length skirt"]

    bottomOvalFilter = ["flat-front", "oxford", "flare", "straight", "bootcut", "boot-cut", "wide leg", "wide-legged", "wide legged", "cargo", "military", "flap-style pockets", "embellished pockets", "whiskering", "whiskered", "sailor", "sash", "gaucho", "culotte", "culottes", "bermuda", "tailored shorts", "cut-off shorts", "cutoff shorts", "cut off shorts", "frayed shorts", "frayed hem shorts", "fringe shorts", "fringed shorts", "fringe hem shorts", "fringed hem shorts", "ragged edges", "ragged edge", "raw edge", "flat front", "flat-front", "tapered cuffs", "whiskering", "a-line", "a line", "classic pleated", "pleated", "pleats", "cargo", "military", "utility", "culotte shorts", "sailor", "eyelet", "patterned", "printed", "print", "pattern", "drawstring", "skimmers", "sash", "tie waist", "tie", "boyfriend", "sailor", "textured", "texture", "Maxi skirt", "midi skirt", "slit skirt", "high-waisted flouncy skirt", " high-waisted circle skirt", "mesh skirt", "skater skirt", "pleated skirt", "pleat skirt", "full skirt", "circle skirt", "tiered skirt", "flared skirt", "short skirt", "mini skirt"]

    bottomLeanColumnFilter = ["pedal pushers", "oxford", "peplum", "jodhpurs", "pegged pants", "micro-pleated", "sash", "harem", "carrot", "cigarette", "capri", "clamdiggers", "skinny", "skinny-fit", "skinny", "detail casual shorts", "leggings", "tapered ", "cargo", "military", "balloon shorts", "balloon", "bubble shorts", "bubble", "ripped destruction", "repaired destruction", "distressed", "slashed", "rolled", "roll-ups", "roll up", "roll ups", "roll-up,turn up", "turn-up", "turnup", "cargo", "cuffs", "cuffed shorts", "military", "utility", "frayed", "fringe", "cut-off shorts", "cutoff shorts", "cut off shorts", "frayed shorts", "frayed hem shorts", "fringe shorts", "fringed shorts", "fringe hem shorts", "fringed hem shorts", "distressed shorts", "ragged edges", "ragged edge", "raw edge", "destroyed shorts", "destructed cutoff shorts", "scallop", "scalloped", "tie waist", "drawstring", "sash", "tie", "elasticized waist", "elastic band", "wide band", "sailor", "crochet", "lace", "embroidered", "embellished", "embroidery", "embellishment", "high-waisted", "high-waist", "high waisted", "high waist", "a-line", "a line", "pleats", "pleated", "classic pleated", "print", "printed", "patterned", "pattern", "textured", "texture", "eyelet short", "assymetric print", "assymetrical print", "abstract print", "polka dot shorts", "polka-dot shorts", "polka dot print shorts", "tribal print", "floral print", "tile print", "foliage print", "aztec print", "flower", " exposed pockets", "embellished", "flap style pockets", "embroidered", "embroidery", "embellishment,plaid", "houndstooth", "skorts", "skort", "wrap tie skort", "retro", "textured", "texture", "Maxi skirt", "midi skirt", "slit skirt", "pleated skirt", "pleat skirt", "box pleated skirt", "patterned skirt", "printed skirt", "print skirt", "pattern skirt", "embroidered skirt", "bead skirt", "embellished skirt", "latice skirt", "floral skirt", "uneven hem skirt", "asymmetric skirt", "flip skirt", "bias skirt", "wrap skirt", "circular skirt", "dirndl skirt", "dome skirt", "peg-top skirt", "peplum skirt", "pleated skirt", "tiered skirt", "mini skirt", "short skirt", "pencil skirt", "a line skirt", "a-line skirt"]

    bottomTriangleFilter = ["straight", "straight-legged", "straight leg", "oxford", "palazzo", "flare", "wide leg", "wide-legged", "wide legged", "gauchos", "culottes", "bell bottoms", "bootcut", "flat front", "flat-front", "high-waisted shorts", "high waisted shorts", "highwaisted shorts", "high waist", "high-waist", "highwaist", "bermuda", "knee-length shorts", "a line", "a-line", "flat front shorts", "flat-front shorts", "mid-length shorts", "mid length", "roll ups", "roll up", "rolled", "turn-ups", "turn up", "cuffs", "cuffed shorts", "welt pockets", "chinos", "tailored", "exposed pocket", "cut-off shorts", "cutoff shorts", "cut off shorts", "frayed shorts", "frayed hem shorts", "fringe shorts", "fringed shorts", "fringe hem shorts", "fringed hem shorts", "distressed shorts", "ragged edges", "ragged edge", "raw edge", "destroyed shorts", "destructed cutoff shorts", "straight leg", "straight-legged shorts", "straight-cut", "skimmers", "sash", "tie waist", "tie", "drawstring", "Tulip skirt", "a-line skirt", "a line skirt", "wrap skirt", "hi-lo skirt", "maxi skirt", "midi skirt", "slit skirt", "eyelet skirt", "full skirt", "gathered skirt", "drape skirt", "draped skirt", "bias cut skirt", "bias skirt", "straight skirt", "panella skirt", "circle skirt"]

    bottomInvertedTriangleFilter = ["pedal pusher", "oxford", "palazzo", "gauchos", "culottes shorts", "culottes pant", "culottes", "bootcut", "boot cut", "boot-cut", "distressed", "bootleg", "bell-bottoms", "bell bottoms", "flare", "flared", "wide-leg", "wide leg", "wide legged", "utility shorts", "cargo shorts", "military shorts", "paisley shorts", "bandana print with pompoms", "tribal print shorts ", "culotte shorts", "cut-off shorts", "cutoff shorts", "cut off shorts", "frayed shorts", "frayed hem shorts", "fringe shorts", "fringed shorts", "fringe hem shorts", "fringed hem shorts", "distressed shorts", "ragged edges", "ragged edge", "raw edge", "destroyed shorts", "destructed cutoff shorts", "assymetric print", "assymetrical print", "abstract print", "polka dot shorts", "polka-dot shorts", "polka dot print shorts", "tribal print", "floral print", "tile print", "foliage print", "aztec print", "flower", "short shorts", "high waisted shorts", "high-waisted shorts", "highwaisted shorts", "high waist", "high-waist", "highwaist", "a line", "a-line", "skort", "skimmer", "knee-length", "tailored", "exposed pockets", "embellished", "flap style pockets", "embroidered", "embroidery", "embellishment", "flowy", "wrap tie skort", "lace trim shorts", "lace shorts", "plaid", "houndstooth", "eyelet short", "belted shorts", "wide band shorts", "textured", "texture", "Full skirt", "balloon skirt", " high-waisted flouncy skirt", "high-waisted circle skirt", "high-waist skirt", "sailor skirt", "Dirndl skirt", "A-line skirt", "Circular skirt", "Gored skirt", "peplum skirt", "tulip skirt", "flounce skirt", "patio skirt", "bias cut skirt", "bias skirt", "trumpet skirt", "pleated skirt", "pleat skirt", "tiered skirt", "sarong skirt", "yoke skirt", "skater skirt", "button-up skirt", "high rise skirt", "maxi skirt", "midi skirt", "slit skirt", "mesh skirt", "skater skirt", "short skirt", "mini skirt"]

    if (bodyShape == "Hourglass")
      topFilter = topHourglassFilter
      bottomFilter = bottomHourglassFilter
    elsif (bodyShape == "Round")
      topFilter = topOvalFilter
      bottomFilter = bottomOvalFilter
    elsif (bodyShape == "Ruler")
      topFilter = topLeanColumnFilter
      bottomFilter = bottomLeanColumnFilter
    elsif (bodyShape == "Inverted-Triangle")
      topFilter = topInvertedTriangleFilter
      bottomFilter = bottomInvertedTriangleFilter
    elsif (bodyShape == "Triangle")
      topFilter = topTriangleFilter
      bottomFilter = bottomTriangleFilter
    end

    filtered_products = []
    Product.all.each do |prod|
      if prod.tops != nil
        i = 0
        while i < topFilter.count
          if prod.description1.include?(topFilter(i))
            filtered_products << prod
            break
          else
            i += 1
          end
        end

      elsif prod.bottoms != nil
        k = 0
        while k < bottomFilter.count
          if prod.description1.include?(bottomFilter(k))
            filtered_products << prod
            break
          else
            k+=1
          end
        end
      end
    end
    return filtered_products
  end

end
