module voluptuousCSVToHumanReadable
  
  def loadMoreVoluptuous(nameIn)
    require 'csv'
    #specify file_location
    csv_text = File.read(file_location)
    csv = CSV.parse(csv_text, :headers => true )

    filteredClothes = []
    names = []

    puts "<table>"
    puts "<tr>"

    csv.each do |lineOfCSV|

      # lineOfCSV = fgetcsv(file, null, ",", "\"")

      isDress = lineOfCSV[0]
      isBlouse = lineOfCSV[2]
      isJean = lineOfCSV[4]
      isJacket = lineOfCSV[6]
      isJumpsuit = lineOfCSV[8]
      isSwimsuit = lineOfCSV[10]
      linkToItem = lineOfCSV[13]
      name = lineOfCSV[14]
      oldPrice = lineOfCSV[15] #These are currently both in the same column. You could create your own splitting function or
      newPrice = lineOfCSV[16] #get the store to give it to you in diff columns.
      description = lineOfCSV[18]
      sizes = (lineOfCSV[20].gsub('Choose an option', '')).gsub('X', 'X ')
      picSRC = lineOfCSV[23]

      if (names.include?(name))
        filteredClothes.each do |element|
          if (element[7] == name)
            newDetails = element[8] + "<br>" + lineOfCSV[18]
            element[8] = newDetails
          end
        end
      else
        #   0		1	2	   3	     4		5		6	7	8		9	10	11		12
        contents = [picSRC, isDress, isBlouse, isJean, isJacket, isJumpsuit, isSwimsuit, name, description, sizes, oldPrice, newPrice, linkToItem]
        filteredClothes << contents
        names << name
      end
    end

    fil_ter = []

    filteredClothes.each do |element_j|

      if (element_j[7] == nameIn)
        fil_ter << element
        # puts "<table>"
        # puts "<tr><td colspan='2' style='min-width: 50px font-size: 45px'>" + filteredClothes[j][7] + "</td></tr>"
        # puts "<tr><td rowspan='4'><img src='" + filteredClothes[j][0] + "'></td></tr>"
        # puts "<tr><td style='min-width: 50px max-width: 300px'>" + filteredClothes[j][8] + "</td></tr>"
        # puts "<tr><td style='min-width: 50px'>" + filteredClothes[j][9] +"</td></tr>"
        # puts "<tr><td style='min-width: 50px'><s>" + filteredClothes[j][10] + "</s> " + filteredClothes[j][11] + "</td></tr>"
        # puts "</table>"
        #
        # break

      end
      #else{
      #puts "Name From List: " . filteredClothes[j][3] . ", Passed Name: " . nameIn . "<br>"
      #}
    end

  end

  def readVoluptuousCSVSize(topSize, bottomSize)
    require 'csv'
    #specify file_location
    csv_text = File.read(file_location)
    csv = CSV.parse(csv_text, :headers => true )

    filteredClothes = []
    names = []

    # puts "<table border='1'>"
    #
    # puts "<tr>"
    # puts "<th><b>Picture</b></th>"
    # puts "<th><b>Name</b></th>"
    # puts "<th><b>Details</b></th>"
    # puts "<th><b>Size</b></th>"
    # puts "<th><b>Price</b></th>"
    # puts "<th><b>Link To Item</b></th>"
    # puts "</tr>"

    csv.each do |lineOfCSV|

      # lineOfCSV = fgetcsv(file, null, ",", "\"")

      isDress = lineOfCSV[0]
      isBlouse = lineOfCSV[2]
      isJean = lineOfCSV[4]
      isJacket = lineOfCSV[6]
      isJumpsuit = lineOfCSV[8]
      isSwimsuit = lineOfCSV[10]
      linkToItem = lineOfCSV[13]
      name = lineOfCSV[14]
      oldPrice = lineOfCSV[15] #These are currently both in the same column. You could create your own splitting function or
      newPrice = lineOfCSV[16] #get the store to give it to you in diff columns.
      description = lineOfCSV[18]
      sizes = (lineOfCSV[20].gsub('Choose an option', '')).gsub('X', 'X ')
      picSRC = lineOfCSV[23]

      if (names.include?(name))
        filteredClothes.each do |element_i|
          if (element_i[7] == name)
            newDetails = element_i[8] + "<br>" + lineOfCSV[18]
            element_i[8] = newDetails
          end
        end
      else
        contents = [picSRC, isDress, isBlouse, isJean, isJacket, isJumpsuit, isSwimsuit, name, description, sizes, oldPrice, newPrice, linkToItem]
        filteredClothes << contents
        names << name
      end
    end

    filteredClothes.each do |element_k|
      if (element_k[1] != "" || element_k[2] != "" || element_k[4] != "")
        #make your own method for ruby version of strspn
        if (strspn(element_k[9], topSize) >= 2)
          # puts "<tr>"
          # puts "<td><img src='" + element_k[0] + "'></td>"
          # puts "<td style='min-width: 50px'>" + element_k[3] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[4] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[5] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[6] + "</td>"
          # puts "<td style='min-width: 50px'><a href='"+ element_k[7] + "' target='_blank'>Buy Now</a></td>"
          # puts "</tr>"
          #do something, most likely store this element in some array.
        elsif (strspn(topSize, element_k[9]) >= 2)
          # puts "<tr>"
          # puts "<td><img src='" + element_k[0] + "'></td>"
          # puts "<td style='min-width: 50px'>" + element_k[3] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[4] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[5] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[6] + "</td>"
          # puts "<td style='min-width: 50px'><a href='" + element_k[7] + "' target='_blank'>Buy Now</a></td>"
          # puts "</tr>"
          #do something
        end
      elsif (element_k[3] != "")
        if (strspn(element_k[9], bottomSize) >= 2)
          # puts "<tr>"
          # puts "<td><img src='" + element_k[0] + "'></td>"
          # puts "<td style='min-width: 50px'>" + element_k[3] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[4] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[5] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[6] + "</td>"
          # puts "<td style='min-width: 50px'><a href='" + element_k[7] + "' target='_blank'>Buy Now</a></td>"
          # puts "</tr>"
          #do something
        elsif (strspn(bottomSize, element_k[9]) >= 2)
          # puts "<tr>"
          # puts "<td><img src='" + element_k[0] + "'></td>"
          # puts "<td style='min-width: 50px'>" + element_k[3] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[4] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[5] + "</td>"
          # puts "<td style='min-width: 50px'>" + element_k[6] + "</td>"
          # puts "<td style='min-width: 50px'><a href='" + element_k[7] + "' target='_blank'>Buy Now</a></td>"
          # puts "</tr>"
          #do something.
        end
      end
    end

    # puts "</table>"
  end
end
