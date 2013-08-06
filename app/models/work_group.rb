class WorkGroup < ActiveRecord::Base
  belongs_to :institution
  belongs_to :project
  has_many :group_memberships, :dependent => :destroy
  has_many :people, :through=>:group_memberships

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :institution, :project

  def destroy
    if people.empty?
        super
    else
      raise Exception.new("Cannot delete the " +description+ ". This Work Group has "+people.size.to_s+" people associated with it. Please disassociate first the people from this Work Group")
    end
  end
  
  def description
    project.name + " at " + institution.name
  end

end
