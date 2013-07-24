file_js_onload = ->

  pl = (quantity, word) ->
    if quantity == 1
      quantity + ' ' + word
    else
      quantity + ' ' + word + 's'

  update_current_path_and_title = (path) ->
    window.current_path = path
    if path == '' then path = '/'
    $('#title').text('FileManager - ' + path)

  update_current_path_and_title '/'

  update_footer = (number_of_files, number_of_dirs) ->
    if number_of_files >= 0
      text = pl(number_of_files, 'item')
      if number_of_dirs > 0 and number_of_files != number_of_dirs
        text += ' (' + pl(number_of_dirs, 'folder') + ')'
    else
      text = "Fail to open this folder."
    $('#footer').text(text)

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
      file_count = 0
      dir_count = 0
      $.each d, (a,b) ->
        if b.name == "." or b.name == ".."
          return true
        if b['directory?']
          type = "dir"
          dir_count += 1
        else
          type = "not_dir"
        anchor = $('<a />', {
          class: 'file '+type,
          href: '/open'+path+encodeURIComponent(b.name),
          html: '<span class="icon"></span>'+b.name
        })
        anchor.data('path', path+b.name)
        column_element.append($('<li />').append(anchor))
        file_count += 1
        # select
        if b.name is next_column_ls_path
          anchor.addClass('active')
          if anchor.position().top > column_height - 20 # scroll to visible area
              should_scroll_to = anchor.position().top - column_height / 2
      column_element.slimScroll({ height: window.column_height, scrollTo: should_scroll_to })
      update_footer file_count, dir_count
    .error -> # error getting ls json
      update_footer -1

  create_new_list = (path, after_element) ->
    parent = after_element.closest('li')
    parent.nextAll('li').remove()
    li = $('<li />').insertAfter(parent)
    resize_columns()
    scroll_columns_to_right()
    element = $('<ul />').addClass('column').data('ls-path', path).appendTo(li)
    make_file_list_uploadable element
    # should return newly created element

  load_file_list($('#columns ul.column[data-ls-path]:first'))

  make_file_list_uploadable = (element) ->
    dropzone = new Dropzone(element[0], {
      url: "/upload" + element.data('ls-path'),
      clickable: false,
      previewTemplate: '<li><a class="file not_dir" href="#"><span class="icon"></span><span class="dz-filename" data-dz-name></span><span class="dz-progress"><span class="dz-upload" data-dz-uploadprogress></span></span><span class="dz-hidden dz-size" data-dz-size data-dz-errormessage></span><img data-dz-thumbnail class="dz-hidden" /></a></li>'
    })
    dropzone.on "sending", (file, xhr, formData) ->
      xhr.setRequestHeader 'X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')
    dropzone.on "success", ->
      parent = element.closest('li')
      parent.nextAll('li').remove()
      load_file_list element
    element

  $('#columns ul.column').each ->
    make_file_list_uploadable $(this)

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
      update_footer column.find('a.file').length, column.find('a.file.dir').length

  $(document).on 'dblclick', 'a.file', (e) ->
    window.location.href = $(this).attr('href')

  $(document).on 'contextmenu', 'a.file', (e) ->
    e.preventDefault()
    column = $(this).closest('ul.column')
    column.find('a.file').removeClass('active')
    $(this).addClass('active')
    $('#context_menu').css({ top: e.pageY - 10, left: e.pageX - 17 }).show()

  $(document).bind 'contextmenu', (e) ->
    e.preventDefault()

  $(document).bind 'click', (e) ->
    $('#context_menu').hide()

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
