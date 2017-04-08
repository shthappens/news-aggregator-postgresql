require "sinatra"
require "pg"
require_relative "./app/models/article"

set :bind, '0.0.0.0'  # bind to all interfaces
set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

# Put your News Aggregator server.rb route code here

get "/" do
  @articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles") }
  erb :index
end

get "/articles" do
  @articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles") }
  erb :index
end

get "/articles/new" do
  erb :new
end

post "/articles/new" do
  @new_article_errors = []
  @new_article = Article.new(params{})
  @new_article.save

  if @new_article.errors.empty?
    redirect "/articles"
  else
    @new_article.errors.each do |error|
      @new_article_errors << error
    end
    erb :new
  end
end
