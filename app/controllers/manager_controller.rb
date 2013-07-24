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
    rescue Errno::ENOENT
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

  private

    def get_path(path)
      File.join(Dir.home, path)
    end

end
