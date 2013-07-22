class ManagerController < ApplicationController

  def index
    path = params[:path] || '/'

    # if not at root path
    unless request.fullpath == '/'
      redirect_to root_path if path == '/'  #  /open/ redirects to root
      redirect_to root_path unless Dir.exist?(get_path(path))  #  dir does not exist
    end

    @ls_path = File.join(list_files_path, path).chomp('/')
  end

  def ls
    path = params[:path] || '/'
    begin
      Dir.chdir(get_path(path))
      files = []
      Dir.foreach('.') do |file|
        stat = File.stat(file)
        files << {
          name: file,
          directory?: stat.directory?,
          size: stat.size
        }
      end
      render json: files
    rescue Errno::ENOENT
      render nothing: true, status: 404
    end
  end

  private

    def get_path(path)
      File.join(Dir.home, path)
    end

end
