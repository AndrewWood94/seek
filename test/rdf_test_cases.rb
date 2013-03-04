
module RdfTestCases
  def test_get_rdf
    object = rest_api_test_object

    #this strange bit of code forces the model to be reloaded from the database after being created by FactoryGirl.
    #this is to (possibly) avoid a variation in the updated_at timestamps. It means the comparison is always against what
    #in the in the database, rather than between that created in memory and that in the database.
    object = object.class.find(object.id)

    expected_resource_uri =  eval("#{object.class.name.underscore}_url(object,:host=>'localhost',:port=>'3000')")

    assert object.can_view?
    assert object.respond_to?(:to_rdf)
    get :show, :id=>object, :format=>"rdf"
    assert_response :success
    rdf = @response.body

    assert_equal object.to_rdf, rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new(expected_resource_uri), reader.statements.first.subject
    end

  end
end