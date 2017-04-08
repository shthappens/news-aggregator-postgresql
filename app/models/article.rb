require 'pry'

class Article

  attr_reader :title, :url, :description, :errors

  def initialize(params = {})
    @title = params["title"]
    @url = params["url"]
    @description = params["description"]
    @errors = []
    @input_array = [@title, @url, @description]
    @valid = true
  end

  def self.all
    article_array = []
    @articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles") }
    @articles.each do |article|
      article_array << Article.new(article)
    end
    article_array
  end

  def incomplete_entry?
    if @input_array.any? { |input| input.empty? }
      @errors << "Please completely fill out form"
      @valid = false
    end
    @valid
  end

  def valid_url?
    if !@url.include?("http") && !@url.empty?
      @errors << "Invalid URL"
      @valid = false
    end
    @valid
  end

  def duplicate_entry?
    db_urls = db_connection { |conn| conn.exec_params("SELECT url FROM articles") }
    db_urls.each do |url|
      if !url.empty? && url.has_value?(@url)
        @errors << "Article with same url already submitted"
        @valid = false
      end
    end
    @valid
  end

  def min_length?
    if @description.size > 0 && @description.size < 20
      description_error = "Description must be at least 20 characters long"
      @errors << description_error
      @valid = false
    end
    @valid
  end

  def valid?
    incomplete_entry?
    valid_url?
    duplicate_entry?
    min_length?
    if @errors.empty?
      @valid = true
    else
      @valid = false
    end
    @valid
  end

  def save
    if valid?
      db_connection do |conn|
        conn.exec_params("INSERT INTO articles (title, url, description)
        VALUES ($1, $2, $3);",
        [@title, @url, @description])
      end
      @valid = true
    end
    @valid
  end
end
