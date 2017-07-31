// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require_tree .
//= require cable


$(document).ready(function() {

  setTimeout(function(){
    $('#alert').slideUp();
  }, 2000);

  setTimeout(function(){
    $('#notice').slideUp();
  }, 2000);

  $('.bodyshape').on('click', function(){
    $('.bodyshape').removeClass('bodyshape-clicked').css('opacity', '1');
    $(this).addClass('bodyshape-clicked').css('opacity', '0.3');
  })

  $('.bodyshape-submit').on('click', function(e){
    // e.preventDefault();
    var bodyShape = $('.bodyshape-clicked').attr('class').split(' ')[1];
    $.ajax({
      url: '/create_body_shape',
      method: 'post',
      data: {
        body_shape: bodyShape
      }
    })
  })

  $(".button_submit").on("click", function(e) {
    e.preventDefault();
    var issuesTop = [];
    var issuesBottom = [];
    var insecuritiesTop = [];
    var insecuritiesBottom = [];
    $(':checkbox:checked').each(function(i){
      if ($(this).attr('name')==="issue_top[]"){
        issuesTop.push($(this).val());
      }
      else if ($(this).attr('name')==="issue_bottom[]"){
        issuesBottom.push($(this).val());
      }
      else if ($(this).attr('name')==="insecurity_bottom[]"){
        insecuritiesBottom.push($(this).val());
      }
      else if ($(this).attr('name')==="insecurity_top[]"){
        insecuritiesTop.push($(this).val());
      }
    });
    $.ajax({
      url: '/update_issues',
      method: 'put',
      data: {
        issues_top: issuesTop, issues_bottom: issuesBottom,
        insecurities_top: insecuritiesTop, insecurities_bottom: insecuritiesBottom
      }
    }).done(function(){
      $(".form1 > form").submit();
    })
  })

  var allItems = $('.filters-container > h4')[3];
  $(allItems).css('color', 'red').css('text-decoration', 'underline');


  $('.filter').click(function(){
    $('.filter').css('color', 'black').css('text-decoration', 'none');
    $(this).css('color', 'red').css('text-decoration', 'underline');
    var filter = $(this).html();
    $.ajax({
      url: '/products',
      method: "get",
      data: {
        filter: filter
      },
      dataType: 'json'
    }).done(function(data){
      var results = $("<div>").addClass('index');
      for(i=0; i < data.length; i++){
        var productId = data[i]['id'];
        var url = 'http://localhost:3000/products/' + productId;
        var link = $('<a>').attr('href', url);
        var filterResultContainer = $("<div>").addClass('prod-container');
        var imgSrc = data[i]['picture_src']
        var resultImage = $("<img>").attr('src', imgSrc).attr('height', "500").attr('width', "350").addClass('prod-img');
        filterResultContainer.append(resultImage).append($('<br>')).append($('<br>'));
        filterResultContainer.append(data[i]["name"].toUpperCase() + " by Voluptuous").append($('<br>'));
        filterResultContainer.append($("<span>").addClass('price-before').html(data[i]["pricebefore"]));
        filterResultContainer.append('&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;').append(data[i]["priceafter"]).append($('<br>')).append($('<br>')).append($('<br>')).append($('<br>'));
        (results.append(link.append(filterResultContainer)));
      }
      $('.index').replaceWith(results);
      })
    })

    $('#user_tops_store').change(function(){
      var storeName = $(this).val();
      $.ajax({
        url: '/profile_1',
        method: 'get',
        data:{
          store_name: storeName
        },
        dataType: 'JSON'
      }).done(function(data){
        $('#user_tops_size').empty();
        for(i=0; i < data.length; i++){
          $('#user_tops_size').append("<option>" + data[i] + "</option>")
        }
      })
    })

    $('#user_bottoms_store').change(function(){
      var storeName = $(this).val();
      $.ajax({
        url: '/profile_1',
        method: 'get',
        data:{
          store_name: storeName
        },
        dataType: 'JSON'
      }).done(function(data){
        $('#user_bottoms_size').empty();
        for(i=0; i < data.length; i++){
          $('#user_bottoms_size').append("<option>" + data[i] + "</option>")
        }
      })
    })


    $('body').delegate('.close-chat', 'click', function(){
      $('.messager').animate({right:"-1000px"}).removeClass('visible');
    })

    $('body').delegate('.messager-submit', 'click', function(e){
      e.preventDefault();
      // var messageSubmit = $('<div>', {class: 'campaign-message-submit', text: "Your message has successfully been sent!"});
      var message = $('.new_message textarea').last().val();

      $.ajax({
        url:'/messages',
        method: "POST",
        data:{
          body: message,
          receiver_id: 1
        }
      }).done(function(data){
        $('.new_message textarea').last().val('');
        $.ajax({
          url:'/messages/new',
          method: 'GET',
          data: {
            receiver_id: 1
          }
        }).done(function(data){
          $('.chat-content').html(data);
          $('.sendmessage').addClass('messager-submit');
          $('.sendmessage').removeClass('sendmessage');
          $('#conversation-body').scrollTop($('#conversation-body').prop("scrollHeight"));
        })
      })
    })

    var images = ['/assets/Leon-98.jpg', '/assets/Leon-196.jpg', '/assets/Leon-342.jpg', '/assets/Leon-398.jpg'];

    var index  = 0;
    var top   = $('.body-complement-right');

    setInterval(function() {
       top.animate({ opacity: 0 }, 500, function() {
         top.css('background-image', 'url('+images[++index]+')');
         top.animate({ opacity: 1 }, 500, function() {
           if(index === ((images.length) - 1)) {
             index = -1;
           }
         });
       });
    }, 5000);


    $('.bodyshape').on('mouseenter', function(){
      var desc = $('<div>').addClass('bodyshape-desc').css('width', '395').css('min-height', '200').css('z-index', '2').css('position', 'absolute').css('bottom', '-25px').css('left', '-100px').css('border', '2px solid black').css('border-radius', '5px');
      var invTri = '<b><u> Inverted Triangle Body Shape </u></b>: Generally, this body is athletic and strong. The broadest part of the body? The shoulders and the chest. The torso and waist are tighter.Health Implication: You benefit from a small waist, which can keep your heart disease risk low.Celebrity Examples: Super sports star Serena Williams and actress Hilary Swank.Fashion Tip: Inverted triangles can go bold with wide leg pants, which balance out the body.';
      var ruler = '<b><u>Ruler Body Shape</b></u>: With a ruler, there’s only a tiny bit of a curve at the hips. They mostly have a straight torso, with shoulders that align with the torso.Health Implication: A high WHR ratio could increase risk of certain diseases, but rulers tend to be thin overall. Keeping your Body Mass Index within healthy range can keep these risks at bay.Celebrity Examples: Two strong and successful women: Jennifer Garner and Madonna.Fashion Tip: Rulers can really play up a blouse with feminine ruffles and skirts with rounded hemlines.';
      var triangle = '<b><u>Triangle Body Shape</b></u>: This shape has a shapely bottom, with a tinier waist. Triangles are a classic feminine shape.Health Implication: Triangles are likely to have increased fertility, from the estrogen that’s putting more weight on their hips.Celebrity Examples: Tons of actresses and singers, from Jennifer Aniston to Jennifer Lopez.Fashion Tip: Triangles can rock a horizontal striped top and a jacket cropped above the waist, drawing attention above.';
      var round = '<b><u>Circle Body Shape</b></u>: Commonly called apples, women with a circle body shape have smaller shoulders and hips. They also tend to have slender legs and a slim booty. All fit! Though the fat has to go somewhere… With circles, it’s right smack in the middle: the stomach.Health Implications: According to past studies, a larger waist in comparison to the rest of the body could put you at greater risk for heart disease. Scientists are beginning to challenge this assertion. Either way, it’s important that you feel in control of your body fitness. As you move in different phases of your life, your shape can take different forms.Celebrity Examples: “30-Rock’s” Jane Krakowski and TV/film actress Dianne Wiest. Some celebs fluctuate with this body shape, like Renée Zellweger. Jennifer Hudson went from a circle shape to hourglass.Fashion Tip: Tops with a wide, scoop neck to show some skin up top, while giving shape.';
      var hourGlass = '<b><u>Hourglass Body Shape</b></u>: The name says it all. This body shape is curvy in all the right places: bust and booty. It’s pretty much a universal perception of what is womanly and attractive.Health Implications: Hourglasses tend to have more estrogen because of their wider hips and breasts, which is ideal for fertility and pregnancy.Celebrity Examples: You may have already guessed—Marilyn Monroe and Christina Hendricks (the modern 50s gal from “Mad Men”) are hourglasses.Fashion Tip: Pencil skirts in a solid color show of curves and leave much to the imagination—intriguing!';

      switch($(this).attr('class').split(' ')[1].trim()){
        case "inverted-triangle":
          $('.bodyshapes-container').append(desc.html(invTri));
          break;
        case "ruler":
          $('.bodyshapes-container').append(desc.html(ruler));
          break;
        case "round":
          $('.bodyshapes-container').append(desc.html(round));
          break;
        case "triangle":
          $('.bodyshapes-container').append(desc.html(triangle));
          break;
        case "hourglass":
          $('.bodyshapes-container').append(desc.html(hourGlass));
          break;
      }
    })

    $('.bodyshape').on('mouseleave', function(){
      $('.bodyshape-desc').remove();
    })

    $(".mission-top").click(function() {
      $('html, body').animate({
          scrollTop: $(".mission").offset().top
      }, 2000);
    });

    $(".how-it-works-top").click(function() {
      $('html, body').animate({
          scrollTop: $(".how-it-works").offset().top
      }, 2000);
    });

    $('.showoff-option').on('click', function(){
      if($(this).attr('class').indexOf('showoff-clicked') !== -1){
        $(this).removeClass('showoff-clicked').css('background-color', 'white');
      }
      else{
        $(this).css('background-color', '#29ABE2').addClass('showoff-clicked');
      }
    })

    $('.prof4-submit').on('click', function(e){
      e.preventDefault();
      var terms = {}
      $(':checkbox:checked').each(function(i){
        terms[($(this).attr('name'))] = $(this).attr('value');
      })
      $.ajax({
        url: '/update_terms_of_service',
        method: 'patch',
        data:{
          terms: terms
        }
      }).done(function(){
        $('.shipping-info > form').submit();
      })
    })

    $('.quantity-value').on('change', function(){
      var $this = $(this);
      var quantity = $(this).val();
      var itemId = $(this).siblings('#order_item_order_item_id').val();
      console.log(quantity);
      console.log(itemId);
      $.ajax({
        url: '/order_items/' + itemId,
        method: 'put',
        data:{
          order_item_quantity: quantity,
          order_item_id: itemId
        },
        dataType: 'json'
      }).done(function(data){
        console.log(data);
        var totalPrice = data['total_price'];
        console.log(totalPrice);
        console.log($this.attr('class'));
        $($this).parent().siblings('.text-right').children('.cart-show-totalprice').empty();
        $($this).parent().siblings('.text-right').children('.cart-show-totalprice').text(totalPrice);
      })
    })

    $('.stripe-button-container').hide();

    var checks = $('.verify-black');

    var interval = 5000;
    for(i = 0; i < checks.length; i++ ) {
      (function(i){
        setInterval(function(){
          var check = checks[i];
          $(check).attr('src', '/assets/success.svg');
        }, interval)
        interval += 5000;
      })(i);
    }

    setTimeout(function(){
      $('.wait-message').empty();
      $('.wait-message').text('Everything is perfect!')
    }, 15000)

    setTimeout(function(){
      $('.stripe-button-container').show();
    }, 15000)

    $("#overlay").on("click",function(event){
		  $('iframe').css('opacity', 1);
      var iframeSrc = $('iframe').attr('src');
      var playIframeSrc = iframeSrc + "?autoplay=1";
      $('iframe').attr('src', playIframeSrc);
      event.preventDefault();
		  $("#overlay").css("z-index",-1);
    });

    $("iframe").on("mouseleave",function(){
    	$("#overlay").css("z-index",1);
    });

  })
