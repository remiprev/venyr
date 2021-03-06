class Venyr.Listener
  constructor: ->
    @initTemplate()
    @initSocket(reconnect: false)

  initEvents: ->
    @initPing()
    $(window).on 'beforeunload', -> 'This message is just there so you won’t accidentally close/reload the Venyr tab while you’re listening. But leave if you must!'

  initTemplate: ->
    @hud = new Venyr.Hud(e: $('.hud'))
    $('.loading').hide()
    $('.authenticated-content').show()

  socketPath: ->
    "/live/listen/#{$('#content').data('user')}"

  initSocket: (opts) ->
    @ws = new WebSocket('ws://' + window.location.host + @socketPath())
    @ws.onopen = => @initEvents() unless opts.reconnect
    @ws.onclose = =>
      return false if window.Venyr.App.fatalError == true
      console.log('The WebSocket has closed, attempting to reconnect in 15 seconds…')
      @reconnectSocket(15000)
    @ws.onmessage = (message) => @handleMessage(message)

  reconnectSocket: (delay) ->
    setTimeout(=>
      console.log('Trying to reconnect…')
      @initSocket(reconnect: true)
    , delay)

  initPing: ->
    setInterval(=>
      @ws.send(JSON.stringify({ event: 'ping', data: {} }))
    , Venyr.App.opts.pingInterval)

  handleMessage: (message) ->
    message = JSON.parse(message.data)
    console.log(message) if Venyr.App.debug

    switch message.event
      when "fatalError" then @ws.close(); R.player.pause(); window.Venyr.App.handleFatalError(message.data)
      when "playStateChange" then @handlePlayStateChange(message.data.state)
      when "playingTrackChange" then @handlePlayingTrackChange(message.data.track)
      when "pong" then true
      else console.log("Invalid event: #{message}")

  handlePlayStateChange: (state) ->
    @hud.updateState(state)
    if Venyr.App.debug
      if state == 0
        console.log("Here, I would pause the current track")
      else
        console.log("Here, I would play the current track")
    else
      if state == 0 then R.player.pause() else R.player.play()

  handlePlayingTrackChange: (track) ->
    if track
      @hud.updateTrack(track)
      if Venyr.App.debug
        console.log("Here, I would start playing #{track.key}")
      else
        R.player.play(source: track.key)
    else
      @hud.clear()
