class Domain < ApplicationRecord
  belongs_to :owner, optional: true, polymorphic: true

  has_many :caches_domains, dependent: :destroy
  has_many :caches, source: :cache, through: :caches_domains

  validates :type, presence: true
  validates :value, presence: true, uniqueness: { scope: %i[owner_type owner_id] }

  scope :global, -> { where(owner: nil) }
  scope :client, ->(client = nil) {
    client_id = case client
                when Client
                  client.id
                else
                  client
                end
    records = where(owner_type: 'Client')
    records = records.where(owner_id: client_id) if client_id
    records
  }

  before_validation if: ->() { last_updated_at.nil? } do
    self.last_updated_at = Time.now.utc
  end

  def values
    defined?(super) ? super : [value]
  end

  def cache!
    ActiveRecord::Base.transaction do
      last_updated_at = Time.now.utc
      ids_caches_domains_to_keep = []

      values.each_slice(10_0000) do |domains|
        caches_exist = cache_klass.select(:id, :value).where(value: domains).to_a
        ids_caches_exist = caches_exist.map(&:id)
        new_caches_ids = cache_klass.import((domains - caches_exist.map(&:value)).map { |v| { value: v, last_updated_at: last_updated_at } }).ids

        caches_domains_exist = caches_domains.select(:id, :cache_id).where(cache_id: ids_caches_exist).to_a
        ids_caches_domains_exist = caches_domains_exist.map(&:id)
        caches_domains_to_create = (new_caches_ids + ids_caches_exist) - caches_domains_exist.map(&:cache_id)
        ids_caches_domains_to_keep += ids_caches_domains_exist
        ids_caches_domains_to_keep += caches_domains.import(caches_domains_to_create.map { |v| { cache_id: v, last_updated_at: last_updated_at } }).ids

        caches_domains.where(id: ids_caches_domains_exist).update_all(last_updated_at: last_updated_at)
        caches.where(id: ids_caches_exist).update_all(last_updated_at: last_updated_at)

        if caches_domains_to_create.any?
          update_columns last_updated_at: last_updated_at
          increment!(:caches_domains_count, caches_domains_to_create.size)

          cache_klass.where(id: caches_domains_to_create).update_all(
            caches_domains_count: Arel::Nodes::InfixOperation.new(
              :+, Arel::Nodes::NamedFunction.new('COALESCE', [cache_klass.arel_table[:caches_domains_count], 0]), 1
            )
          )
        end
      end

      caches_domains.where.not(id: ids_caches_domains_to_keep).destroy_all
    end
  end

  def self.print_table(data, column_titles, column_sizes)
    num_columns = column_titles.size
    line_size = column_sizes.sum + (3 * (num_columns - 1))

    puts "╔═" + ("═" * line_size) + "═╗"
    puts "║ " + num_columns.times.map { |n| column_titles[n].ljust(column_sizes[n]) }.join(' ║ ') + " ║"
    puts "╠═" + ("═" * line_size) + "═╣"

    data.each do |columns|
      columns = yield columns if block_given?

      puts "║ " + num_columns.times.map { |n| (columns[n].is_a?(Array) ? columns[n].join(', ') : columns[n].to_s).ljust(column_sizes[n]) }.join(' ║ ') + " ║"
    end

    puts "╚═" + ("═" * line_size) + "═╝"
  end

  def self.cache!(debug: false)
    return find_each(batch_size: 10_000, &:cache!) unless debug

    data = find_each(batch_size: 10_000).pluck(:id, :value, :caches_domains_count)
    column_titles = %w[# Value Old New Duration]
    column_sizes = (column_titles.size - 1).times.map { |n| [data.size.positive? ? data.max_by { |c| c[n].to_s.size }[n].to_s.size : 0, column_titles[n].size].max }
    column_sizes[3] = [column_sizes[2] * 2 + 5, 18].max
    column_sizes[4] = 11

    print_table(data, column_titles, column_sizes) do |columns|
      start_time = Time.now

      find(columns[0]).cache!

      end_time = Time.now

      num_caches_domains = find(columns[0]).caches_domains.size
      num_new_caches_domains = num_caches_domains - columns[2]
      columns[3] = "#{num_caches_domains}"
      columns[3] += " (#{num_new_caches_domains.negative? ? '' : '+'}#{num_new_caches_domains})" unless num_new_caches_domains.zero?
      columns[4] = end_time - start_time
      columns
    end
  end

  def self.report(linked: false)
    select(:id, :value, :caches_domains_count).order(:id).map do |domain|
      duplicated_count = domain.caches.select(:caches_domains_count).select { |c| c.caches_domains.size > 1 }.size
      num_caches = domain.caches_domains.size

      columns = [
        domain.id, domain.value,
        duplicated_count,
        num_caches,
        num_caches > 0 ? (duplicated_count / num_caches.to_f * 100).round(2) : 0
      ]
      columns << Domain.unscoped.where(id: CachesDomain.where(cache_id: domain.caches).select(:domain_id)).pluck(:id) if linked
      columns
    end
  end

  def self.print_report(linked: false)
    data = report(linked: linked)
    column_titles = %w[# Value Duplicated Count Percent]
    column_titles << 'Linked' if linked
    column_sizes = column_titles.size.times.map { |n| [data.size.positive? ? data.max_by { |c| c[n].to_s.size }[n].to_s.size : 0, column_titles[n].size].max }

    print_table(data, column_titles, column_sizes)

    nil
  end
end
