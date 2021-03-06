class Notebook < ActiveRecord::Base
  include Models::CommonModels
  before_save :set_custo
  before_save :validity
  validates_presence_of :name
  validates :name, uniqueness: true
  #suivant les relations vers
  belongs_to :student
  ####has_and_belongs_to_many :teacher, join_table: :notebook_teachers
  ####has_many :notebook_teacher, :foreign_key=>:teacher_id
  def validity
    msg=""
    valid=true
    unless self.student.notebook.nil? || self.student.notebook.ident==self.ident
      msg="L'étudiant a déja un cahier (#{self.student.notebook.ident})"
    valid=false
    end
    self.errors.add(:base, "Notebook is not valid:#{msg}") unless valid
    valid
  end
  def get_teachers
    ret=[]
    teachings=self.student.student_class_school.teachings
    teachings.to_a.each do |teaching|
      ret<< teaching.teaching_teacher
    end
    ret
  end
   # pour h_table student => notebook
  def notebooktext_short
    truncate_text_words(self.notebooktext, 100)
  end
end
