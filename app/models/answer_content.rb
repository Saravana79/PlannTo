class AnswerContent < Content
	acts_as_citier
	belongs_to :question_content
end
