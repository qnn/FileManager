jQuery ($) ->
  list_files_path = $('#columns').data('ls-path')
  $.getJSON list_files_path, (d) ->
    $('#columns ul.column').empty();
    $.each d, (a,b) ->
      if b.name == "." or b.name == ".."
        return true
      type = if b['directory?'] then "dir" else "not_dir"
      $('#columns ul.column').append('<li><a class="file '+type+'" href="#"><span class="icon"></span>'+b.name+'</a></li>')

  $(document).on 'click', 'a.file', (e) ->
    e.preventDefault()
    $('a.file').removeClass('active')
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
