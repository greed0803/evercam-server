defmodule EvercamMedia.EvercamBot.Commands do
  use EvercamMedia.EvercamBot.Router
  use EvercamMedia.EvercamBot.Commander

  import Nadia.API

  Application.ensure_all_started :inets

  command ["start"] do
    # Logger module injected from App.Commander
    Logger.log :info, "Command /start"
    send_message "Wellcome, write /cam to start"
  end

  # You can create commands in the format `/command` by
  # using the macro `command "command"`.
  command ["hello", "hi"] do
    # Logger module injected from App.Commander
    Logger.log :info, "Command /hello or /hi"

    # You can use almost any function from the Nadia core without
    # having to specify the current chat ID as you can see below.
    # For example, `Nadia.send_message/3` takes as first argument
    # the ID of the chat you want to send this message. Using the
    # macro `send_message/2` defined at App.Commander, it is
    # injected the proper ID at the function. Go take a look.
    #
    # See also: https://hexdocs.pm/nadia/Nadia.html
    send_message "Hello World!"
  end

  command "cam" do
    Logger.log :info, "Command /cam"
    id = update.message.chat.username
    usu = File.read!("users")
    usu2 = String.split(usu, " ")
    for n <- usu2 do
      if  id == n do
        camera1 = "esb2-uascg"
        camera2 = "stewart-harcourt"
        camera3 = "hik-ptz-herbst"
        camera4 = "gpocam"

        {:ok, _} = send_message "Select a camera to show:",
          # Nadia.Model is aliased from App.Commander
          #
          # See also: https://hexdocs.pm/nadia/Nadia.Model.InlineKeyboardMarkup.html
          reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: [
              [
                %{
                  callback_data: "/choose cam1",
                  text: "\xF0\x9F\x93\xB9 #{camera1}",
                },
                %{
                  callback_data: "/choose cam2",
                  text: "\xF0\x9F\x93\xB9 #{camera2}",
                },

              ],
              [
                # Read about fallbacks in the end of the file
                %{
                  callback_data: "/typo-:p",
                  text: "\xF0\x9F\x93\xB9 #{camera3}",
                },
                %{
                  callback_data: "/choose cam4",
                  text: "\xF0\x9F\x93\xB9 #{camera4}",
                },
              ]
            ]
          }
        end
    end
  end

  #<% @cameras.each do |camera| %>
  #  <% css = "onlinec"
  #    thumbnail_url = "https://media.evercam.io/v1/cameras/#{camera['id']}/thumbnail?api_id=#{current_user.api_id}&api_key=#{current_user.api_key}"
  #    unless !camera['is_online']
  #      css = "offlinec"
  #    end
  #  %>
  #  <option class="<%= css %>" value="<%= camera['id'] %>" data-val="<%= thumbnail_url %>">
  #    <%= camera['name'] %> <% unless camera['is_online'] %>(Offline)<% end %> <% unless camera['is_public'] %><% end %>
  #  </option>
  #<% end %>

  # You can create command interfaces for callback querys using this macro.
  callback_query_command "choose" do
    Logger.log :info, "Callback Query Command /choose"

    case update.callback_query.data do
      "/choose cam1" ->
        camera1 = "esb2-uascg"
        api_id= env["api_id"]
        api_key= env["api_key"]
        url = URI.parse("https://api.evercam.io/v1/cameras/#{camera1}/live/snapshot?api_id=#{api_id}&api_key=#{api_key}")
        %HTTPoison.Response{body: body} = HTTPoison.get!(url, [], [timeout: 10_000, recv_timeout: 10_000])
        File.write!("image.png", body)
        send_photo("image.png")
        #"https://media.evercam.io/v1/cameras/#{camera1}/thumbnail?api_id=#{api_id}&api_key=#{api_key}"
      "/choose cam2" ->
        camera2 = "stewart-harcourt"
        api_id= env["api_id"]
        api_key= env["api_key"]
        url = URI.parse("https://api.evercam.io/v1/cameras/#{camera2}/live/snapshot?api_id=#{api_id}&api_key=#{api_key}")
        %HTTPoison.Response{body: body} = HTTPoison.get!(url, [], [timeout: 10_000, recv_timeout: 10_000])
        File.write!("image.png", body)
        send_photo("image.png")
        answer_callback_query text: "Second camera"
      "/choose cam4" ->
        camera4 = "gpocam"
        api_id= env["api_id"]
        api_key= env["api_key"]
        url = URI.parse("https://api.evercam.io/v1/cameras/#{camera4}/live/snapshot?api_id=#{api_id}&api_key=#{api_key}")
        %HTTPoison.Response{body: body} = HTTPoison.get!(url, [], [timeout: 10_000, recv_timeout: 10_000])
        File.write!("image.png", body)
        send_photo("image.png")
    end
  end

  # You may also want make commands when in inline mode.
  # Be sure to enable inline mode first: https://core.telegram.org/bots/inline
  # Try by typping "@your_bot_name /whatis something"
  inline_query_command "whatis" do
    Logger.log :info, "Inline Query Command /whatis"

    :ok = answer_inline_query [
      %InlineQueryResult.Article{
        id: "1",
        title: "GPO Dublin Live Stream",
        thumb_url: "https://evercam.io/wp-content/uploads/2018/04/Evercam-logo-horizontal_black-background1-01-e1522828595798.png",
        description: "This is a test @testevercam_bot",
        input_message_content: %{
          message_text: "https://www.youtube.com/watch?v=FV6jj5lqxnw",
        }
      }
    ]
  end

  # Advanced Stuff
  #
  # Now that you already know basically how this boilerplate works let me
  # introduce you to a cool feature that happens under the hood.
  #
  # If you are used to telegram bot API, you should know that there's more
  # than one path to fetch the current message chat ID so you could answer it.
  # With that in mind and backed upon the neat macro system and the cool
  # pattern matching of Elixir, this boilerplate automatically detectes whether
  # the current message is a `inline_query`, `callback_query` or a plain chat
  # `message` and handles the current case of the Nadia method you're trying to
  # use.
  #
  # If you search for `defmacro send_message` at App.Commander, you'll see an
  # example of what I'm talking about. It just works! It basically means:
  # When you are with a callback query message, when you use `send_message` it
  # will know exatcly where to find it's chat ID. Same goes for the other kinds.

  inline_query_command "foo" do
    Logger.log :info, "Inline Query Command /foo"
    # Where do you think the message will go for?
    # If you answered that it goes to the user private chat with this bot,
    # you're right. Since inline querys can't receive nothing other than
    # Nadia.InlineQueryResult models. Telegram bot API could be tricky.
    send_message "This came from an inline query"
  end

  # Fallbacks

  # Rescues any unmatched callback query.
  callback_query do
    Logger.log :warn, "Did not match any callback query"
    camera3 = "hik-ptz-herbst"
    answer_callback_query text: "#{camera3} offline"
  end

  # Rescues any unmatched inline query.
  inline_query do
    Logger.log :warn, "Did not match any inline query"

    :ok = answer_inline_query [
      %InlineQueryResult.Article{
        id: "1",
        title: "GPO Dublin Live Stream",
        thumb_url: "https://evercam.io/wp-content/uploads/2018/04/Evercam-logo-horizontal_black-background1-01-e1522828595798.png",
        description: "GPO Dublin Live Stream",
        input_message_content: %{
          message_text: "https://www.youtube.com/watch?v=FV6jj5lqxnw",
        }
      }
    ]
  end

  # The `message` macro must come at the end since it matches anything.
  # You may use it as a fallback.
  message do
      #Logger.log :warn, "Did not match the message"
      #send_message "Sorry, I couldn't understand you"
      Logger.log :info, "Command /cam"
      id = update.message.chat.username
      usu = File.read!("users")
      usu2 = String.split(usu, " ")
      for n <- usu2 do
        if  id == n do
          camera1 = "esb2-uascg"
          camera2 = "stewart-harcourt"
          camera3 = "hik-ptz-herbst"
          camera4 = "gpocam"

          {:ok, _} = send_message "Select a camera to show:",
            # Nadia.Model is aliased from App.Commander
            #
            # See also: https://hexdocs.pm/nadia/Nadia.Model.InlineKeyboardMarkup.html
            reply_markup: %Model.InlineKeyboardMarkup{
              inline_keyboard: [
                [
                  %{
                    callback_data: "/choose cam1",
                    text: "\xF0\x9F\x93\xB9 #{camera1}",
                  },
                  %{
                    callback_data: "/choose cam2",
                    text: "\xF0\x9F\x93\xB9 #{camera2}",
                  },

                ],
                [
                  # Read about fallbacks in the end of the file
                  %{
                    callback_data: "/typo-:p",
                    text: "\xF0\x9F\x93\xB9 #{camera3}",
                  },
                  %{
                    callback_data: "/choose cam4",
                    text: "\xF0\x9F\x93\xB9 #{camera4}",
                  },
                ]
              ]
            }
          end
      end
  end
end
