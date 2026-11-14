# frozen_string_literal: true

require "decidim/common_need/seeds"

participatory_space = if defined?(Decidim::ParticipatoryProcess)
                        Decidim::ParticipatoryProcess.first
                      end

Decidim::CommonNeed::Seeds.new(participatory_space: participatory_space).call
