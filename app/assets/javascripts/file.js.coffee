file_js_onload = ->
  list_files_path = $('#columns').data('ls-path')
  $.getJSON list_files_path, (d) ->
    $('#columns ul.column').data('ls-path', list_files_path).empty();
    open_path = list_files_path.replace(/^\/ls/, '/open').replace(/\/*$/, '')
    $.each d, (a,b) ->
      if b.name == "." or b.name == ".."
        return true
      type = if b['directory?'] then "dir" else "not_dir"
      $('#columns ul.column').append('<li><a class="file '+type+'" href="'+open_path+'/'+encodeURIComponent(b.name)+'"><span class="icon"></span>'+b.name+'</a></li>')

  $(document).on 'click', 'a.file', (e) ->
    e.preventDefault()
    $('a.file').removeClass('active')
    $(this).addClass('active')

  $(document).on 'dblclick', 'a.file', (e) ->
    location.href = $(this).attr('href')

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

$(file_js_onload)
$(window).bind 'page:change', file_js_onload
