class Schedule < ActiveRecord::Base
  include Models::CommonModels
  before_save :set_custo
  validates_presence_of :schedule_type
  before_save :validity
  belongs_to :schedule_father, :class_name=>Schedule
  belongs_to :schedule_teaching, :class_name=>Teaching
  def self. schedule_types
    SYLR::C_ALL_SCHEDULE_TYPES
  end

  # for start_time and rustion depending of all_of_day
  def validity
    fname = "#{self.class.name}.#{__method__}"
    begin
      valid=true
      if start_time.nil?
        valid=false
        msg="The start_time can't be blank "
      end
      if all_of_day == false
        if duration.nil?
          valid=false
          msg="The duration can't be blank "
        end
      else
      # if all_of_day==true, duration is not usefull
        duration=nil
        # if all_of_day==true, hour and minute must be equals to 0
        self.start_time=self.start_time.change(hour:0,minute:0,second:0)
      end
      errors.add(:base, "Schedule is not valid:#{msg}") unless valid
    rescue Exception => e
      valid = false
      msg = 'Exception during schedule validity:'
      msg += "<br/>exception=#{e}"
      errors.add(:base, msg)
    end
    LOG.debug(fname) { "validity '#{self}' =#{valid} msg=#{msg}" }

    valid
  end

  # for calendar of teaching for example
  def ident
    ret=""
    ret+="#{schedule_teaching.name}." unless schedule_teaching.nil?
    ret+="#{start_time_hour}.#{duration}.#{all_of_day}"
  end

  # for show view
  def ident_long
    ret=""
    ret+="#{schedule_teaching.name}." unless schedule_teaching.nil?
    ret+="#{start_time_date}.#{duration}.#{all_of_day}"
  end

  #enleve UTC... a la fin
  def start_time_date
    start_time.to_s[0,start_time.to_s.size-7]
  end

  # ne garde que l'heure et les minutes
  def start_time_hour
    "#{start_time.hour}:#{start_time.hour}"
  end

  def is_root?
    self.schedule_father=self
  end

  # return true if this meeting is alone, no childs
  def is_alone?
    self.schedule_father=nil
  end

  # return the childs schedules of the current one
  # same object and father different meeting (in this case, it is the root itself)
  def get_childs
    ret=[]
    Schedule.all.where("father_father_id = '#{self.id}'").to_a.each do |schedule|
      ret << schedule if(schedule!=self)
    end
    ret
  end

end
