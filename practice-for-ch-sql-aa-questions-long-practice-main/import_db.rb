require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
    include Singleton
    def initialize 
        super('aa_questions.db')
        self.type_translation = true 
        self.results_as_hash = true 
    end 
end 
class Users 
    def self.all 
        data = QuestionsDatabase.instance.execute("SELECT * FROM users")
        data.map {|datum| Users.new(datum)}
    end 
    def self.find_by_name(name)
    end 
    def initialize(user_attributes)
        @id = user_attributes['id']
        @fname = user_attributes['fname']
        @lname = user_attributes['lname']
    end 
end 
class Questions
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
        data.map { |datum| Questions.new(datum)}
    end 
    def self.find_by_id(target_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
        selected_question_hash = data.select { |datum| datum['id'] = target_id}
        selected_question.map { |question| Questions.new(question)}
        # Try variation of passing in the target_id into the SQL statement 
    end 
    def initialize (question)
        @id = question['id']
        @title = question['title']
        @body = question['body']
        @associated_authorr = question['associated author']
    end 
end 
