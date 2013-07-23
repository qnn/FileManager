file_js_onload = ->

  update_current_path_and_title = (path) ->
    window.current_path = path
    if path == '' then path = '/'
    $('#title').text('FileManager - ' + path)

  update_current_path_and_title '/'

  list_files_path = (path = '') ->
    if path != null and path[0] != '/'
      path = '/' + path
    $('#columns').data('list-files-path') + path

  load_file_list = (column_element) ->
    update_current_path_and_title column_element.data('ls-path')
    path = window.current_path
    $.getJSON list_files_path(path), (d) ->
      # find next column
      column_parent = column_element.closest('li')
      column_height = column_parent.height()
      next_column = column_parent.next('li').find('ul.column[data-ls-path]')
      next_column_ls_path = null
      if next_column.length > 0
        load_file_list next_column
        next_column_ls_path = next_column.data('ls-path').replace(/^.*[\\\/]/, '')

      should_scroll_to = null
      column_element.empty()
      path += '/'
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
        column_element.append($('<li />').append(anchor))
        # select
        if b.name is next_column_ls_path
          anchor.addClass('active')
          if anchor.position().top > column_height - 20 # scroll to visible area
              should_scroll_to = anchor.position().top - column_height / 2
      column_element.slimScroll({ height: window.column_height, scrollTo: should_scroll_to })

  create_new_list = (path, after_element) ->
    parent = after_element.closest('li')
    parent.nextAll('li').remove()
    li = $('<li />').insertAfter(parent)
    resize_columns()
    scroll_columns_to_right()
    $('<ul />').addClass('column').data('ls-path', path).appendTo(li)

  load_file_list($('#columns ul.column[data-ls-path]:first'))

  $(document).on 'click', 'a.file', (e) ->
    column = $(this).closest('ul.column')
    e.preventDefault()
    column.find('a.file').removeClass('active')
    $(this).addClass('active')
    if $(this).hasClass('dir')
      load_file_list create_new_list($(this).data('path'), column)
    else
      parent = column.closest('li')
      parent.nextAll('li').remove()
      update_current_path_and_title column.data('ls-path')

  $(document).on 'dblclick', 'a.file', (e) ->
    location.href = $(this).attr('href')

  # column list should stick to right
  scroll_columns_to_right = ->
    $('#columns ul.columns').slimScrollHorizontal({ width: 'auto', scrollTo: 99999 })

  # resize columns
  resize_columns = ->
    parent = $('#columns_container')
    window.column_height = parent.height()
    $('#columns').css({
      top: parent.position().top,
      left: parent.position().left,
      width: parent.width(),
      height: window.column_height
    })
    $('#columns ul.columns > li').height(window.column_height)
    $('#columns ul.column').slimScroll({ height: 'auto' })
    $('#columns ul.columns').slimScrollHorizontal({ width: 'auto' })
  resize_columns()
  scroll_columns_to_right()
  $(window).resize ->
    resize_columns()

$(file_js_onload)
$(window).bind 'page:change', file_js_onload
