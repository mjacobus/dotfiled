# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module Dotfiled
  module AlternativeFile
    class Finder
      def execute(argv)
        file = File.new(argv.first)

        if file.match?(/.*_(test|spec).rb$/)
          return find_alternative_for_ruby_test_file(file)
        end

        if file.match?(/.*\.rb$/)
          find_ruby_test_file_for(file)
        end
      end

      private

      # rubocop:disable Metrics/CyclomaticComplexity:
      def find_ruby_test_file_for(file, prefix: File.new)
        if file.match?(/^packages/)
          return find_packaged_test_file_for(file)
        end

        if file.start_with?("public/") || file.start_with?("private/")
          file = file.without_prefix("public/").without_prefix("private/")
        end

        minitest_folder = prefix.join("test")
        minitest = minitest_folder.join(file).sub(/(lib|app)/, "").sub(".rb", "_test.rb")

        rspec_folder = prefix.join("spec")
        rspec = rspec_folder.join(file).sub(/(lib|app)/, "").sub(".rb", "_spec.rb")

        candidates = [rspec, minitest]

        if file.match?("controllers/")
          candidate = file
                      .sub("app/controllers", "spec/requests")
                      .sub("controller.rb", "request_spec.rb")

          candidates << candidate
          candidates << candidate.sub(%r{^spec/}, "test/").sub("spec.rb", "test.rb")
        end

        if minitest_folder.exist? && rspec_folder.exist?
          return best_candidate(candidates)
        end

        if minitest_folder.exist?
          return minitest
        end

        rspec
      end
      # rubocop:enable Metrics/CyclomaticComplexity:

      def find_packaged_test_file_for(file)
        parts = file.split
        rejected_parts = %w[private public]

        package = File.join([parts[0..1]])
        file = [parts[2..]]
               .flatten
               .reject { |p| rejected_parts.include?(p) }
               .join("/")

        find_ruby_test_file_for(file, prefix: package)
      end

      def find_alternative_for_ruby_test_file(file, prefix: File.new)
        if file.match?(/^packages/)
          return find_packaged_file_for_test(file)
        end

        if file.match?(/request_spec.rb$/)
          return find_controller_file_for_test(file)
        end

        file = file
               .sub(/_(test|spec).rb$/, ".rb")
               .sub(%r{^(test|tests|spec|specs)/}, "")

        possible_folders = ["lib", "app/models", "app/controllers", "app", "private", "public"]
        candidates = possible_folders.map { |folder| prefix.join(folder).join(file) }
        best_candidate(candidates)
      end

      def find_packaged_file_for_test(file)
        parts = file.split
        package = File.join([parts[0..1]])
        file = File.join([parts[2..]])
        prefix = File.new(package)

        find_alternative_for_ruby_test_file(file, prefix: prefix)
      end

      def find_controller_file_for_test(file)
        file = file.split("requests/").last
        file = File.new(file)
        file = file.gsub("request_spec", "controller")

        find_alternative_for_ruby_test_file(file)
      end

      def best_candidate(candidates)
        candidates.find(&:exist?) || candidates.first
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
