class Post
    include ActiveModel::Model
    attr_accessor :id, :title, :content, :created_at
  
    # Path to our JSON storage file
    FILE_PATH = Rails.root.join('db', 'posts.json')
  
    # Initialize a new Post object
    def initialize(attributes = {})
      super
      @id ||= SecureRandom.uuid
      @created_at ||= Time.now.utc
    end
  
    # Save a post to the JSON file
    def save
      posts = self.class.all
      posts << self
      File.write(FILE_PATH, posts.to_json)
      self
    end
  
    # Find a post by its ID
    def self.find(id)
      all.find { |post| post.id == id }
    end
  
    # Retrieve all posts
    def self.all
      return [] unless File.exist?(FILE_PATH)
      posts_hashes = JSON.parse(File.read(FILE_PATH))
      posts_hashes.map { |post_hash| new(post_hash) }
    end
  
    # Update attributes of a post
    def update(attributes)
      posts = self.class.all
      post_to_update = posts.find { |p| p.id == self.id }
      return false unless post_to_update
  
      post_to_update.title = attributes[:title] if attributes[:title]
      post_to_update.content = attributes[:content] if attributes[:content]
  
      # Re-serialize the entire array back to JSON
      File.write(FILE_PATH, posts.to_json(methods: [:id, :title, :content, :created_at]))
      self
    end
  
    # Delete a post by its ID
    def destroy
      posts = self.class.all
      posts.reject! { |p| p.id == self.id }
      File.write(FILE_PATH, posts.to_json)
    end
  
    # Helper method to present the post as a hash
    def as_json(options = {})
      {
        id: id,
        title: title,
        content: content,
        created_at: created_at
      }
    end
  end