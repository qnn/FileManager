file_js_onload = ->

  list_files_path = ->
    $('#columns').data('list-files-path')

  load_file_list = (column_element) ->
    path = column_element.data('ls-path')
    $.getJSON path, (d) ->
      # find next column
      column_parent = column_element.closest('li')
      column_height = column_parent.height()
      next_column = column_parent.next('li').find('ul.column[data-ls-path]')
      next_column_ls_path = null
      if next_column.length > 0
        scroll_columns_to_right()
        load_file_list next_column
        next_column_ls_path = next_column.data('ls-path').replace(/^.*[\\\/]/, '')

      should_scroll_to = null
      column_element.empty()
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

  # column list should stick to right
  scroll_columns_to_right = ->
    last = $('#columns ul.columns li:last')
    if last.position().left + last.width() > $('#columns').width()
      $('#columns ul.columns').scrollLeft($('#columns').width())

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
  resize_columns()
  $(window).resize ->
    resize_columns()

$(file_js_onload)
$(window).bind 'page:change', file_js_onload
