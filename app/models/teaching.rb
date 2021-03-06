class Teaching < ActiveRecord::Base
  include Models::CommonModels
  before_save :set_custo
  before_destroy :check_destroy
  before_destroy :destroy_schedules_childs
  before_save :validity
  before_update :validity
  validates_presence_of :name, :teaching_class_school_id, :teaching_teacher_id, :teaching_matter_id
  validates_presence_of :teaching_location_id, :teaching_start_time, :teaching_repetition
  validates_uniqueness_of :name
  validates_uniqueness_of :teaching_start_time

  belongs_to :teaching_class_school,class_name: 'ClassSchool'
  belongs_to :teaching_teacher,class_name: 'Teacher'
  belongs_to :teaching_matter, class_name: 'Matter'
  belongs_to :teaching_domain, class_name: 'Element'
  belongs_to :teaching_location, class_name: 'Location'

  has_many :presents, :foreign_key=>:teaching_id
  has_many :schedules, :foreign_key=>:schedule_teaching_id
  def self.teaching_domains
    Element.all.where("for_what = 'teaching_domain' ").to_a
  end

  def self.teaching_domains_names
    teaching_domains.map {|r| [r.name, r]}
  end

  def teaching_class_school_ident
    teaching_class_school.ident
  end

  def teaching_teacher_ident
    teaching_teacher.ident
  end

  def teaching_matter_ident
    teaching_matter.ident
  end

  def teaching_domain_ident
    teaching_domain.ident unless teaching_domain.nil?
  end

  def teaching_location_ident
    teaching_location.ident
  end

  # verifier le nombre d'eleves de la classe et la salle avant de creer le teaching
  # verifier si le professeur enseigne la matiere donnée
  def validity
    msg=""
    valid=true
    unless self.teaching_class_school.nil?
      nb_in_class=self.teaching_class_school.nb_max_student
      nb_in_location=self.teaching_location.location_nb_max_person
      if nb_in_class > nb_in_location
        msg+=" La salle de classe est pleine, choisissez en une autre !!"
      valid=false
      end
    end
    # coherence teacher matter
    matters=self.teaching_teacher.matters.to_a
    unless matters.include? self.teaching_matter
      msg+=" Le professeur #{self.teaching_teacher.ident} et la matière #{self.teaching_matter.ident} sont incohérents"
    valid=false
    end
    self.errors.add(:base, "Teaching is not valid:#{msg}") unless valid
    valid
  end

  # verifie la non presence de references
  def check_destroy
    valid=true
    msg=""
    if presents.count > 0
      valid=false
      msg+=" There are #{presents.count} presents references"
    end
    if schedules.count > 0
      valid=false
      msg+=" There are #{schedules.count} schedules references"
    end
    self.errors.add(:base, "Teaching can't be destroyed:#{msg}") unless valid
    valid
  end

  def create_schedules(teaching_params)
    msg=nil
    schedule_father = create_schedule_father(teaching_params)
    unless schedule_father.nil?
      if schedule_father.save
        unless  self.teaching_repetition.nil? && self.teaching_repetition == SYLR::C_TEACHING_NONE
          ind = 1
          i=1
          while ind < self.teaching_repetition_number.to_i  && msg.nil? do
            #puts "==================== create_schedules.create_schedules : schedule #{ind} in creation i=#{i}"
            new_start_time=schedule_father.start_time
            # values in second
            day=60*60*24
            week=day*7
            case self.teaching_repetition
            when SYLR::C_TEACHING_DAY
              new_start_time+=day*(i)
            when SYLR::C_TEACHING_WEEK
              new_start_time+=week*(i)
            else
            msg="Bad value (#{teaching_repetition}) for repetition (#{SYLR::C_ALL_TEACHING_REPETITION})"
            end
            if msg.nil?
              # copy du pere !!!
              schedule_child =schedule_father.dup
              # traitement de la date
              schedule_child.start_time=new_start_time
              # c'est un fils du pere !!
              schedule_child.schedule_father=schedule_father

              unless schedule_child.exist_unworking?
                # si ce n'est pas un jour non travaille, on peut le sauver
                st=schedule_child.save
                ind+=1
                unless st
                  msg="Schedule_child(#{i}) not saved: #{schedule_child.errors.full_messages}"
                end
              end
            else
            # on essaie le prochain jour quand meme
            ind+=1
            end
            i+=1
          end
        end
      else
        msg="Schedule father not saved #{schedule_father.errors.full_messages}"
      end
    else
      msg="Schedule father not created "
    end
    self.errors.add(:base, "Schedule repetition is bad:#{msg}") unless msg.nil?
    # retour true ou false
    msg.nil?
  end

  # si repetition ou repet number change, detruire les scedules et les refaire
  def update_schedules(teaching_params)
    msg=""
    ret=true
    if teaching_params["teaching_repetion"]!=self.teaching_repetition ||
    teaching_params["teaching_repetition_number"]!=self.teaching_repetition_number
      if destroy_schedules_childs
        # on recree les schedules
        unless create_schedules(teaching_params)
          msg="Error during schedules repetition update"
        ret=false
        end
      else
        msg="Error during destroying schedules"
      ret=false
      end
    end
    self.errors.add(:base, "Schedule repetition update is bad: #{msg}") unless ret
    # retour true ou false
    ret
  end

  # return the childs schedules of the current one
  # same object and father different meeting (in this case, it is the root itself)
  def get_schedules_childs
    ret=[]
    Schedule.all.where("schedule_teaching_id = '#{self.id}'").to_a.each do |schedule|
      ret << schedule
    end
    ret
  end

  def destroy_schedules_childs
    msg=nil?
    childs=self.get_schedules_childs
    childs.each do |child|
      unless msg==false
        unless child.destroy
          msg="Pb. on #{child.ident_long}"
        end
      end
    end
    self.errors.add(:base, "A schedule was not destroyed : #{msg}") unless msg==false
    # retour true ou false
    msg==false
  end

  def get_schedules
    #puts "=========== schedules=#{schedules.size} days=#{Schedule.get_day_schedules.size}"
    self.schedules.to_a.concat(Schedule.get_only_all_day)
  end

  protected

  def create_schedule_father(teaching_params)
    schedule_params=teaching_params
    schedule_params.delete :name
    schedule_params.delete :teaching_class_school_id
    schedule_params.delete :teaching_teacher_id
    schedule_params.delete :teaching_matter_id
    schedule_params.delete :teaching_domain_id
    schedule_params.delete :teaching_repetition
    schedule_params.delete :teaching_location_id
    schedule_params.delete :teaching_repetition_number
    schedule_params.delete :description
    schedule_params[:schedule_type]=SYLR::C_SCHEDULE_WORKING
    # affectation du teaching
    schedule_params[:schedule_teaching_id]=self.id
    transfert_start_time(teaching_params,schedule_params,:teaching_start_time,:start_time)
    ret=Schedule.new(schedule_params)
    # to be root
    ret.schedule_father=ret
    ret
  end

  def transfert_start_time(from_params,to_params,from_param,to_param)
    to_params["#{to_param}(1i)"]=from_params["#{from_param}(1i)"]
    to_params["#{to_param}(2i)"]=from_params["#{from_param}(2i)"]
    to_params["#{to_param}(3i)"]=from_params["#{from_param}(3i)"]
    to_params["#{to_param}(4i)"]=from_params["#{from_param}(4i)"]
    to_params["#{to_param}(5i)"]=from_params["#{from_param}(5i)"]
    to_params.delete "#{from_param}(1i)"
    to_params.delete "#{from_param}(2i)"
    to_params.delete "#{from_param}(3i)"
    to_params.delete "#{from_param}(4i)"
    to_params.delete "#{from_param}(5i)"
  end

end
