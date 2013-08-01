class ManagerController < ApplicationController

  def index
    path = params[:path] || '/'

    @ls_paths = []

    if request.fullpath == '/' # root

      if session.has_key?(:path)
        session_path = session[:path]
        if Dir.exist?(get_path(session_path))
          path = ""
          session_path = "/" + session_path
          session_path.split(File::SEPARATOR).each do |_path|
            path = File.join(path, _path)
            break unless Dir.exist?(get_path(path))
            @ls_paths << path.chomp('/')
          end
        end
      end

    else  #  not at root path: /open/
      redirect_to root_path and return if path == '/'  #  /open/ redirects to root
      unless Dir.exist?(get_path(path))  #  dir does not exist
        _path = get_path(path)
        begin
          _path = File.expand_path("..", _path)
        end while not Dir.exist?(_path)
        _path.sub!(get_path('/').chomp('/'), '')
        redirect_to File.join(open_files_path, _path) and return
      end
    end

    if @ls_paths.empty?
      @ls_paths = [path.chomp('/')]
    end
  end

  def ls
    path = params[:path] || '/'
    begin
      Dir.chdir(get_path(path))

      session[:path] = path

      files = []
      Dir.foreach('.') do |file|
        stat = File.stat(file)
        files << {
          name: file,
          directory?: stat.directory?,
          size: stat.size
        }
      end
      files = files.select{ |file| file[:directory?] } + files.select{ |file| !file[:directory?] }
      render json: files
    rescue Errno::ENOENT, Errno::ENOTDIR
      render nothing: true, status: 404
    end
  end

  def upload
    path = params[:path] || '/'
    upload_file = params[:file]
    File.open(File.join(get_path(path), upload_file.original_filename), 'wb') do |file|
      file.write(upload_file.read)
    end
    render json: {file: File.join(get_path(path), upload_file.original_filename)}
  end

  # move one or more files in a directory to trash
  def rm
    path = params[:path] || '/'

    if params.has_key?(:files) and params[:files].kind_of?(Array)
      files = params[:files]
      dests = []
      files.each do |file|
        dest = trash_file(File.join(path, file))
        break if dest == false
        dests << dest
      end
      render nothing: true, status: 500 and return if dests.empty?

      parent = File.dirname(dests[0])
      dests.map! do |dest|
        File.basename(dest)
      end
      render json: { undo: {
        name: "Move of #{dests.length} files",
        action: "#{move_files_path(parent)}",
        parameters: { _method: 'put', to: path, files: dests }
      }}
    else # if to move one file to trash
      dest = trash_file(path)

      render nothing: true, status: 500 and return if dest == false

      render json: { undo: {
          name: "Move of #{File.basename(path)}",
          action: "#{move_files_path(dest)}",
          parameters: { _method: 'put', to: path }
      }}
    end
  end

  def mv
    from = params[:path]
    to = params[:to]
    if params.has_key?(:files)
      files = params[:files]
      files.each do |file|
        if move_file(File.join(from, file), File.join(to, file)) == false
          render nothing: true, status: 500 and return
        end
      end
    else
      render nothing: true, status: 500 and return if move_file(from, to) == false
    end
    render nothing: true, status: 200
  end

  def rename
    from = params[:path]
    to = params[:to]
    if not to.nil?
      to = File.join(File.dirname(from), File.basename(to).strip)
    end
    render nothing: true, status: 500 and return if move_file(from, to) == false
    render json: { undo: {
        name: "Rename of #{File.basename(from)}",
        action: "#{rename_files_path(to)}",
        parameters: { _method: 'put', to: File.basename(from).strip }
    }}
  end

  private

    def get_path(path)
      File.join(Dir.home, path)
    end

    def trash_file(path)
      trash_path = get_path('.Trash')

      # create directory if it does not exist
      unless File.directory?(trash_path)
        begin
          Dir.mkdir trash_path, 0700
        rescue SystemCallError
          return false
        end
      end

      source = get_path(path)
      dest = File.join(trash_path, File.basename(path))

      require 'fileutils'
      begin
        FileUtils.mv source, dest
      rescue
        return false
      end

      dest.sub(get_path(''), '')
    end

    def move_file(from, to)
      return false if from.nil? or to.nil?

      from = get_path(from)
      to = get_path(to)
      unless File.exists?(from)
        return false
      end

      require 'fileutils'
      begin
        FileUtils.mv from, to
      rescue
        return false
      end
      
      true
    end
end
