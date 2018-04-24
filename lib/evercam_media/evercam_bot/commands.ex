defmodule EvercamMedia.EvercamBot.Commands do
  use EvercamMedia.EvercamBot.Router
  use EvercamMedia.EvercamBot.Commander

  #import Nadia.API

  Application.ensure_all_started :inets

  command ["start"] do
    # Logger module injected from App.Commander
    Logger.log :info, "Command /start"
    send_message "Wellcome, write anything to show the main menu or /help to show the list of commands"
  end

  command ["help"] do
    # Logger module injected from App.Commander
    Logger.log :info, "Command /help"
    send_message "Commands:
    - /start -> Show the initial message
    - /hello - /hi -> Send 'Hello World!' :)
    - /liveview -> List the cameras availables to show the live view
    - /date -> Get the image of a camera in one specific date
    - /comparison -> Get a video of the last comparison
    - /timelapse -> Get a video of the last timelapse"
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

  # You can create command interfaces for callback querys using this macro.
  callback_query_command "choose" do
    Logger.log :info, "Callback Query Command /choose"
    id = update.callback_query.from.username
    user = User.by_telegram_username(id)
    cameras_list = Camera.for(user, true)

    case update.callback_query.data do

      "/choose live" ->
            Enum.each(cameras_list, fn(camera) ->
              send_message "#{camera.exid}",
                  # Nadia.Model is aliased from App.Commander
                  #
                  # See also: https://hexdocs.pm/nadia/Nadia.Model.InlineKeyboardMarkup.html
                  reply_markup: %Model.InlineKeyboardMarkup{
                    inline_keyboard: [
                      [
                        %{
                          callback_data: "/choose mycamera",
                          text: "\xF0\x9F\x93\xB9 #{camera.name}"
                        },
                      ],
                    ]
                  }
                  camera1 = "#{camera.exid}"
                  api_id = user.api_id
                  api_key = user.api_key
                  url = "https://api.evercam.io/v1/cameras/#{camera1}/live/snapshot?api_id=#{api_id}&api_key=#{api_key}"
                  send_photo(url)
            end)

      "/choose all" ->
        Enum.each(cameras_list, fn(camera) ->
          camera1 = "#{camera.exid}"
          api_id = user.api_id
          api_key = user.api_key
          url = URI.parse("https://api.evercam.io/v1/cameras/#{camera1}/live/snapshot?api_id=#{api_id}&api_key=#{api_key}")
          #url = URI.parse("/v1/cameras/#{camera1}/timelapses?api_id=#{api_id}&api_key=#{api_key}")
          %HTTPoison.Response{body: body} = HTTPoison.get!(url, [], [timeout: 10_000, recv_timeout: 10_000])
          File.write!("image.png", body)
          send_photo("image.png")
        end)

      "/choose mycamera" ->
        camera1 = "#{update.callback_query.message.text}"
        api_id = user.api_id
        api_key = user.api_key
        url = URI.parse("https://api.evercam.io/v1/cameras/#{camera1}/live/snapshot?api_id=#{api_id}&api_key=#{api_key}")
        #url = URI.parse("/v1/cameras/#{camera1}/timelapses?api_id=#{api_id}&api_key=#{api_key}")
        %HTTPoison.Response{body: body} = HTTPoison.get!(url, [], [timeout: 10_000, recv_timeout: 10_000])
        File.write!("image.png", body)
        send_photo("image.png")

      "/choose comparison" ->
        Enum.each(cameras_list, fn(camera) ->
          send_message "#{camera.exid}",
              # Nadia.Model is aliased from App.Commander
              #
              # See also: https://hexdocs.pm/nadia/Nadia.Model.InlineKeyboardMarkup.html
              reply_markup: %Model.InlineKeyboardMarkup{
                inline_keyboard: [
                  [
                    %{
                      callback_data: "/choose mycomparison",
                      text: "\xF0\x9F\x93\xB9 #{camera.name}"
                    },
                  ],
                ]
              }
        end)

      "/choose mycomparison" ->
        camera1 = "#{update.callback_query.message.text}"
        api_id = user.api_id
        api_key = user.api_key
        url = URI.parse("https://media.evercam.io/v1/cameras/#{camera1}/compares?api_id=#{api_id}&api_key=#{api_key}")
        %HTTPoison.Response{body: body} = HTTPoison.get!(url, [], [timeout: 10_000, recv_timeout: 10_000])
        this = Poison.Parser.parse!(~s(#{body}), keys: :atoms!)
        last = List.last(this.compares)

        url = URI.parse("https://media.evercam.io/v1/cameras/#{camera1}/compares/#{last.id}.mp4")
        %HTTPoison.Response{body: body} = HTTPoison.get!(url, [], [timeout: 10_000, recv_timeout: 10_000])
        File.write!("video.mp4", body)
        send_video("video.mp4")
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
    camera3 = "env[camera3]"
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
      id = update.message.chat.username
      user = User.by_telegram_username(id)
      cameras_list = Camera.for(user, true)
      if user != nil do
        {:ok, _} = send_message "what do you want to see?",
          # Nadia.Model is aliased from App.Commander
          #
          # See also: https://hexdocs.pm/nadia/Nadia.Model.InlineKeyboardMarkup.html
          reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: [
              [
                %{
                  callback_data: "/choose live",
                  text: "Live view",
                },
              ],
              [
              %{
                callback_data: "/choose all",
                text: "View all images",
              },
              ],
              [
                # Read about fallbacks in the end of the file
                %{
                  callback_data: "/choose comparison",
                  text: "Comparison",
                },
              ]
            ]
          }
      else
        send_message "Unregistered user"
      end
  end
end
