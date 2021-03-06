module Models
  module CommonModels
    public
    # modifie les attributs avant edition
    def self.included(base)
      base.extend(ClassMethods)
    # a appelle extend du sous module ClassMethods sur "base", la classe dans laquelle tu as inclue la lib
    end

    # methodes of class begin
    module ClassMethods
      def datetime_short(datetime)
        #on met la date + heure minutes
        datetime.to_s[0,datetime.to_s.size-9]
      end

      def datetime_todate(datetime)
        #on met la date
        val.to_s.to_date.to_s
      end

      def get_day_schedules
        Schedule.select("*").where("schedule_teaching_id = -1")
      end

      def get_all
        all.to_a
      end

      def get_all_not_me(object_to_exclude)
        get_all.delete(object_to_exclude)
      end

      #def get_all_names
      #  get_all.map {|r| ["#{r.id}.#{r.name}", r]}
      #get_all.map {|r| [r.name, r]}
      #end

      # for student,responsible,teacher
      def all_person_status
        SYLR::C_ALL_PERSON_STATUS
      end

    end
    # methodes of class end

    # methodes of object begin
    def set_custo
      #puts "=============set_custo avant custo: #{self.inspect}"
      self.custo=SYLR::V_APP_CUSTO
    #puts "=============set_custo apres custo: #{self.inspect}"
    end

    def ident
      # mode debug, rajout de l'id
      if LOG.level==0
        "#{id}.#{name}"
      else
        "#{name}"
      end
    end

    # return the model name in lower case with underscore
    # UserAppli becomes user_appli
    #def modelname
    #  fname = "#{self.class.name}.#{__method__}:"
    #  ret = self.class.name.underscore
    #  ret
    #end

    # tronque une chaine en n mots
    def truncate_text_words(text, len = 25, end_string = " ...")
      return if text.blank?
      words = text.split()
      ret=words[0..(len-1)].join(' ') + (words.length > len ? end_string : '')
      ret
    end

  # methodes of object end

  end
end
