class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :lockable

  has_many :authored_conversations, class_name: "Conversation", foreign_key: 'author_id'
  has_many :received_conversations, class_name: "Conversation", foreign_key: 'receiver_id'
  has_many :sent_messages, class_name: "Message", foreign_key: 'author_id', dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: 'receiver_id', dependent: :destroy
  has_many :orders
  has_one :wish_list
  has_many :issues
  accepts_nested_attributes_for :issues, reject_if: :all_blank?
  has_many :showoffs
  accepts_nested_attributes_for :showoffs, reject_if: :all_blank?

  def self.get_results(search)
    results_hash = {}
    results_stores = Store.where('lower(store_name) LIKE lower(?)', "%#{search}%") #change LIKE to ILIKE and remove lower term for deployment
    results_products = Product.where('lower(name) LIKE (?) OR lower(description1) LIKE lower(?)
    OR lower(description2) LIKE lower(?) OR lower(description3) LIKE lower(?) OR lower(description4) LIKE lower(?)
    OR lower(description5) LIKE lower(?)', "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%")
    results_hash[:store_results] = results_stores #heroku uses postgres which uses ILIKE for case-insensitive searches.
    results_hash[:product_results] = results_products
    return results_hash
  end

  def self.bmiCalculator(user)
    if user.weight_type == "Kg"
      weightKg = user.weight.to_i
    else
      weightKG = ((user.weight.to_i) * 0.453592)
    end

    if user.height_cm
      heightM = ((user.height_cms).to_f)/100
    elsif user.height_ft
      personHeight = (user.height_ft * 12) + user.height_in
      heightM = (personHeight.to_f * 0.0254)
    end

    bmi = (weightKG.to_f / (heightM * heightM))

    data_hash = {weight_kg: weightKG, height_m: heightM, bmi: bmi}

    if (bmi < 19)
      data_hash[:bmi_state] = "under"
    elsif ((bmi >= 19) && (bmi <= 24.999))
      data_hash[:bmi_state] = "healthy"
    elsif ((bmi >= 25) && (bmi <= 29.999))
      data_hash[:bmi_state] = "over"
    elsif (bmi >= 30)
      data_hash[:bmi_state] = "obese"
    end

    return data_hash
  end

  def self.guessBodyShapeNew(user, calculated_bmi)
     bustSize = user.bust.to_f
     waistSize = user.waist.to_f
     hipSize = user.hip.to_f
     bustWaistRatio = (bustSize / waistSize)
     hipWaistRatio = (hipSize / waistSize)
     waistRatio = 1

     diffInterBustWaist = (bustSize - waistSize).abs
     diffInterHipWaist = (hipSize - waistSize).abs
     diffInterBustHip = (bustSize - hipSize).abs

     bodyCategory = calculated_bmi

     results_hash = {bust_waist_ratio: bustWaistRatio, hip_waist_ratio: hipWaistRatio, body_category: bodyCategory}

     if((diffInterBustWaist <= 3) && (diffInterHipWaist <= 3) && (diffInterBustHip <= 3))
       results_hash[:body_shape] = "Rectangle"
     elsif((waistRatio > bustWaistRatio) && (waistRatio > hipWaistRatio))
       results_hash[:body_shape] = "Oval"
     elsif ((waistRatio < bustWaistRatio) && (waistRatio < hipWaistRatio))
       results_hash[:body_shape] = "Hourglass"
     elsif ((waistRatio < bustWaistRatio) && (waistRatio > hipWaistRatio))
       results_hash[:body_shape] = "Inverted Triangle"
     elsif ((waistRatio > bustWaistRatio) && (waistRatio < hipWaistRatio))
       results_hash[:body_shape] = "Triangle"
     end
     return results_hash
  end

  def self.calcFromHeightWeight(user) #when you only have height and weight from the user. priority: 1**
    if user.height_cm
      getHeight = (user.height_cm.to_f) * 0.393701
    elsif user.height_ft
      getHeight = (user.height_ft.to_f * 12) + user.height_in.to_f
    end

    if user.weight_type == "Lbs"
      getWeight = user.weight.to_f
    elsif user.weight_type == "Kg"
      getWeight = ((user.weight.to_f) * 2.20462)
    end

    if ((getHeight >= 48) && (getHeight <= 59))
        predictedFromHWBust = (39.8264 + (getHeight * (-0.302730)) + (getWeight * 0.120800))
        predictedFromHWWaist = (35.8677 + (getHeight * (-0.384542)) + (getWeight * 0.138296))
        predictedFromHWHip = (33.4821 + (getHeight * (-0.166397)) + (getWeight * 0.118986))
        predictedFromHWInseam = (-7.39781 + (getHeight * 0.602135)) + (getWeight * (-0.0133127))
    elsif ((getHeight >= 60) && (getHeight <=71))
        predictedFromHWBust = (39.8602 + (getHeight * (-0.303865)) + (getWeight * 0.120917))
        predictedFromHWWaist = (60.0865 + (getHeight * (-0.763514)) + (getWeight * 0.141982))
        predictedFromHWHip = (33.3585 + (getHeight * (-0.162360)) + (getWeight * 0.118724))
        predictedFromHWInseam = (-7.85941 + (getHeight * 0.608293)) + (getWeight * (-0.0128906))
    elsif ((getHeight >= 72) && (getHeight <=80))
        predictedFromHWBust = (39.7441 + (getHeight * (-0.302251)) + (getWeight * 0.120945))
        predictedFromHWWaist = (39.4437 + (getHeight * (-0.446287)) + (getWeight * 0.139020))
        predictedFromHWHip = (33.0163 + (getHeight * (-0.160000)) + (getWeight * 0.119220))
        predictedFromHWInseam = (-10.1759 + (getHeight * 0.636287)) + (getWeight * (-0.0117900))
    end

    results_hash = {}
    results_hash[:true_bust] = predictedFromHWBust
    results_hash[:true_waist] = predictedFromHWWaist
    results_hash[:true_hip] = predictedFromHWHip
    results_hash[:true_inseam] = predictedFromHWInseam

    return results_hash
  end

  def self.calcFromHeightWeightBra(user) #priority 2
    getBraBust = user.bra_size.to_f + (['AA', 'A', 'B', 'C', 'D', 'DD or E', 'DDD or F', 'G', 'H', 'I', 'J'].find_index(user.bra_cup))

    if user.height_cm
      getHeight = (user.height_cm.to_f) * 0.393701
    elsif user.height_ft
      getHeight = (user.height_ft.to_f * 12) + user.height_in.to_f
    end

    if user.weight_type == "Lbs"
      getWeight = user.weight.to_f
    elsif user.weight_type == "Kg"
      getWeight = ((user.weight.to_f) * 2.20462)
    end

    if ((getHeight >= 48) && (getHeight <= 59))
        predictedFromHWBust = (39.8264 + (getHeight * (-0.302730)) + (getWeight * 0.120800))
        predictedFromHWWaist = (35.8677 + (getHeight * (-0.384542)) + (getWeight * 0.138296))
        predictedFromHWHip = (33.4821 + (getHeight * (-0.166397)) + (getWeight * 0.118986))
        predictedFromHWInseam = (-7.39781 + (getHeight * 0.602135)) + (getWeight * (-0.0133127))
    elsif ((getHeight >= 60) && (getHeight <=71))
        predictedFromHWBust = (39.8602 + (getHeight * (-0.303865)) + (getWeight * 0.120917))
        predictedFromHWWaist = (60.0865 + (getHeight * (-0.763514)) + (getWeight * 0.141982))
        predictedFromHWHip = (33.3585 + (getHeight * (-0.162360)) + (getWeight * 0.118724))
        predictedFromHWInseam = (-7.85941 + (getHeight * 0.608293)) + (getWeight * (-0.0128906))
    elsif ((getHeight >= 72) && (getHeight <=80))
        predictedFromHWBust = (39.7441 + (getHeight * (-0.302251)) + (getWeight * 0.120945))
        predictedFromHWWaist = (39.4437 + (getHeight * (-0.446287)) + (getWeight * 0.139020))
        predictedFromHWHip = (33.0163 + (getHeight * (-0.160000)) + (getWeight * 0.119220))
        predictedFromHWInseam = (-10.1759 + (getHeight * 0.636287)) + (getWeight * (-0.0117900))
    end

    constant = 0
    coefficient = 0

    #Set Coefficient and Constant
    if((getWeight >= 140) && (getWeight < 150))
        constant = -2.75
        coefficient = 0.880769
    elsif((getWeight >= 150) && (getWeight < 160))
        constant = -2.36061
        coefficient = 0.879545
    elsif((getWeight >= 160) && (getWeight < 170))
        constant = -2.04394
        coefficient = 0.879545
    elsif((getWeight >= 170) && (getWeight < 180))
        constant = -1.67552
        coefficient = 0.878671
    elsif((getWeight >= 180) && (getWeight < 190))
        constant = -1.39953
        coefficient = 0.88007
    elsif((getWeight >= 190) && (getWeight < 200))
        constant = -1.06212
        coefficient = 0.879545
    elsif((getWeight >= 200) && (getWeight < 210))
        constant = -0.721212
        coefficient = 0.879545
    elsif((getWeight >= 210) && (getWeight < 220))
        constant = -7.38083
        coefficient = 1.04605
    elsif((getWeight >= 220) && (getWeight < 230))
        constant = 0.00198135
        coefficient = 0.877972
    elsif((getWeight >= 230) && (getWeight < 240))
        constant = 0.259907
        coefficient = 0.88007
    elsif((getWeight >= 240) && (getWeight < 250))
        constant = 0.559907
        coefficient = 0.88007
    elsif((getWeight >= 250) && (getWeight < 260))
        constant = 0.98951
        coefficient = 0.878147
    elsif((getWeight >= 260) && (getWeight < 270))
        constant = 1.18077
        coefficient = 0.880769
    elsif((getWeight >= 270) && (getWeight < 280))
        constant = 1.53963
        coefficient = 0.88007
    elsif((getWeight >= 280) && (getWeight < 290))
        constant = 1.97692
        coefficient = 0.878147
    elsif((getWeight >= 290) && (getWeight < 300))
        constant = 2.15769
        coefficient = 0.880769
    elsif((getWeight >= 300) && (getWeight < 310))
        constant = 2.55758
        coefficient = 0.879545
    elsif((getWeight >= 310) && (getWeight < 320))
        constant = 2.85268
        coefficient = 0.88007
    elsif((getWeight >= 320) && (getWeight < 330))
        constant = 3.25641
        coefficient = 0.878846
    elsif((getWeight >= 330) && (getWeight < 340))
        constant = 3.53939
        coefficient = 0.879545
    elsif((getWeight >= 340) && (getWeight < 350))
        constant = 3.8324
        coefficient = 0.88007
    elsif((getWeight >= 350) && (getWeight < 360))
        constant = 4.19697
        coefficient = 0.879545
    elsif((getWeight >= 360) && (getWeight < 370))
        constant = 4.5303
        coefficient = 0.879545
    elsif((getWeight >= 370) && (getWeight < 380))
        constant = -7.38083
        coefficient = 1.04605
    elsif((getWeight >= 380) && (getWeight < 390))
        constant = 5.15198
        coefficient = 0.88007
    end

    predictedFromBraWaist = (constant + (coefficient * getBraBust))

    deltaWaist = (predictedFromHWWaist - predictedFromBraWaist).abs

    if (getBodyShape == "Triangle")
      predictedFromHWHip += deltaWaist
    end

    trueBust = (((predictedFromHWBust * 4) + (predictedFromBraBust * 6)) / 10)
    trueWaist = (((predictedFromHWWaist * 4) + (predictedFromBraWaist * 6)) / 10)
    trueHip = predictedFromHWHip

    results_hash = {}
    results_hash[:true_bust] = trueBust
    results_hash[:true_waist] = trueWaist
    results_hash[:true_hip] = trueHip

    return results_hash
  end

  def self.calcFromStoresAndSizes(user) # when you only know the stores and sizes in each store for the user. priority 5

    #Variable Instantiation
    topBustMax = 0
    topBustMin = 0
    topWaistMax = 0
    topWaistMin = 0
    topHipMax = 0
    topHipMin = 0

    bottomBustMax = 0
    bottomBustMin = 0
    bottomWaistMax = 0
    bottomWaistMin = 0
    bottomHipMax = 0
    bottomHipMin = 0

    countTopMinBust = 0
    countTopMaxBust = 0
    countTopMinWaist = 0
    countTopMaxWaist = 0
    countTopMinHip = 0
    countTopMaxHip = 0

    countTopBustLoops = 0
    countTopWaistLoops = 0
    countTopHipLoops = 0

    countBottomMinBust = 0
    countBottomMaxBust = 0
    countBottomMinWaist = 0
    countBottomMaxWaist = 0
    countBottomMinHip = 0
    countBottomMaxHip = 0

    countBottomBustLoops = 0
    countBottomWaistLoops = 0
    countBottomHipLoops = 0

    storeName = user.tops_store.upcase
    storeSizeTop = user.tops_size

    resultTopBust = Store.where(store_name: storeName, feature: "BUST")
    resultTopWaist = Store.where(store_name: storeName, feature: "WAIST")
    resultTopHip = Store.where(store_name: storeName, feature: "HIP")

    #Get Data For Top Bust

    numRowsTopBust = resultTopBust.count
    a = 0
    while a < resultTopBust.count

      countTopBustLoops+= 1

      if((resultTopBust[a].store_size.include?(storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?( "2" + storeSizeTop)))

        topBustMin = topBustMin + resultTopBust[a].size_min.to_f
        topBustMax = topBustMax + resultTopBust[a].size_max.to_f

        countTopMinBust += 1
        countTopMaxBust += 1
        break
      elsif(resultTopBust[a].store_size == storeSizeTop)

        topBustMin = topBustMin + resultTopBust[a].size_min.to_f
        topBustMax = topBustMax + resultTopBust[a].size_max.to_f

        countTopMinBust+= 1
        countTopMaxBust+= 1
        a += 1
      elsif(numRowsTopBust == countTopBustLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        a += 1
      end
    end


    #Get Data For Top Waist
    numRowsTopWaist = resultTopWaist.count
    b = 0
    while b < resultTopWaist.count

      countTopWaistLoops+=1
      if((resultTopWaist[b].store_size.include?(storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?( "2" + storeSizeTop)))

        topWaistMin = topWaistMin + resultTopWaist[b].size_min.to_f
        topWaistMax = topWaistMax + resultTopWaist[b].size_max.to_f

        countTopMinWaist+=1
        countTopMaxWaist+=1

        break
      elsif(resultTopWaist[b].store_size == storeSizeTop)

        topWaistMin = topWaistMin + resultTopWaist[b].size_min.to_f
        topWaistMax = topWaistMax + resultTopWaist[b].size_max.to_f

        countTopMinWaist+=1
        countTopMaxWaist+=1
        b+=1
      elsif(numRowsTopWaist == countTopWaistLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        b += 1
      end
    end

    numRowsTopHip = resultTopHip.count
    c = 0
    while c < resultTopHip.count

      countTopHipLoops+=1
      if((resultTopHip[c].store_size.include?(storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?( "2" + storeSizeTop)))

        topHipMin = topHipMin + resultTopHip[c].size_min.to_f
        topHipMax = topHipMax + resultTopHip[c].size_max.to_f

        countTopMinHip+=1
        countTopMaxHip+=1
        break
      elsif(resultTopHip[c].store_size == storeSizeTop)
        topHipMin = topHipMin + resultTopHip[c].size_min.to_f
        topHipMax = topHipMax + resultTopHip[c].size_max.to_f

        countTopMinHip+=1
        countTopMaxHip+=1
        c+=1
      elsif(numRowsTopHip == countTopHipLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        c += 1
      end
    end

    storeName = user.bottoms_store.upcase
    storeSizeBottom = user.bottoms_size

    resultBottomBust = Store.where(store_name: storeName, feature: "BUST")
    resultBottomWaist = Store.where(store_name: storeName, feature: "WAIST")
    resultBottomHip = Store.where(store_name: storeName, feature: "HIP")

    numRowsBottomBust = resultBottomBust.count
    i = 0
    while i < resultBottomBust.count

      countBottomBustLoops+=1
      if((resultBottomBust[i].store_size.include?(storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?( "2" + storeSizeBottom)))

        bottomBustMin = bottomBustMin + resultBottomBust[i].size_min.to_f
        bottomBustMax = bottomBustMax + resultBottomBust[i].size_max.to_f

        countBottomMinBust+=1
        countBottomMaxBust+=1

        break
      elsif(resultBottomBust[i].store_size == storeSizeBottom)

        bottomBustMin = bottomBustMin + resultBottomBust[i].size_max.to_f
        bottomBustMax = bottomBustMax + resultBottomBust[i].size_min.to_f

        countBottomMinBust+=1
        countBottomMaxBust+=1
        i+=1
      elsif(numRowsBottomBust == countBottomBustLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        i += 1
      end
    end

    numRowsBottomWaist = resultBottomWaist.count
    j = 0
    while j < resultBottomWaist.count

      countBottomWaistLoops+=1

      if((resultBottomWaist[j].store_size.include?(storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?( "2" + storeSizeBottom)))

        bottomWaistMin = bottomWaistMin + resultBottomWaist[j].size_min.to_f
        bottomWaistMax = bottomWaistMax + resultBottomWaist[j].size_max.to_f

        countBottomMinWaist+=1
        countBottomMaxWaist+=1
        break
      elsif(resultBottomWaist[j].store_size == storeSizeBottom)
        bottomWaistMin = bottomWaistMin + resultBottomWaist[j].size_min.to_f
        bottomWaistMax = bottomWaistMax + resultBottomWaist[j].size_max.to_f

        countBottomMinWaist+=1
        countBottomMaxWaist+=1
        j+=1
      elsif(numRowsBottomWaist == countBottomWaistLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        j += 1
      end
    end

    numRowsBottomHip = resultBottomHip.count
    k = 0
    while k < resultBottomHip.count

      countBottomHipLoops+=1
      if((resultBottomHip[k].store_size.include?(storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?( "2" + storeSizeBottom)))

        bottomHipMin = bottomHipMin + resultBottomHip[k].size_min.to_f
        bottomHipMax = bottomHipMax + resultBottomHip[k].size_max.to_f

        countBottomMinHip+=1
        countBottomMaxHip+=1
        break
      elsif(resultBottomHip[k].store_size == storeSizeBottom)
        bottomHipMin = bottomHipMin + resultBottomHip[k].size_min.to_f
        bottomHipMax = bottomHipMax + resultBottomHip[k].size_max.to_f

        countBottomMinHip+=1
        countBottomMaxHip+=1
        k+=1
      elsif(numRowsBottomHip == countBottomHipLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        k += 1
      end
    end

    averageTopBustMin = ((topBustMin.to_f) / countTopMinBust)
    averageTopBustMax = (topBustMax.to_f / countTopMaxBust)
    averageTopWaistMin = (topWaistMin.to_f / countTopMinWaist)
    averageTopWaistMax = (topWaistMax.to_f / countTopMaxWaist)
    averageTopHipMin = (topHipMin.to_f / countTopMinHip)
    averageTopHipMax = (topHipMax.to_f / countTopMaxHip)

    averageBottomBustMin = (bottomBustMin.to_f / countBottomMinBust)
    averageBottomBustMax = (bottomBustMax.to_f / countBottomMaxBust)
    averageBottomWaistMin = (bottomWaistMin.to_f / countBottomMinWaist)
    averageBottomWaistMax = (bottomWaistMax.to_f / countBottomMaxWaist)
    averageBottomHipMin = (bottomHipMin.to_f / countBottomMinHip)
    averageBottomHipMax = (bottomHipMax.to_f/ countBottomMaxHip)

    averageTopBust = (((averageTopBustMin.to_f * 6) + (averageTopBustMax * 4)) / 10)
    averageTopWaist = (((averageTopWaistMin.to_f * 6) + (averageTopWaistMax * 4)) / 10)
    averageTopHip = (((averageTopHipMin.to_f * 6) + (averageTopHipMax * 4)) / 10)

    averageBottomBust = (((averageBottomBustMin.to_f * 6) + (averageBottomBustMax * 4)) / 10)
    averageBottomWaist = (((averageBottomWaistMin.to_f * 6) + (averageBottomWaistMax * 4)) / 10)
    averageBottomHip = (((averageBottomHipMin.to_f * 6) + (averageBottomHipMax * 4)) / 10)

    averageBust = (((averageTopBust.to_f * 9) + averageBottomBust) / 10)
    averageWaist = (((averageTopWaist.to_f * 2) + (averageBottomWaist * 8)) / 10)
    averageHip = ((averageTopHip.to_f + (averageBottomHip * 9)) / 10)

    results_hash = {}
    results_hash[:true_bust] = averageBust
    results_hash[:true_waist] = averageWaist
    results_hash[:true_hip] = averageHip

    return results_hash
  end

  def self.calcFromStoreAndHeightWeightBust(user) #priority 3
    #Variable Instantiation
    topBustMax = 0
    topBustMin = 0
    topWaistMax = 0
    topWaistMin = 0
    topHipMax = 0
    topHipMin = 0

    bottomBustMax = 0
    bottomBustMin = 0
    bottomWaistMax = 0
    bottomWaistMin = 0
    bottomHipMax = 0
    bottomHipMin = 0

    countTopMinBust = 0
    countTopMaxBust = 0
    countTopMinWaist = 0
    countTopMaxWaist = 0
    countTopMinHip = 0
    countTopMaxHip = 0

    countTopBustLoops = 0
    countTopWaistLoops = 0
    countTopHipLoops = 0

    countBottomMinBust = 0
    countBottomMaxBust = 0
    countBottomMinWaist = 0
    countBottomMaxWaist = 0
    countBottomMinHip = 0
    countBottomMaxHip = 0

    countBottomBustLoops = 0
    countBottomWaistLoops = 0
    countBottomHipLoops = 0

    storeName = user.tops_store.upcase
    storeSizeTop = user.tops_size

    resultTopBust = Store.where(store_name: storeName, feature: "BUST")
    resultTopWaist = Store.where(store_name: storeName, feature: "WAIST")
    resultTopHip = Store.where(store_name: storeName, feature: "HIP")

    #Get Data For Top Bust

    numRowsTopBust = resultTopBust.count
    a = 0
    while a < resultTopBust.count

      countTopBustLoops+= 1

      if((resultTopBust[a].store_size.include?(storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?( "2" + storeSizeTop)))

        topBustMin = topBustMin + resultTopBust[a].size_min.to_f
        topBustMax = topBustMax + resultTopBust[a].size_max.to_f

        countTopMinBust += 1
        countTopMaxBust += 1
        break
      elsif(resultTopBust[a].store_size == storeSizeTop)

        topBustMin = topBustMin + resultTopBust[a].size_min.to_f
        topBustMax = topBustMax + resultTopBust[a].size_max.to_f

        countTopMinBust+= 1
        countTopMaxBust+= 1
        a += 1
      elsif(numRowsTopBust == countTopBustLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        a += 1
      end
    end


    #Get Data For Top Waist
    numRowsTopWaist = resultTopWaist.count
    b = 0
    while b < resultTopWaist.count

      countTopWaistLoops+=1
      if((resultTopWaist[b].store_size.include?(storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?( "2" + storeSizeTop)))

        topWaistMin = topWaistMin + resultTopWaist[b].size_min.to_f
        topWaistMax = topWaistMax + resultTopWaist[b].size_max.to_f

        countTopMinWaist+=1
        countTopMaxWaist+=1

        break
      elsif(resultTopWaist[b].store_size == storeSizeTop)

        topWaistMin = topWaistMin + resultTopWaist[b].size_min.to_f
        topWaistMax = topWaistMax + resultTopWaist[b].size_max.to_f

        countTopMinWaist+=1
        countTopMaxWaist+=1
        b+=1
      elsif(numRowsTopWaist == countTopWaistLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        b += 1
      end
    end

    numRowsTopHip = resultTopHip.count
    c = 0
    while c < resultTopHip.count

      countTopHipLoops+=1
      if((resultTopHip[c].store_size.include?(storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?( "2" + storeSizeTop)))

        topHipMin = topHipMin + resultTopHip[c].size_min.to_f
        topHipMax = topHipMax + resultTopHip[c].size_max.to_f

        countTopMinHip+=1
        countTopMaxHip+=1
        break
      elsif(resultTopHip[c].store_size == storeSizeTop)
        topHipMin = topHipMin + resultTopHip[c].size_min.to_f
        topHipMax = topHipMax + resultTopHip[c].size_max.to_f

        countTopMinHip+=1
        countTopMaxHip+=1
        c+=1
      elsif(numRowsTopHip == countTopHipLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        c += 1
      end
    end

    storeName = user.bottoms_store.upcase
    storeSizeBottom = user.bottoms_size

    resultBottomBust = Store.where(store_name: storeName, feature: "BUST")
    resultBottomWaist = Store.where(store_name: storeName, feature: "WAIST")
    resultBottomHip = Store.where(store_name: storeName, feature: "HIP")

    numRowsBottomBust = resultBottomBust.count
    i = 0
    while i < resultBottomBust.count

      countBottomBustLoops+=1
      if((resultBottomBust[i].store_size.include?(storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?( "2" + storeSizeBottom)))

        bottomBustMin = bottomBustMin + resultBottomBust[i].size_min.to_f
        bottomBustMax = bottomBustMax + resultBottomBust[i].size_max.to_f

        countBottomMinBust+=1
        countBottomMaxBust+=1

        break
      elsif(resultBottomBust[i].store_size == storeSizeBottom)

        bottomBustMin = bottomBustMin + resultBottomBust[i].size_max.to_f
        bottomBustMax = bottomBustMax + resultBottomBust[i].size_min.to_f

        countBottomMinBust+=1
        countBottomMaxBust+=1
        i+=1
      elsif(numRowsBottomBust == countBottomBustLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        i += 1
      end
    end

    numRowsBottomWaist = resultBottomWaist.count
    j = 0
    while j < resultBottomWaist.count

      countBottomWaistLoops+=1

      if((resultBottomWaist[j].store_size.include?(storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?( "2" + storeSizeBottom)))

        bottomWaistMin = bottomWaistMin + resultBottomWaist[j].size_min.to_f
        bottomWaistMax = bottomWaistMax + resultBottomWaist[j].size_max.to_f

        countBottomMinWaist+=1
        countBottomMaxWaist+=1
        break
      elsif(resultBottomWaist[j].store_size == storeSizeBottom)
        bottomWaistMin = bottomWaistMin + resultBottomWaist[j].size_min.to_f
        bottomWaistMax = bottomWaistMax + resultBottomWaist[j].size_max.to_f

        countBottomMinWaist+=1
        countBottomMaxWaist+=1
        j+=1
      elsif(numRowsBottomWaist == countBottomWaistLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        j += 1
      end
    end

    numRowsBottomHip = resultBottomHip.count
    k = 0
    while k < resultBottomHip.count

      countBottomHipLoops+=1
      if((resultBottomHip[k].store_size.include?(storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?( "2" + storeSizeBottom)))

        bottomHipMin = bottomHipMin + resultBottomHip[k].size_min.to_f
        bottomHipMax = bottomHipMax + resultBottomHip[k].size_max.to_f

        countBottomMinHip+=1
        countBottomMaxHip+=1
        break
      elsif(resultBottomHip[k].store_size == storeSizeBottom)
        bottomHipMin = bottomHipMin + resultBottomHip[k].size_min.to_f
        bottomHipMax = bottomHipMax + resultBottomHip[k].size_max.to_f

        countBottomMinHip+=1
        countBottomMaxHip+=1
        k+=1
      elsif(numRowsBottomHip == countBottomHipLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        k += 1
      end
    end

    averageTopBustMin = ((topBustMin.to_f) / countTopMinBust)
    averageTopBustMax = (topBustMax.to_f / countTopMaxBust)
    averageTopWaistMin = (topWaistMin.to_f / countTopMinWaist)
    averageTopWaistMax = (topWaistMax.to_f / countTopMaxWaist)
    averageTopHipMin = (topHipMin.to_f / countTopMinHip)
    averageTopHipMax = (topHipMax.to_f / countTopMaxHip)

    averageBottomBustMin = (bottomBustMin.to_f / countBottomMinBust)
    averageBottomBustMax = (bottomBustMax.to_f / countBottomMaxBust)
    averageBottomWaistMin = (bottomWaistMin.to_f / countBottomMinWaist)
    averageBottomWaistMax = (bottomWaistMax.to_f / countBottomMaxWaist)
    averageBottomHipMin = (bottomHipMin.to_f / countBottomMinHip)
    averageBottomHipMax = (bottomHipMax.to_f/ countBottomMaxHip)

    averageTopBust = (((averageTopBustMin.to_f * 6) + (averageTopBustMax * 4)) / 10)
    averageTopWaist = (((averageTopWaistMin.to_f * 6) + (averageTopWaistMax * 4)) / 10)
    averageTopHip = (((averageTopHipMin.to_f * 6) + (averageTopHipMax * 4)) / 10)

    averageBottomBust = (((averageBottomBustMin.to_f * 6) + (averageBottomBustMax * 4)) / 10)
    averageBottomWaist = (((averageBottomWaistMin.to_f * 6) + (averageBottomWaistMax * 4)) / 10)
    averageBottomHip = (((averageBottomHipMin.to_f * 6) + (averageBottomHipMax * 4)) / 10)

    averageBust = (((averageTopBust.to_f * 9) + averageBottomBust) / 10)
    averageWaist = (((averageTopWaist.to_f * 2) + (averageBottomWaist * 8)) / 10)
    averageHip = ((averageTopHip.to_f + (averageBottomHip * 9)) / 10)

    if user.height_cm
      getHeight = (user.height_cm.to_f) * 0.393701
    elsif user.height_ft
      getHeight = (user.height_ft.to_f * 12) + user.height_in.to_f
    end

    if user.weight_type == "Lbs"
      getWeight = user.weight.to_f
    elsif user.weight_type == "Kg"
      getWeight = ((user.weight.to_f) * 2.20462)
    end
    # getBraBust = user.bust #(bra size)

    if ((getHeight >= 48) && (getHeight <= 59))
        predictedBust = (39.8264 + (getHeight * (-0.302730)) + (getWeight * 0.120800))
        predictedWaist = (35.8677 + (getHeight * (-0.384542)) + (getWeight * 0.138296))
        predictedHip = (33.4821 + (getHeight * (-0.166397)) + (getWeight * 0.118986))
        predictedInseam = (-7.39781 + (getHeight * 0.602135)) + (getWeight * (-0.0133127))
    elsif ((getHeight >= 60) && (getHeight <=71))
        predictedBust = (39.8602 + (getHeight * (-0.303865)) + (getWeight * 0.120917))
        predictedWaist = (60.0865 + (getHeight * (-0.763514)) + (getWeight * 0.141982))
        predictedHip = (33.3585 + (getHeight * (-0.162360)) + (getWeight * 0.118724))
        predictedInseam = (-7.85941 + (getHeight * 0.608293)) + (getWeight * (-0.0128906))
    elsif ((getHeight >= 72) && (getHeight <=80))
        predictedBust = (39.7441 + (getHeight * (-0.302251)) + (getWeight * 0.120945))
        predictedWaist = (39.4437 + (getHeight * (-0.446287)) + (getWeight * 0.139020))
        predictedHip = (33.0163 + (getHeight * (-0.160000)) + (getWeight * 0.119220))
        predictedInseam = (-10.1759 + (getHeight * 0.636287)) + (getWeight * (-0.0117900))
    end

    getBraBust = user.bra_size.to_f + (['AA', 'A', 'B', 'C', 'D', 'DD or E', 'DDD or F', 'G', 'H', 'I', 'J'].find_index(user.bra_cup))

    constant = 0
    coefficient = 0

    #Set Coefficient and Constant
    if((getWeight >= 140) && (getWeight < 150))
        constant = -2.75
        coefficient = 0.880769
    elsif((getWeight >= 150) && (getWeight < 160))
        constant = -2.36061
        coefficient = 0.879545
    elsif((getWeight >= 160) && (getWeight < 170))
        constant = -2.04394
        coefficient = 0.879545
    elsif((getWeight >= 170) && (getWeight < 180))
        constant = -1.67552
        coefficient = 0.878671
    elsif((getWeight >= 180) && (getWeight < 190))
        constant = -1.39953
        coefficient = 0.88007
    elsif((getWeight >= 190) && (getWeight < 200))
        constant = -1.06212
        coefficient = 0.879545
    elsif((getWeight >= 200) && (getWeight < 210))
        constant = -0.721212
        coefficient = 0.879545
    elsif((getWeight >= 210) && (getWeight < 220))
        constant = -7.38083
        coefficient = 1.04605
    elsif((getWeight >= 220) && (getWeight < 230))
        constant = 0.00198135
        coefficient = 0.877972
    elsif((getWeight >= 230) && (getWeight < 240))
        constant = 0.259907
        coefficient = 0.88007
    elsif((getWeight >= 240) && (getWeight < 250))
        constant = 0.559907
        coefficient = 0.88007
    elsif((getWeight >= 250) && (getWeight < 260))
        constant = 0.98951
        coefficient = 0.878147
    elsif((getWeight >= 260) && (getWeight < 270))
        constant = 1.18077
        coefficient = 0.880769
    elsif((getWeight >= 270) && (getWeight < 280))
        constant = 1.53963
        coefficient = 0.88007
    elsif((getWeight >= 280) && (getWeight < 290))
        constant = 1.97692
        coefficient = 0.878147
    elsif((getWeight >= 290) && (getWeight < 300))
        constant = 2.15769
        coefficient = 0.880769
    elsif((getWeight >= 300) && (getWeight < 310))
        constant = 2.55758
        coefficient = 0.879545
    elsif((getWeight >= 310) && (getWeight < 320))
        constant = 2.85268
        coefficient = 0.88007
    elsif((getWeight >= 320) && (getWeight < 330))
        constant = 3.25641
        coefficient = 0.878846
    elsif((getWeight >= 330) && (getWeight < 340))
        constant = 3.53939
        coefficient = 0.879545
    elsif((getWeight >= 340) && (getWeight < 350))
        constant = 3.8324
        coefficient = 0.88007
    elsif((getWeight >= 350) && (getWeight < 360))
        constant = 4.19697
        coefficient = 0.879545
    elsif((getWeight >= 360) && (getWeight < 370))
        constant = 4.5303
        coefficient = 0.879545
    elsif((getWeight >= 370) && (getWeight < 380))
        constant = -7.38083
        coefficient = 1.04605
    elsif((getWeight >= 380) && (getWeight < 390))
        constant = 5.15198
        coefficient = 0.88007
    end

    predictedFromBraWaist = (constant + (coefficient * getBraBust))

    deltaWaist = (predictedFromHWWaist - predictedFromBraWaist).abs

    if (getBodyShape == "Triangle")
      predictedFromHWHip += deltaWaist
    end

    trueBust = (((predictedFromHWBust * 4) + (predictedFromBraBust * 6)) / 10)
    trueWaist = (((predictedFromHWWaist * 4) + (predictedFromBraWaist * 6)) / 10)
    trueHip = predictedFromHWHip

    results_hash = {}
    results_hash[:true_bust] = trueBust
    results_hash[:true_waist] = trueWaist
    results_hash[:true_hip] = trueHip

    return results_hash
  end

  def self.calcFromHeightWeightStore(user) #priority 4
    if user.height_cm
      getHeight = (user.height_cm.to_f) * 0.393701
    elsif user.height_ft
      getHeight = (user.height_ft.to_f * 12) + user.height_in.to_f
    end

    if user.weight_type == "Lbs"
      getWeight = user.weight.to_f
    elsif user.weight_type == "Kg"
      getWeight = ((user.weight.to_f) * 2.20462)
    end
    # getBraBust = user.bust #(bra size)

    if ((getHeight >= 48) && (getHeight <= 59))
        predictedBust = (39.8264 + (getHeight * (-0.302730)) + (getWeight * 0.120800))
        predictedWaist = (35.8677 + (getHeight * (-0.384542)) + (getWeight * 0.138296))
        predictedHip = (33.4821 + (getHeight * (-0.166397)) + (getWeight * 0.118986))
        predictedInseam = (-7.39781 + (getHeight * 0.602135)) + (getWeight * (-0.0133127))
    elsif ((getHeight >= 60) && (getHeight <=71))
        predictedBust = (39.8602 + (getHeight * (-0.303865)) + (getWeight * 0.120917))
        predictedWaist = (60.0865 + (getHeight * (-0.763514)) + (getWeight * 0.141982))
        predictedHip = (33.3585 + (getHeight * (-0.162360)) + (getWeight * 0.118724))
        predictedInseam = (-7.85941 + (getHeight * 0.608293)) + (getWeight * (-0.0128906))
    elsif ((getHeight >= 72) && (getHeight <=80))
        predictedBust = (39.7441 + (getHeight * (-0.302251)) + (getWeight * 0.120945))
        predictedWaist = (39.4437 + (getHeight * (-0.446287)) + (getWeight * 0.139020))
        predictedHip = (33.0163 + (getHeight * (-0.160000)) + (getWeight * 0.119220))
        predictedInseam = (-10.1759 + (getHeight * 0.636287)) + (getWeight * (-0.0117900))
    end

    #Variable Instantiation
    topBustMax = 0
    topBustMin = 0
    topWaistMax = 0
    topWaistMin = 0
    topHipMax = 0
    topHipMin = 0

    bottomBustMax = 0
    bottomBustMin = 0
    bottomWaistMax = 0
    bottomWaistMin = 0
    bottomHipMax = 0
    bottomHipMin = 0

    countTopMinBust = 0
    countTopMaxBust = 0
    countTopMinWaist = 0
    countTopMaxWaist = 0
    countTopMinHip = 0
    countTopMaxHip = 0

    countTopBustLoops = 0
    countTopWaistLoops = 0
    countTopHipLoops = 0

    countBottomMinBust = 0
    countBottomMaxBust = 0
    countBottomMinWaist = 0
    countBottomMaxWaist = 0
    countBottomMinHip = 0
    countBottomMaxHip = 0

    countBottomBustLoops = 0
    countBottomWaistLoops = 0
    countBottomHipLoops = 0

    storeName = user.tops_store.upcase
    storeSizeTop = user.tops_size

    resultTopBust = Store.where(store_name: storeName, feature: "BUST")
    resultTopWaist = Store.where(store_name: storeName, feature: "WAIST")
    resultTopHip = Store.where(store_name: storeName, feature: "HIP")

    #Get Data For Top Bust

    numRowsTopBust = resultTopBust.count
    a = 0
    while a < resultTopBust.count

      countTopBustLoops+= 1

      if((resultTopBust[a].store_size.include?(storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopBust[a].store_size.include?( "2" + storeSizeTop)))

        topBustMin = topBustMin + resultTopBust[a].size_min.to_f
        topBustMax = topBustMax + resultTopBust[a].size_max.to_f

        countTopMinBust += 1
        countTopMaxBust += 1
        break
      elsif(resultTopBust[a].store_size == storeSizeTop)

        topBustMin = topBustMin + resultTopBust[a].size_min.to_f
        topBustMax = topBustMax + resultTopBust[a].size_max.to_f

        countTopMinBust+= 1
        countTopMaxBust+= 1
        a += 1
      elsif(numRowsTopBust == countTopBustLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        a += 1
      end
    end


    #Get Data For Top Waist
    numRowsTopWaist = resultTopWaist.count
    b = 0
    while b < resultTopWaist.count

      countTopWaistLoops+=1
      if((resultTopWaist[b].store_size.include?(storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopWaist[b].store_size.include?( "2" + storeSizeTop)))

        topWaistMin = topWaistMin + resultTopWaist[b].size_min.to_f
        topWaistMax = topWaistMax + resultTopWaist[b].size_max.to_f

        countTopMinWaist+=1
        countTopMaxWaist+=1

        break
      elsif(resultTopWaist[b].store_size == storeSizeTop)

        topWaistMin = topWaistMin + resultTopWaist[b].size_min.to_f
        topWaistMax = topWaistMax + resultTopWaist[b].size_max.to_f

        countTopMinWaist+=1
        countTopMaxWaist+=1
        b+=1
      elsif(numRowsTopWaist == countTopWaistLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        b += 1
      end
    end

    numRowsTopHip = resultTopHip.count
    c = 0
    while c < resultTopHip.count

      countTopHipLoops+=1
      if((resultTopHip[c].store_size.include?(storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?("X" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?("0" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?( "1" + storeSizeTop)) &&
        !(resultTopHip[c].store_size.include?( "2" + storeSizeTop)))

        topHipMin = topHipMin + resultTopHip[c].size_min.to_f
        topHipMax = topHipMax + resultTopHip[c].size_max.to_f

        countTopMinHip+=1
        countTopMaxHip+=1
        break
      elsif(resultTopHip[c].store_size == storeSizeTop)
        topHipMin = topHipMin + resultTopHip[c].size_min.to_f
        topHipMax = topHipMax + resultTopHip[c].size_max.to_f

        countTopMinHip+=1
        countTopMaxHip+=1
        c+=1
      elsif(numRowsTopHip == countTopHipLoops)
        puts storeSizeTop + " not found in " + storeName + "<br>"
        break
      else
        c += 1
      end
    end

    storeName = user.bottoms_store.upcase
    storeSizeBottom = user.bottoms_size

    resultBottomBust = Store.where(store_name: storeName, feature: "BUST")
    resultBottomWaist = Store.where(store_name: storeName, feature: "WAIST")
    resultBottomHip = Store.where(store_name: storeName, feature: "HIP")

    numRowsBottomBust = resultBottomBust.count
    i = 0
    while i < resultBottomBust.count

      countBottomBustLoops+=1
      if((resultBottomBust[i].store_size.include?(storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomBust[i].store_size.include?( "2" + storeSizeBottom)))

        bottomBustMin = bottomBustMin + resultBottomBust[i].size_min.to_f
        bottomBustMax = bottomBustMax + resultBottomBust[i].size_max.to_f

        countBottomMinBust+=1
        countBottomMaxBust+=1

        break
      elsif(resultBottomBust[i].store_size == storeSizeBottom)

        bottomBustMin = bottomBustMin + resultBottomBust[i].size_max.to_f
        bottomBustMax = bottomBustMax + resultBottomBust[i].size_min.to_f

        countBottomMinBust+=1
        countBottomMaxBust+=1
        i+=1
      elsif(numRowsBottomBust == countBottomBustLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        i += 1
      end
    end

    numRowsBottomWaist = resultBottomWaist.count
    j = 0
    while j < resultBottomWaist.count

      countBottomWaistLoops+=1

      if((resultBottomWaist[j].store_size.include?(storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomWaist[j].store_size.include?( "2" + storeSizeBottom)))

        bottomWaistMin = bottomWaistMin + resultBottomWaist[j].size_min.to_f
        bottomWaistMax = bottomWaistMax + resultBottomWaist[j].size_max.to_f

        countBottomMinWaist+=1
        countBottomMaxWaist+=1
        break
      elsif(resultBottomWaist[j].store_size == storeSizeBottom)
        bottomWaistMin = bottomWaistMin + resultBottomWaist[j].size_min.to_f
        bottomWaistMax = bottomWaistMax + resultBottomWaist[j].size_max.to_f

        countBottomMinWaist+=1
        countBottomMaxWaist+=1
        j+=1
      elsif(numRowsBottomWaist == countBottomWaistLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        j += 1
      end
    end

    numRowsBottomHip = resultBottomHip.count
    k = 0
    while k < resultBottomHip.count

      countBottomHipLoops+=1
      if((resultBottomHip[k].store_size.include?(storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?("X" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?("0" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?( "1" + storeSizeBottom)) &&
        !(resultBottomHip[k].store_size.include?( "2" + storeSizeBottom)))

        bottomHipMin = bottomHipMin + resultBottomHip[k].size_min.to_f
        bottomHipMax = bottomHipMax + resultBottomHip[k].size_max.to_f

        countBottomMinHip+=1
        countBottomMaxHip+=1
        break
      elsif(resultBottomHip[k].store_size == storeSizeBottom)
        bottomHipMin = bottomHipMin + resultBottomHip[k].size_min.to_f
        bottomHipMax = bottomHipMax + resultBottomHip[k].size_max.to_f

        countBottomMinHip+=1
        countBottomMaxHip+=1
        k+=1
      elsif(numRowsBottomHip == countBottomHipLoops)
        puts storeSizeBottom + " not found in " + storeName + "<br>"
        break
      else
        k += 1
      end
    end

    averageTopBustMin = ((topBustMin.to_f) / countTopMinBust)
    averageTopBustMax = (topBustMax.to_f / countTopMaxBust)
    averageTopWaistMin = (topWaistMin.to_f / countTopMinWaist)
    averageTopWaistMax = (topWaistMax.to_f / countTopMaxWaist)
    averageTopHipMin = (topHipMin.to_f / countTopMinHip)
    averageTopHipMax = (topHipMax.to_f / countTopMaxHip)

    averageBottomBustMin = (bottomBustMin.to_f / countBottomMinBust)
    averageBottomBustMax = (bottomBustMax.to_f / countBottomMaxBust)
    averageBottomWaistMin = (bottomWaistMin.to_f / countBottomMinWaist)
    averageBottomWaistMax = (bottomWaistMax.to_f / countBottomMaxWaist)
    averageBottomHipMin = (bottomHipMin.to_f / countBottomMinHip)
    averageBottomHipMax = (bottomHipMax.to_f/ countBottomMaxHip)

    averageTopBust = (((averageTopBustMin.to_f * 6) + (averageTopBustMax * 4)) / 10)
    averageTopWaist = (((averageTopWaistMin.to_f * 6) + (averageTopWaistMax * 4)) / 10)
    averageTopHip = (((averageTopHipMin.to_f * 6) + (averageTopHipMax * 4)) / 10)

    averageBottomBust = (((averageBottomBustMin.to_f * 6) + (averageBottomBustMax * 4)) / 10)
    averageBottomWaist = (((averageBottomWaistMin.to_f * 6) + (averageBottomWaistMax * 4)) / 10)
    averageBottomHip = (((averageBottomHipMin.to_f * 6) + (averageBottomHipMax * 4)) / 10)

    averageBust = (((averageTopBust.to_f * 9) + averageBottomBust) / 10)
    averageWaist = (((averageTopWaist.to_f * 2) + (averageBottomWaist * 8)) / 10)
    averageHip = ((averageTopHip.to_f + (averageBottomHip * 9)) / 10)

    trueBust = predictedBust + averageBust
    trueWaist = ((predictedWaist.to_f * 4) + (averageWaist * 6)) / 10
    trueHip = ((predictedHip.to_f * 4) + (averageHip * 6)) / 10

    results_hash = {}
    results_hash[:true_bust] = trueBust
    results_hash[:true_waist] = trueWaist
    results_hash[:true_hip] = trueHip
    return results_hash
  end

  def getUserSizeForStoreTop(user, storeName)
    bustIn = user.bust
    waistIn = user.waist

    resultBust = Store.where(store_name: storeName, feature: "BUST")

    resultWaist = Store.where(store_name: storeName, feature: "WAIST")

    previousMinBust = 0
    previousMaxBust = 0
    previousMinWaist = 0
    previousMaxWaist = 0

    previousStoreSizeBust = ""
    previousStoreSizeWaist = ""

    previousStoreNameBust = ""
    previousStoreNameWaist = ""

    perfectBustArray = {}
    perfectWaistArray = {}

    tightBustArray = {}
    tightWaistArray = {}

    looseBustArray = {}
    looseWaistArray = {}

    sizeOfResultBust = resultBust.count
    if(sizeOfResultBust < 1)
      return "Bad Read Bust"
    end
    countBustLoops = 0

    resultBust.each do |res_bust|

      countBustLoops+=1

      if ((res_bust.size_min.to_f < bustIn) && (res_bust.size_max.to_f > bustIn))

        perfectBustArray[res_bust.id] = res_bust.store_size
      else
        if (res_bust.size_min.to_f == bustIn)

          looseBustArray[res_bust.id = res_bust.store_size]
        elsif (res_bust.size_max.to_f == bustIn)

          tightBustArray[res_bust.id] = res_bust.store_size
        elsif ((bustIn > previousMaxBust) && (bustIn < res_bust.size_min.to_f))
          if (((previousMaxBust + res_bust.size_min.to_f) / 2) == bustIn)

            looseBustArray[previousStoreNameBust] = previousStoreSizeBust
            tightBustArray[res_bust.id] = res_bust.store_size
          elsif (((previousMaxBust + res_bust.size_min.to_f) / 2) > bustIn)

            looseBustArray[previousStoreNameBust] = previousStoreSizeBust
          elsif (((previousMaxBust + res_bust.size_min.to_f) / 2) < bustIn)

            tightBustArray[res_bust.id] = res_bust.store_size
          end
        elsif ((previousStoreNameBust != res_bust.id) && ((bustIn - 1) == previousMaxBust))

          tightBustArray[previousStoreNameBust] = previousStoreSizeBust
        elsif ((countBustLoops == sizeOfResultBust) && ((bustIn - 1) == res_bust.size_max.to_f))

          tightBustArray[res_bust.id] = res_bust.store_size
        end
      end

      previousStoreNameBust = res_bust.id
      previousStoreSizeBust = res_bust.store_size
      previousMinBust = res_bust.size_min.to_f
      previousMaxBust = res_bust.size_max.to_f

    end

    sizeOfResultWaist = resultWaist.count
    if(sizeOfResultWaist < 1)
      return "Bad Read Waist"
    end
    countWaistLoops = 0
    resultWaist.each do |res_waist|

      countWaistLoops+=1

      if ((res_waist.size_min.to_f < bustIn) && (res_waist.size_max.to_f > bustIn))

        perfectBustArray[res_waist.id] = res_waist.store_size
      else
        if (res_waist.size_min.to_f == bustIn)

          looseBustArray[res_waist.id] = res_waist.store_size
        elsif (res_waist.size_max.to_f == bustIn)

          tightBustArray[res_waist.id] = res_waist.store_size
        elsif ((bustIn > previousMaxBust) && (bustIn < res_waist.size_min.to_f))
          if (((previousMaxBust + res_waist.size_min.to_f) / 2) == bustIn)

            looseBustArray[previousStoreNameBust] = previousStoreSizeBust
            tightBustArray[res_waist.id] = res_waist.store_size
          elsif (((previousMaxBust + res_waist.size_min.to_f) / 2) > bustIn)

            looseBustArray[previousStoreNameBust] = previousStoreSizeBust
          elsif (((previousMaxBust + res_waist.size_min.to_f) / 2) < bustIn)

            tightBustArray[res_waist.id] = res_waist.store_size
          end
        elsif ((previousStoreNameBust != res_waist.id) && ((bustIn - 1) == previousMaxBust))

          tightBustArray[previousStoreNameBust] = previousStoreSizeBust
        elsif ((countBustLoops == sizeOfResultBust) && ((bustIn - 1) == res_waist.size_max.to_f))

          tightBustArray[res_waist.id] = res_waist.store_size
        end
      end

      previousStoreNameWaist = res_waist.id
      previousStoreSizeWaist = res_waist.store_size
      previousMinWaist = res_waist.size_min.to_f
      previousMaxWaist = res_waist.size_max.to_f
    end

    #Perfect vs All
    #Perfect vs Perfect
    perfectWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        perfectBustSize = perfectBustArray[storeNameKey]
        perfectWaistSize = storeSizeValue

        if (perfectBustSize == perfectWaistSize)
          return perfectBustSize
        elsif (perfectBustSize > perfectWaistSize)
          return perfectBustSize
        elsif (perfectBustSize < perfectWaistSize)
          return perfectWaistSize
        end

      end
    end

    #Perfect vs Tight
    perfectWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        tightBustSize = tightBustArray[storeNameKey]
        perfectWaistSize = storeSizeValue

        if (tightBustSize == perfectWaistSize)
          return tightBustSize
        elsif (tightBustSize > perfectWaistSize)
          return tightBustSize
        elsif (tightBustSize < perfectWaistSize)
          return perfectWaistSize
        end

      end
    end

    perfectBustArray.each do |storeNameKey,storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        tightWaistSize = tightWaistArray[storeNameKey]
        perfectBustSize = storeSizeValue

        if (perfectBustSize == tightWaistSize)
          return perfectBustSize
        elsif (perfectBustSize > tightWaistSize)
          return perfectBustSize
        elsif (perfectBustSize < tightWaistSize)
          return tightWaistSize
        end
      end
    end

    #Perfect vs Loose
    perfectWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        looseBustSize = looseBustArray[storeNameKey]
        perfectWaistSize = storeSizeValue

        if (looseBustSize == perfectWaistSize)
          return looseBustSize
        elsif (looseBustSize > perfectWaistSize)
          return perfectWaistSize
        elsif (looseBustSize < perfectWaistSize)
          return looseBustSize
        end

      end
    end

    perfectBustArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))
        looseWaistSize = looseWaistArray[storeNameKey]
        perfectBustSize = storeSizeValue

        if (perfectBustSize == looseWaistSize)
          return perfectBustSize
        elsif (perfectBustSize > looseWaistSize)
          return looseWaistSize
        elsif (perfectBustSize < looseWaistSize)
          return perfectBustSize
        end
      end
    end

    #Tight vs All
    #Tight vs Tight
    tightWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))
        tightBustSize = tightBustArray[tightStoreNameKey]
        tightWaistSize = tightStoreSizeValue

        if (tightWaistSize > tightBustSize)
          return tightWaistSize
        elsif (tightWaistSize < tightBustSize)
          return tightBustSize
        elsif (tightWaistSize == tightBustSize)
          return tightBustSize
        end

      end
    end

    #Tight vs Loose
    tightBustArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))
        looseWaistSize = looseWaistArray[tightStoreNameKey]
        tightBustSize = tightStoreSizeValue

        if (looseWaistSize > tightBustSize)
          return looseWaistSize
        elsif (looseWaistSize < tightBustSize)
          return tightBustSize
        elsif (looseWaistSize == tightBustSize)
          return tightBustSize
        end

      end
    end

    tightWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        looseBustSize = looseBustArray[tightStoreNameKey]
        tightWaistSize = tightStoreSizeValue

        if (tightWaistSize > looseBustSize)
          return looseBustSize
        elsif (tightWaistSize < looseBustSize)
          return looseBustSize
        elsif (tightWaistSize == looseBustSize)
          return looseBustSize
        end
      end
    end

    #Loose vs All
    #Loose vs Loose
    looseWaistArray.each do |storeNameKey,storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        looseBustSize = looseBustArray[looseStoreNameKey]
        looseWaistSize = looseStoreSizeValue

        if (looseWaistSize > looseBustSize)
          return looseBustSize
        elsif (looseWaistSize < looseBustSize)
          return looseWaistSize
        elsif (looseWaistSize == looseBustSize)
          return looseBustSize
        end
      end
    end

    return "No Size In Store"
  end

  def getUserSizeForStoreBottom(user, storeName)

    # userBWHSQL = "SELECT Waist, Hip FROM users WHERE Email = '" + emailIn + "'"
    #
    # resultMeasure = mysqli_query(dataTransfer, userBWHSQL)
    # rowOFMeasure = mysqli_fetch_row(resultMeasure)
    waistIn = user.waist
    hipIn = user.hip

    resultWaist = Store.where(store_name: storeName, feature: "waist")
    # "SELECT STORE_ID, store_size, size_min.to_f, size_Max FROM sizes WHERE (store_ID = '" + storeName + "' AND type = 'WAIST')"
    resultHip = Store.where(store_name: storeName, feature: "hip")
    # "SELECT STORE_ID, store_size, size_min.to_f, size_Max FROM sizes WHERE (store_ID = '" + storeName + "' AND type = 'HIP')"

    previousMinWaist = 0
    previousMaxWaist = 0
    previousMinHip = 0
    previousMaxHip = 0

    previousStoreSizeWaist = ""
    previousStoreSizeHip = ""

    previousStoreNameWaist = ""
    previousStoreNameHip = ""

    perfectWaistArray = {}
    perfectHipArray = {}

    tightWaistArray = {}
    tightHipArray = {}

    looseWaistArray = {}
    looseHipArray = {}

    # resultWaist = mysqli_query(dataTransfer, waistStoreSizeSQL)
    sizeOfResultWaist = resultWaist.count
    if(sizeOfResultWaist < 1)
      return "Bad Read Waist"
    end
    countWaistLoops = 0

    resultWaist.each do |res_waist|

      countWaistLoops+= 1

      if ((res_waist.size_min.to_f < waistIn) && (res_waist.size_max.to_f > waistIn))

        perfectWaistArray[res_waist.id] = res_waist.store_size

      else
        if (res_waist.size_min.to_f == waistIn)

          looseWaistArray[res_waist.id] = res_waist.store_size
        elsif (res_waist.size_max.to_f == waistIn)

          tightWaistArray[res_waist.id] = res_waist.store_size
        elsif ((waistIn > previousMaxWaist) && (waistIn < res_waist.size_min.to_f))

          if (((previousMaxWaist + res_waist.size_min.to_f) / 2) == waistIn)

            looseWaistArray[previousStoreNameWaist] = previousStoreSizeWaist
            tightWaistArray[res_waist.id] = res_waist.store_size
          elsif (((previousMaxWaist + res_waist.size_min.to_f) / 2) > waistIn)

            looseWaistArray[previousStoreNameWaist] = previousStoreSizeWaist
          elsif (((previousMaxWaist + res_waist.size_min.to_f) / 2) < waistIn)

            tightWaistArray[res_waist.id] = res_waist.store_size
          end
        elsif ((previousStoreNameWaist != res_waist.id) && ((waistIn - 1) == previousMaxWaist))

          tightWaistArray[previousStoreNameWaist] = previousStoreSizeWaist
        elsif ((countWaistLoops == sizeOfResultWaist) && ((waistIn - 1) == res_waist.size_max.to_f))

          tightWaistArray[res_waist.id] = res_waist.store_size
        end
      end

      previousStoreNameWaist = res_waist.id
      previousStoreSizeWaist = res_waist.store_size
      previousMinWaist = res_waist.size_min.to_f
      previousMaxWaist = res_waist.size_max.to_f

    end

    # resultHip = mysqli_query(dataTransfer, hipStoreSizeSQL)
    sizeOfResultHip = resultHip.count
    if(sizeOfResultHip < 1)
      return "Bad Read Hip"
    end
    countHipLoops = 0

    resultHip.each do |res_hip|

      countWaistLoops+= 1

      if ((res_hip.size_min.to_f < waistIn) && (res_hip.size_max.to_f > waistIn))

        perfectWaistArray[res_hip.id] = res_hip.store_size

      else
        if (res_hip.size_min.to_f == waistIn)

          looseWaistArray[res_hip.id] = res_hip.store_size
        elsif (res_hip.size_max.to_f == waistIn)

          tightWaistArray[res_hip.id] = res_hip.store_size
        elsif ((waistIn > previousMaxWaist) && (waistIn < res_hip.size_min.to_f))

          if (((previousMaxWaist + res_hip.size_min.to_f) / 2) == waistIn)

            looseWaistArray[previousStoreNameWaist] = previousStoreSizeWaist
            tightWaistArray[res_hip.id] = res_hip.store_size
          elsif (((previousMaxWaist + res_hip.size_min.to_f) / 2) > waistIn)

            looseWaistArray[previousStoreNameWaist] = previousStoreSizeWaist
          elsif (((previousMaxWaist + res_hip.size_min.to_f) / 2) < waistIn)

            tightWaistArray[res_hip.id] = res_hip.store_size
          end
        elsif ((previousStoreNameWaist != res_hip.id) && ((waistIn - 1) == previousMaxWaist))

          tightWaistArray[previousStoreNameWaist] = previousStoreSizeWaist
        elsif ((countWaistLoops == sizeOfResultWaist) && ((waistIn - 1) == res_hip.size_max.to_f))

          tightWaistArray[res_hip.id] = res_hip.store_size
        end
      end

      previousStoreNameWaist = res_hip.id
      previousStoreSizeWaist = res_hip.store_size
      previousMinWaist = res_hip.size_min.to_f
      previousMaxWaist = res_hip.size_max.to_f

    end
    #Perfect vs All
    #Perfect vs Perfect
    perfectWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        perfectBustSize = perfectHipArray[storeNameKey]
        perfectWaistSize = storeSizeValue

        if (perfectBustSize == perfectWaistSize)
          return perfectBustSize
        elsif (perfectBustSize > perfectWaistSize)
          return perfectBustSize
        elsif (perfectBustSize < perfectWaistSize)
          return perfectWaistSize
        end

      end
    end

    #Perfect vs Tight
    perfectWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        tightBustSize = tightHipArray[storeNameKey]
        perfectWaistSize = storeSizeValue

        if (tightBustSize == perfectWaistSize)
          return tightBustSize
        elsif (tightBustSize > perfectWaistSize)
          return tightBustSize
        elsif (tightBustSize < perfectWaistSize)
          return perfectWaistSize
        end

      end
    end

    perfectHipArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))
        tightWaistSize = tightWaistArray[storeNameKey]
        perfectBustSize = storeSizeValue

        if (perfectBustSize == tightWaistSize)
          return perfectBustSize
        elsif (perfectBustSize > tightWaistSize)
          return perfectBustSize
        elsif (perfectBustSize < tightWaistSize)
          return tightWaistSize
        end
      end
    end

    #Perfect vs Loose
    perfectWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        looseBustSize = looseHipArray[storeNameKey]
        perfectWaistSize = storeSizeValue

        if (looseBustSize == perfectWaistSize)
          return looseBustSize
        elsif (looseBustSize > perfectWaistSize)
          return perfectWaistSize
        elsif (looseBustSize < perfectWaistSize)
          return looseBustSize
        end

      end
    end

    perfectHipArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))
        looseWaistSize = looseWaistArray[storeNameKey]
        perfectBustSize = storeSizeValue

        if (perfectBustSize == looseWaistSize)
          return perfectBustSize
        elsif (perfectBustSize > looseWaistSize)
          return looseWaistSize
        elsif (perfectBustSize < looseWaistSize)
          return perfectBustSize
        end
      end
    end

    #Tight vs All
    #Tight vs Tight
    tightWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))
        tightBustSize = tightHipArray[tightStoreNameKey]
        tightWaistSize = tightStoreSizeValue

        if (tightWaistSize > tightBustSize)
          return tightWaistSize
        elsif (tightWaistSize < tightBustSize)
          return tightBustSize
        elsif (tightWaistSize == tightBustSize)
          return tightBustSize
        end

      end
    end

    #Tight vs Loose
    tightHipArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))
        looseWaistSize = looseWaistArray[tightStoreNameKey]
        tightBustSize = tightStoreSizeValue

        if (looseWaistSize > tightBustSize)
          return looseWaistSize
        elsif (looseWaistSize < tightBustSize)
          return tightBustSize
        elsif (looseWaistSize == tightBustSize)
          return tightBustSize
        end

      end
    end

    tightWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        looseBustSize = looseHipArray[tightStoreNameKey]
        tightWaistSize = tightStoreSizeValue

        if (tightWaistSize > looseBustSize)
          return looseBustSize
        elsif (tightWaistSize < looseBustSize)
          return looseBustSize
        elsif (tightWaistSize == looseBustSize)
          return looseBustSize
        end
      end
    end

    #Loose vs All
    #Loose vs Loose
    looseWaistArray.each do |storeNameKey, storeSizeValue|

      if (perfectBustArray.key?(storeNameKey))

        looseBustSize = looseHipArray[looseStoreNameKey]
        looseWaistSize = looseStoreSizeValue

        if (looseWaistSize > looseBustSize)
          return looseBustSize
        elsif (looseWaistSize < looseBustSize)
          return looseWaistSize
        elsif (looseWaistSize == looseBustSize)
          return looseBustSize
        end
      end
    end

    return "No Size In Store"
  end


end
