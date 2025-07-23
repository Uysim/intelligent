require "anthropic"
require_relative "base"

module Intelligent
  module Llm
    class Anthropic < Base
      def self.available_models
        {
          "claude-sonnet-4-20250514" => "Claude Sonnet 4 (Recommended)",
          "claude-opus-4-20250514" => "Claude Opus 4 (Most Capable)",
          "claude-3-7-sonnet-20250219" => "Claude Sonnet 3.7 (Fast)",
          "claude-3-5-haiku-20241022" => "Claude Haiku 3.5 (Fastest)"
        }
      end
    
      def self.default_model
        "claude-sonnet-4-20250514"
      end
    
      def initialize(model: self.class.default_model)
        super(provider: "anthropic", model: model)
        @client = ::Anthropic::Client.new(api_key: api_key)
      end
    
      def generate(prompt_content, files = [])
        raise ArgumentError, "API key not configured" unless api_key_present?
    
        # Prepare message content
        content = [ { type: "text", text: prompt_content } ]
    
        # Add files to content if provided
        if files && !files.empty?
          files.each do |file|
            file_content = prepare_file_content(file)
            content << file_content if file_content
          end
        end
    
        begin
    
    
          response = @client.messages.create(
            model: model,
            max_tokens: 4000,
            messages: [
              {
                role: "user",
                content: content
              }
            ]
          )
    
          {
            success: true,
            text: response.content.first.text,
            usage: response.usage&.to_h
          }
        rescue ::Anthropic::Errors::APIError => e
          {
            error: "API request failed: #{e.message}",
            status: e.status
          }
        rescue => e
          { error: "Request failed: #{e.message}" }
        end
      end
    
      private
    
      def prepare_file_content(file)
        # Determine content type from file extension
        content_type = determine_content_type(file.path)
        
        case content_type
        when /^image\//
          # For images, we need to encode as base64
          {
            type: "image",
            source: {
              type: "base64",
              media_type: content_type,
              data: Base64.strict_encode64(file.read)
            }
          }
        when /^text\//
          # For text files, we can include the content directly
          {
            type: "text",
            text: file.read.dup.force_encoding("UTF-8")
          }
        when "application/pdf"
          # For PDFs, use the document content type with base64 encoding
          {
            type: "document",
            source: {
              type: "base64",
              media_type: "application/pdf",
              data: Base64.strict_encode64(file.read)
            }
          }
        else
          raise "Unsupported file type: #{content_type} for file: #{file.path}"
        end
      end
      
      def determine_content_type(file_path)
        case File.extname(file_path).downcase
        when '.jpg', '.jpeg'
          'image/jpeg'
        when '.png'
          'image/png'
        when '.gif'
          'image/gif'
        when '.webp'
          'image/webp'
        when '.txt', '.md', '.rb', '.py', '.js', '.html', '.css', '.json', '.xml', '.yaml', '.yml'
          'text/plain'
        when '.pdf'
          'application/pdf'
        else
          'application/octet-stream'
        end
      end
    end
  end
end