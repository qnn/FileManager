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

  window.error_msgs = [
    "Fail to open this folder."                # -1
    "Fail to move this file to trash."         # -2
    "Fail to complete the undo request."       # -3
    "Fail to rename this file."                # -4
    "Fail to create new directory/file."       # -5
  ]

  update_footer = (number_of_files, number_of_dirs) ->
    if number_of_files >= 0
      text = pl(number_of_files, 'item')
      if number_of_dirs > 0 and number_of_files != number_of_dirs
        text += ' (' + pl(number_of_dirs, 'folder') + ')'
    else
      text = window.error_msgs[Math.abs(number_of_files)-1]
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
        anchor = $ '<a />',
          class: 'file '+type
          href: '/open'+path+encodeURIComponent(b.name)
          html: '<span class="icon"></span><span class="name">'+b.name+'</span>'
        anchor.data('path', path+b.name)
        column_element.append($('<li />').append(anchor))
        file_count += 1
        # select
        if b.name is next_column_ls_path
          anchor.addClass('active')
          if anchor.position().top > column_height - 20 # scroll to visible area
              should_scroll_to = anchor.position().top - column_height / 2
      column_element.slimScroll
        height: window.column_height
        scrollTo: should_scroll_to
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
    make_file_list_selectable element
    make_file_list_uploadable element
    # should return newly created element

  load_file_list($('#columns ul.column[data-ls-path]:first'))

  make_file_list_selectable = (element) ->
    $(element).click (e) ->
      e.preventDefault()
      e.stopPropagation()
      hide_context_menu()
      $(this).nextAll('li').remove()
    .selectable
      filter: 'li'
      selecting: (event, ui) ->
        $(ui.selecting).find('a.file').addClass('active')
      unselecting: (event, ui) ->
        $(ui.unselecting).find('a.file').removeClass('active')
      start: (event, ui) ->
        hide_context_menu()
        # pressing command or ctrl key to select multiple items
        if event.metaKey == false and event.ctrlKey == false
          $(this).find('a.file').removeClass('active')
      stop: (event, ui) ->
        column = $(this)
        selected = column.find('.ui-selectee.ui-selected')
        # clicking on one item
        if selected.length == 1
          selected = selected.find('a.file')
          selected.addClass('active')
          if selected.hasClass('dir')
            load_file_list create_new_list(selected.data('path'), column)
          else
            parent = column.closest('li')
            parent.nextAll('li').remove()
            update_current_path_and_title column.data('ls-path')
            update_footer column.find('a.file').length, column.find('a.file.dir').length
          if window.last_clicked_list_item && selected[0] == window.last_clicked_list_item.selected[0] && event.timeStamp - window.last_clicked_list_item.timeStamp <= 3000
            # clicking too fast is 'double click'
            if event.timeStamp - window.last_clicked_list_item.timeStamp > 500
              show_renames()
          else
            window.last_clicked_list_item = { selected: selected, timeStamp: event.timeStamp }

  make_file_list_uploadable = (element) ->
    dropzone = new Dropzone element[0],
      url: "/upload" + element.data('ls-path')
      clickable: false
      previewTemplate: '<li><a class="file not_dir" href="#"><span class="icon"></span><span class="dz-filename" data-dz-name></span><span class="dz-progress"><span class="dz-upload" data-dz-uploadprogress></span></span><span class="dz-hidden dz-size" data-dz-size data-dz-errormessage></span><img data-dz-thumbnail class="dz-hidden" /></a></li>'
    dropzone.on "sending", (file, xhr, formData) ->
      xhr.setRequestHeader 'X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')
    dropzone.on "success", ->
      parent = element.closest('li')
      parent.nextAll('li').remove()
      # remove dropzone tags to make it look like real one
      success = element.find('.dz-processing.dz-success')
      success.find('.dz-filename').replaceWith ->
        $(this).contents()
      success.find('.dz-hidden, .dz-progress').remove();
      success.removeClass('dz-processing dz-success')
      # if all operations completed, refresh the list
      if element.find('.dz-processing').length == 0
        load_file_list element
    element # return the element

  $('#columns ul.column').each ->
    make_file_list_selectable $(this)
    make_file_list_uploadable $(this)

  # $(document).on 'click', 'a.file', (e) ->
  #   (code move to make_file_list_selectable)

  $(document).on 'dblclick', 'a.file', (e) ->
    window.location.href = $(this).attr('href')

  $(document).on 'contextmenu', 'a.file', (e) ->
    e.preventDefault()
    e.stopPropagation()
    files = $(this).closest('ul.column').find('a.file')
    if !$(this).hasClass('active')
      files.removeClass('active')
      $(this).addClass('active')
    open_context_menu 'for_files', files.filter('.active'), e

  # saving renames
  save_renames = ->
    $('input.rename.renaming').each ->
      input = $(this)
      val = input.val().trim()
      file = input.closest('a.file')
      is_new = file.hasClass('new')
      is_dir = file.hasClass('dir')
      path = file.data('path')

      if val == input.data('name') or val == ''
        cancel_renames()
        return

      already_exists = false
      input.closest('ul.column').find('a.file').each ->
        if $('.name', this).text() == val
          already_exists = true
      if is_new and already_exists and not confirm('The file name "'+val+'" is already taken.')
        return
      if not is_new and already_exists and not confirm('The file name "'+val+'" is already taken. Are you sure you want to overwrite the file?')
        return

      input.removeClass('renaming') # prevent re-submit
      if is_new
        if is_dir
          post_path = window.routes.make_directory_path.replace('/:path', path + '/' + val)
        else
          post_path = window.routes.touch_file_path.replace('/:path', path + '/' + val)
        $.post post_path,
          _method: 'post'
        .success (d) ->
          window.available_undos.unshift d
          load_file_list input.closest('ul.column')
        .error ->
          input.addClass('renaming')
          update_footer -5
      else
        $.post window.routes.rename_files_path.replace('/:path', path),
          _method: 'put'
          to: val
        .success (d) ->
          window.available_undos.unshift d
          load_file_list input.closest('ul.column')
        .error ->
          input.addClass('renaming')
          update_footer -4

  # clearing rename inputs
  cancel_renames = ->
    $('input.rename').each ->
      if $(this).closest('a.file').hasClass('new')
        $(this).closest('li').remove()
      else
        $(this).replaceWith ->
          $(this).data('name')

  # show rename input box
  show_renames = ->
    last_selected = $('#columns a.file.active:last')
    if last_selected.length == 1
      if last_selected.find('input.rename').length == 0
        input = $('<input />')
        input.bind 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()
        .bind 'contextmenu dblclick mousedown', (e) ->
          e.stopPropagation()
        input.data('name', last_selected.find('span.name').text())
        last_selected.find('span.name').html(input)
        input.addClass('rename renaming')
        input.val(input.data('name')).select()
      else
        save_renames()

  # detect pressing enter
  $(document).keyup (e) ->
    if e.which == 13 # enter key
      show_renames()
    else if e.which == 27 # esc key
      cancel_renames()

  # $(document).on 'click', 'ul.columns > li', (e) ->
  #   (code move to make_file_list_selectable)

  $(document).on 'contextmenu', 'ul.columns > li', (e) ->
    e.preventDefault()
    e.stopPropagation()
    $(this).find('a.file').removeClass('active')
    $(this).nextAll('li').remove()
    open_context_menu 'for_lists', $(this), e

  window.selected_items = []

  open_context_menu = (type, file, e) ->
    save_renames()
    window.selected_items = file
    $('#menu').data('type', type).empty()
    $.each menu_items[type], (a,b) ->
      li = $('<li />')
      if b.substr(-2) == '--'
        b = b.substr(0, b.length-2)
        li.addClass('bottom-separator')
      li.append('<a href="#">'+b+'</a>')
      $('#menu').append(li)
    x = e.pageX - 17
    if x + $('#context_menu').outerWidth() > $(window).width()
      x = $(window).width() - $('#context_menu').outerWidth()
    y = e.pageY - 10
    $('#context_menu').show().css
      height: $('#menu').outerHeight() + 20
      top: e.pageY - 10
      left: x
      'z-index': 20
    if (y + $('#context_menu').height() > $(window).height())
      $('#context_menu').css
        top: $(window).height() - $('#context_menu').height()
    menu_items_before_clicked[type]()

  hide_context_menu = ->
    save_renames()
    $('#context_menu').css({ 'z-index': 0 }).hide()

  open = ->
    first = window.selected_items.eq(0)
    first.trigger('dblclick')

  # move one or more files in a directory to trash
  move_to_trash = ->
    first = window.selected_items.eq(0)
    path = first.closest('ul.column').data('ls-path')
    files = []
    window.selected_items.each ->
      if $(this).is('a.file')
        files.push $(this).data('path').substr(path.length + 1)
    if files.length > 0
      if files.length == 1
        path = first.data('path')
        files = null
      else
        files = { files: files }
      $.post window.routes.remove_files_path.replace('/:path', path),
        $.extend
          _method: 'delete'
        , files
      .success (d) ->
        window.available_undos.unshift d
        load_file_list first.closest('ul.column')
      .error ->
        update_footer -2

  rename = ->
    show_renames()

  window.available_undos = []
  # undo
  undo = ->
    if window.available_undos.length > 0
      undo = window.available_undos[0].undo
      $.post(undo.action, undo.parameters)
      .complete ->
        window.available_undos = window.available_undos.splice(1)
      .success ->
        load_file_list window.selected_items.eq(0).find('ul.column')
      .error ->
        update_footer -3

  # make file/directory
  mkdir = ->
    mkfile true
  mkfile = (is_dir) ->
    current_list = window.selected_items.eq(0).find('ul.column')
    anchor = $ '<a />',
      class: 'file '+(if is_dir==true then 'dir' else 'not_dir')+' active new'
      html: '<span class="icon"></span><span class="name"></span>'
    anchor.data('path', current_list.data('ls-path'))
    current_list.append($('<li />').append(anchor))

  # refresh list
  refresh = ->
    if window.selected_items.length > 0
      load_file_list window.selected_items.eq(0).find('ul.column')

  menu_items =
    for_files: [
      'Open--'
      'Move to Trash--'
      'Get Info'
      'Rename'
    ]
    for_lists: [
      'Undo--'
      'Make Directory'
      'Create Empty File--'
      'Refresh--'
      'Get Info'
      'Settings'
    ]

  menu_items_before_clicked =
    for_files: ->
      null
    for_lists: ->
      if window.available_undos.length == 0
        $('#menu li:first').addClass('disabled')
      else
        text = 'Undo "' + window.available_undos[0].undo.name + '"'
        $('#menu li:first').removeClass('disabled').find('a').text(text).attr('title', text)

  menu_items_clicked =
    for_files: [
      open
      move_to_trash
      null
      null
    ]
    for_lists: [
      undo
      mkdir
      mkfile
      refresh
      null
      null
    ]

  menu_items_after_clicked =
    for_files: (index) ->
      switch index
        when 3 then show_renames()
    for_lists: (index) ->
      switch index
        when 1, 2 then show_renames()

  $(document).bind 'contextmenu', (e) ->
    if $('#context_menu').css('z-index') != '0'
      hide_context_menu()
      e.preventDefault()

  $(document).on 'click', '#menu a', (e) ->
    e.preventDefault()
    e.stopPropagation()
    index = $(this).parent().index()
    func = menu_items_clicked[$('#menu').data('type')][index]
    if func != null
      func();
    hide_context_menu()
    menu_items_after_clicked[$('#menu').data('type')](index)

  $(document).bind 'click', (e) ->
    hide_context_menu()

  # column list should stick to right
  scroll_columns_to_right = ->
    $('#columns ul.columns').slimScrollHorizontal({ width: 'auto', scrollTo: 99999 })

  # resize columns
  resize_columns = ->
    parent = $('#columns_container')
    window.column_height = parent.height()
    $('#columns').css
      top: parent.position().top
      left: parent.position().left
      width: parent.width()
      height: window.column_height
    $('#columns ul.columns > li').height(window.column_height)
    $('#columns ul.column').slimScroll({ height: 'auto' })
    $('#columns ul.columns').slimScrollHorizontal({ width: 'auto' })
  resize_columns()
  scroll_columns_to_right()
  $(window).resize ->
    resize_columns()

$(file_js_onload)
