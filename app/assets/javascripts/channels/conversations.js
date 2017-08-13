$(document).ready(function() {

  var messages, messages_to_bottom;

  messages = $('#conversation-body');

  messages_to_bottom = function() {
    return messages.scrollTop(messages.prop("scrollHeight"));
  };



  if ($('#current-user').size() > 0) {
    App.personal_chat = App.cable.subscriptions.create({
      channel: "NotificationsChannel"
    }, {
    connected: function() {},
      // Called when the subscription is ready for use on the server

    disconnected: function() {},
      // Called when the subscription has been terminated by the server

    received: function(data) {

      if (data['message_receiver_id'] !== 1) {
        if ($('.messager').size() > 0) {
          $('#conversation-body').append(data["message"]);
          $('#conversation-body').scrollTop($('#conversation-body').prop("scrollHeight"));
        }
        else {
          var messager = $('<div>').addClass('messager').text('Chat ');
          messager.append($('<span>').addClass('close-chat').text(' X'));
          messager.append($('<span>').addClass('chat-content'));

          $.ajax({
            url: '/messages/new',
            method: 'get',
            data:
            {
               receiver_id: 1
            }
          }).done(function(data){
            $('.chat-content').html(data);
            $('.sendmessage').addClass('messager-submit');
            $('.sendmessage').removeClass('sendmessage');
            $('#conversation-body').scrollTop($('#conversation-body').prop("scrollHeight"));
          })

          $('.messager-insert').html(messager);
          messager.show().animate({right:"0px"}).addClass('visible');
        }
      }

      if (messages.size() > 0 && messages.data('conversation-id') === data['conversation_id']) {
        messages.append(data['message']);
         return messages_to_bottom();
      }
      else {

        if ($('#conversations').size() > 0) { $.getScript('/conversations'); }

        if (data['notification']) {
          if(data['message_receiver_id'] === 1){
            return $('body').append(data['notification']);
          }
        }
      }
    },

    send_message: function(message, conversation_id, message_receiver_id) {
      return this.perform('send_message', {message: message, conversation_id: conversation_id, message_receiver_id: message_receiver_id});
    }
  });
  }

  $(document).on('click', '#notification .close', function() {
    return $(this).parents('#notification').fadeOut(1000);
  });

  if (messages.length > 0) {
    messages_to_bottom();
    return $('#new_message').submit(function(e) {
      var $this = $(this);
      var textarea = $this.find('#message_body');
      if ($.trim(textarea.val()).length > 0) {
        App.personal_chat.send_message(textarea.val(), $this.find('#conversation_id').val(), $this.find('#message_receiver_id').val());
        textarea.val('');
      }
      e.preventDefault();
      return false;
    });
  }

  $('.add-to-cart').on('click', function(){
    var convId = parseInt($(this).siblings('#order_item_conv_id').val());
    var itemCode = $(this).siblings('#order_item_itemcode').val();
    var itemLink = $(this).siblings('#order_item_item_link').val();
    var userId = $(this).siblings('#order_item_user_id').val();
    var message = "item code: " + itemCode + " | " + "item link:" + itemLink + " | " + "user id: " + userId;

    App.personal_chat.send_message(message, convId, 1);
  })
});
