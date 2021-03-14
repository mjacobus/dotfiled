# frozen_string_literal: true

module Dotfiled
  module AlternativeFile
    class File
      def initialize(path = "")
        @path = Pathname.new(path.to_s)
      end

      def to_s
        @path.to_s.gsub("//", "/")
      end

      def start_with?(prefix)
        to_s.start_with?(prefix)
      end

      def without_prefix(prefix)
        sub(/^#{prefix}/, "")
      end

      def match?(*args)
        to_s.match?(*args)
      end

      def split(char = "/")
        to_s.split(char)
      end

      def sub(find, replace)
        new(to_s.sub(find, replace))
      end

      def gsub(find, replace)
        new(to_s.gsub(find, replace))
      end

      def join(other_part)
        new(@path.join(other_part.to_s))
      end

      def prefix_with(prefix)
        new(prefix).join(self)
      end

      def exist?
        ::File.exist?(to_s)
      end

      private

      def new(path)
        self.class.new(path)
      end

      class << self
        def join(parts)
          file = File.new("")
          parts.flatten.each { |part| file = file.join(part) }
          file
        end
      end
    end
  end
end
