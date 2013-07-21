jQuery ($) ->
  list_files_path = $('#columns').data('ls-path')
  $.getJSON list_files_path, (d) ->
    $('#columns ul.column').empty();
    $.each d, (a,b) ->
      $('#columns ul.column').append('<li><a href="#">'+b+'</a</li>')

  $(document).on 'click', '.column a', (e) ->
    e.preventDefault()
    $('.column a').removeClass('active')
    $(this).addClass('active')

  # resize columns
  resize_columns = ->
    parent = $('#columns_container')
    height = parent.height()
    $('#columns').css({
      top: parent.position().top,
      left: parent.position().left,
      width: parent.width(),
      height: height
    })
    $('.columns > li').height(height)
  resize_columns()
  $(window).resize ->
    resize_columns()
