class ManagerController < ApplicationController

  def index
  end

  def ls
    path = params[:path] || '/'
    begin
      Dir.chdir(File.join(Dir.home, path))
      files = Dir.entries('.')
      files.delete('.')
      files.delete('..')
      render json: files
    rescue Errno::ENOENT
      render nothing: true, status: 404
    end
  end

end
