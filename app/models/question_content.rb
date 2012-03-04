class QuestionContent < Content
	acts_as_citier
	has_many :answer_contents
end
