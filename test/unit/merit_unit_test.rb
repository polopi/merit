require 'test_helper'

# TODO: Split different objects tests in it's own files
class MeritUnitTest < ActiveSupport::TestCase
  test 'extends only meritable ActiveRecord models' do
    class User < ActiveRecord::Base
      def self.columns; @columns ||= []; end
      has_merit
    end
    class Fruit < ActiveRecord::Base
      def self.columns; @columns ||= []; end
    end

    assert User.method_defined?(:points), 'has_merit adds methods'
    assert !Fruit.method_defined?(:points), 'other models aren\'t extended'
  end

  test 'Badges get "related_models" methods' do
    class Soldier < ActiveRecord::Base
      def self.columns; @columns ||= []; end
      has_merit
    end
    class Player < ActiveRecord::Base
      def self.columns; @columns ||= []; end
      has_merit
    end
    assert Merit::Badge.method_defined?(:soldiers), 'Badge#soldiers should be defined'
    assert Merit::Badge.method_defined?(:players), 'Badge#players should be defined'
  end

  test 'Badge#last_granted returns recently granted badges' do
    # Create sashes, badges and badges_sashes
    sash = Merit::Sash.create
    badge = Merit::Badge.create(id: 20, name: 'test-badge-21')
    sash.add_badge badge.id
    Merit::BadgesSash.last.update_attribute :created_at, 1.day.ago
    sash.add_badge badge.id
    Merit::BadgesSash.last.update_attribute :created_at, 8.days.ago
    sash.add_badge badge.id
    Merit::BadgesSash.last.update_attribute :created_at, 15.days.ago

    # Test method options
    assert_equal Merit::Badge.last_granted(since_date: Time.now), []
    assert_equal Merit::Badge.last_granted(since_date: 1.week.ago), [badge]
    assert_equal Merit::Badge.last_granted(since_date: 2.weeks.ago).count, 2
    assert_equal Merit::Badge.last_granted(since_date: 2.weeks.ago, limit: 1), [badge]
  end

  test 'Merit::Score.top_scored returns scores leaderboard' do
    # Create sashes and add points
    sash_1 = Merit::Sash.create
    sash_1.add_points(10); sash_1.add_points(10)
    sash_2 = Merit::Sash.create
    sash_2.add_points(5); sash_2.add_points(5)

    # Test method options
    assert_equal [{'sash_id'=>sash_1.id, 'sum_points'=>20},
      {'sash_id'=>sash_2.id, 'sum_points'=>10}],
      Merit::Score.top_scored(table_name: :sashes)
    assert_equal  [{'sash_id'=>sash_1.id, 'sum_points'=>20}],
      Merit::Score.top_scored(table_name: :sashes, limit: 1)
  end

  test 'unknown ranking raises exception' do
    class WeirdRankRules
      include Merit::RankRulesMethods
      def initialize
        set_rank level: 1, to: User, level_name: :clown
      end
    end
    assert_raises Merit::RankAttributeNotDefined do
      WeirdRankRules.new.check_rank_rules
    end
  end

  test 'Badge#custom_fields_hash saves correctly' do
    Merit::Badge.create(id: 99, name: 'test-badge',
      custom_fields: { key_1: 'value1' })
    assert_equal 'value1', Merit::Badge.find(99).custom_fields[:key_1]
  end
end