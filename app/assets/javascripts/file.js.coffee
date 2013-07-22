file_js_onload = ->

  list_files_path = ->
    $('#columns').data('list-files-path')

  load_file_list = (column_element) ->
    path = column_element.data('ls-path')
    $.getJSON path, (d) ->
      # find next column
      next_column = column_element.parent().next('li').find('ul.column[data-ls-path]')
      next_column_ls_path = null
      if next_column.length > 0
        load_file_list next_column
        next_column_ls_path = next_column.data('ls-path').replace(/^.*[\\\/]/, '')

      column_element.empty();
      path = '/' + path.replace(/^\/ls/, '') + '/'
      path = path.replace(/^\/*/, '/').replace(/\/*$/, '/')
      $.each d, (a,b) ->
        if b.name == "." or b.name == ".."
          return true
        type = if b['directory?'] then "dir" else "not_dir"
        anchor = $('<a />', {
          class: 'file '+type,
          href: '/open'+path+encodeURIComponent(b.name),
          html: '<span class="icon"></span>'+b.name
        })
        anchor.data('path', path+b.name)
        if b.name is next_column_ls_path then anchor.addClass('active')
        column_element.append($('<li />').append(anchor))

  create_new_list = (path, after_element) ->
    parent = after_element.parent()
    parent.nextAll('li').remove()
    li = $('<li />').insertAfter(after_element.parent())
    resize_columns()
    $('<ul />').addClass('column').data('ls-path', list_files_path() + path).appendTo(li)

  load_file_list($('#columns ul.column[data-ls-path]:first'))

  $(document).on 'click', 'a.file', (e) ->
    column = $(this).closest('ul.column')
    e.preventDefault()
    column.find('a.file').removeClass('active')
    $(this).addClass('active')
    if $(this).hasClass('dir')
      load_file_list create_new_list($(this).data('path'), column)

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
