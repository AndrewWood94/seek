require 'test_helper'

class ObservationUnitTest < ActiveSupport::TestCase

  test 'max factory' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    refute_nil obs_unit.created_at
    refute_nil obs_unit.updated_at
    refute_empty obs_unit.projects
    refute_empty obs_unit.creators
    refute_nil obs_unit.other_creators
    refute_nil obs_unit.extended_metadata
    refute_nil obs_unit.extended_metadata.extended_metadata_type
    refute_nil obs_unit.study
    refute_empty obs_unit.study.observation_units
    refute_empty obs_unit.samples
    refute_empty obs_unit.data_files
  end


  test 'to rdf' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    assert obs_unit.rdf_supported?
    rdf = obs_unit.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/observation_units/#{obs_unit.id}"), reader.statements.first.subject
      type = reader.statements.detect{|s| s.predicate == RDF.type}
      assert_equal RDF::URI('http://purl.org/ppeo/PPEO.owl#observation_unit'), type.object
    end
  end

  test 'policy' do
    obs_unit = FactoryBot.create(:observation_unit)
    contributor = obs_unit.contributor
    person2 = FactoryBot.create(:person)
    refute_nil obs_unit.policy

    assert obs_unit.can_manage?(contributor)

    obs_unit.policy = FactoryBot.create(:public_policy)
    assert obs_unit.can_view?(nil)
    assert obs_unit.can_view?(contributor)
    assert obs_unit.can_view?(person2)

    obs_unit.policy = FactoryBot.create(:private_policy)
    refute obs_unit.can_view?(nil)
    assert obs_unit.can_view?(contributor)
    refute obs_unit.can_view?(person2)
  end

  test 'can destroy' do
    obs_unit = FactoryBot.create(:max_observation_unit)
    refute_empty obs_unit.data_files
    assert_difference('ObservationUnit.count', -1) do
      assert_difference('ObservationUnitAsset.count', -3) do
        assert_difference('ExtendedMetadata.count', -1) do
          assert_difference('AssetsCreator.count', -1) do
            assert_difference('Policy.count', -1) do
              User.with_current_user(obs_unit.contributor) do
                obs_unit.destroy
              end
            end
          end
        end
      end
    end
  end

  test 'validation' do
    obs_unit = FactoryBot.build(:observation_unit)
    assert obs_unit.valid?

    obs_unit.title = ''
    refute obs_unit.valid?

    obs_unit = FactoryBot.build(:observation_unit)
    obs_unit.study = nil
    refute obs_unit.valid?

    obs_unit = FactoryBot.build(:observation_unit)
    obs_unit.projects = []
    refute obs_unit.valid?

  end


end