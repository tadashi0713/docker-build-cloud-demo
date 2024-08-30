module Taxonomy
  class TopicTaxonomy
    def initialize(adapter: RedisCacheAdapter.new, tree_builder_class: Tree)
      @adapter = adapter
      @tree_builder_class = tree_builder_class
    end

    def ordered_taxons
      @ordered_taxons ||= ordered_branches.select(&:visible_to_departmental_editors)
    end

    def ordered_taxons_transformed(selected_taxon_content_ids = [])
      transform_taxon(ordered_taxons, selected_taxon_content_ids)
    end

    def all_taxons
      @all_taxons ||= branches.flat_map(&:taxon_list)
    end

    def visible_taxons
      @visible_taxons = visible_branches.flat_map(&:taxon_list)
    end

    def visible_branches
      @visible_branches ||= branches.select(&:visible_to_departmental_editors)
    end

  private

    def branches
      @branches ||= @adapter.taxon_data.map do |taxon_hash|
        @tree_builder_class.new(taxon_hash).root_taxon
      end
    end

    def ordered_branches
      @ordered_branches ||= branches.sort_by(&:name)
    end

    def transform_taxon(taxons, selected_taxon_content_ids)
      taxons.map do |taxon|
        checked = taxon.taxon_list.any? do |descendant_taxon|
          selected_taxon_content_ids.include?(descendant_taxon.content_id)
        end

        {
          label: taxon.name,
          value: taxon.content_id,
          items: (transform_taxon(taxon.children, selected_taxon_content_ids) if taxon.children),
          checked:,
        }
      end
    end
  end
end
