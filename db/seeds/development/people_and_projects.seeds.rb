class << self
  def create_person(name, email_suffix, workgroup)
    first_name, last_name = name.split(' ')
    email = "#{first_name[0]}#{last_name[0]}#{email_suffix}@example.com".downcase
    p = Person.where(first_name: first_name, last_name: last_name, email: email).first_or_create!
    p.work_groups << workgroup unless p.work_groups.include?(workgroup)
    p
  end
end

# Project
uk_proj = Project.where(title: "iGrid").first_or_create!
uk_inst = Institution.where(title: "University of Duckchester", country: 'United Kingdom').first_or_create!
uk_workgroup = WorkGroup.where(project_id: uk_proj.id, institution_id: uk_inst.id).first_or_create!

["Flynn McCall", "Norbert Morrissey" "Stewart Irwin", "Natasha Stratford", "Adam Willingham",
 "Anastasiya Nenasheva", "Daniel Meadows", "Neil Baird", "Stanley Zeeland-Rogers", "Rainer Schüttler",
 "Shaun Suffolk", "Coraline Galbraith"].each_with_index do |name, index|
  create_person(name, "#{index}.dcuni", uk_workgroup)
end

# Project with two institutions
aus_proj = Project.where(title: "StrayaBioDiv").first_or_create!
aus_inst1 = Institution.where(title: "NSW Institute of Technology", country: 'Australia').first_or_create!
aus_inst2 = Institution.where(title: "ACT Institute of Science", country: 'Australia').first_or_create!
aus_wg1 = WorkGroup.where(project_id: aus_proj.id, institution_id: aus_inst1.id).first_or_create!
aus_wg2 = WorkGroup.where(project_id: aus_proj.id, institution_id: aus_inst2.id).first_or_create!
["Brody Johnston", "Karl Kennedy", "Jimi Hendrix"].each_with_index do |name, index|
  create_person(name, "#{index}.nsw", aus_wg1)
end
["John Smith", "Judy Foster", "Victoria Castlemaine"].each_with_index do |name, index|
  create_person(name, "#{index}.act", aus_wg2)
end

puts 'Seeded dummy projects and people'
