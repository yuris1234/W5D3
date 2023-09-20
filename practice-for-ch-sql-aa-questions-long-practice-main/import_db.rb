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
        data = QuestionsDatabase.instance.execute("SELECT * FROM users WHERE fname = '#{name}'")
        data.map {|user| Users.new(user)}
    end 
    attr_accessor :id, :fname, :lname
    def initialize(user_attributes)
        @id = user_attributes['id']
        @fname = user_attributes['fname']
        @lname = user_attributes['lname']
    end 
    def followed_questions
        QuestionFollows.followed_questions_for_user_id(id)
    end 

    def authored_questions
        Question.find_by_author_id(id)
    end

    def authored_replies
        Replies.find_by_user_id(id)
    end
end 
class Questions
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
        data.map { |datum| Questions.new(datum)}
    end 
    def self.find_by_author_id(target_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
        selected_question_hash = data.select { |datum| datum['associated_author'] == target_id}
        selected_question_hash.map { |question| Questions.new(question)}
        # Try variation of passing in the target_id into the SQL statement 
    end 
    attr_accessor :id, :title, :body
    def initialize (question)
        @id = question['id']
        @title = question['title']
        @body = question['body']
        @associated_author = question['associated author']
    end 
    def author 
        @associated_author
    end
    def replies 
        Replies.find_by_question_id(id)
    end
    def followers
        QuestionFollows.followers_for_question_id(id)
    end 
    def likers
        QuestionLike.likers_for_question_id(id)
    end 
end 
class QuestionFollows 
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
        data.map {|datum| QuestionFollows.new(datum) }
    end
    def self.followers_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT 
            * 
        FROM 
            users 
        JOIN 
            question_follows ON users.id = question_follows.user_id
        WHERE 
            question_follows.question_id = ? 
        SQL
        data.map {|datum| Users.new(datum) }
    end 
    def self.most_followed_questions(num)
        data = QuestionsDatabase.instance.execute(<<-SQL, num)
        SELECT
            questions.id AS id, title, body, associated_author
         FROM 
            questions
        JOIN
            question_follows ON question_follows.question_id = questions.id
        GROUP BY 
            question_id 
        ORDER BY
            COUNT(user_id) DESC
        LIMIT ?
        SQL
        data.map {|datum| Questions.new(datum) }
    end 
    def self.most_followed
        QuestionFollows.most_followed_questions(1)
    end 

     def self.followed_questions_for_user_id(target_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, target_id)
            SELECT
                questions.id, questions.title, questions.body, questions.associated_author
            FROM
                questions
            JOIN
                question_follows ON questions.id = question_follows.question_id
            JOIN
                users ON users.id = question_follows.user_id
            WHERE
                users.id = ?
        SQL
        data.map {|datum| Questions.new(datum)}
    end

    def initialize(question_follows_attributes)
        @id = question_follows_attributes['id']
        @question_id = question_follows_attributes['question_id']
        @user_id = question_follows_attributes['user_id']
    end

end
class Replies
    def self.all 
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
        data.map {|datum| Replies.new(datum) }
    end

    def self.find_by_question_id(question_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE question_id = '#{question_id}'")
        data.map {|datum| Replies.new(datum) }

    end

    def self.find_by_user_id(user_id)
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE user_id = '#{user_id}'")
        data.map {|datum| Replies.new(datum)}
    end

    def initialize(replies_attr)
        @id = replies_attr['id']
        @question_id = replies_attr['question_id']
        @parent_id = replies_attr['parent_id']
        @user_id = replies_attr['user_id']
        @body = replies_attr['body']
    end

    attr_accessor :id, :question_id, :parent_id, :user_id, :body
    def author
        @user_id  
    end

    def question 
        @question_id
    end

    def parent_reply
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE id = #{parent_id}")
        data.map {|datum| Replies.new(datum)}
    end

    def child_replies
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies WHERE #{id} = parent_id")
        data.map {|datum| Replies.new(datum)}
    end
end 
class QuestionLike 
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
        data.map {|datum| QuestionLike.new(datum) }
    end
    def self.likers_for_question_id(question)
        data = QuestionsDatabase.instance.execute(<<-SQL, question)
            SELECT 
                *
            FROM 
                question_likes
            WHERE 
                question_id = ? 
        SQL
        data.map {|datum| QuestionLike.new(datum)}
    end
    def self.num_likes_for_question_id(question)
        data = QuestionsDatabase.instance.execute(<<-SQL, question)
        SELECT 
            count(user_id)
        FROM 
            question_likes 
        WHERE 
            question_id = ?
        SQL
        #data.map {|datum| QuestionLike.new(datum)}
    end 
    def self.liked_questions_for_user_id(user)
        data = QuestionsDatabase.instance.execute(<<-SQL, user)
        SELECT 
            question_id
        FROM 
            question_likes
        WHERE 
            user_id = ?
        SQL
    end 
    def initialize(attributes)
        @id = attributes['id']
        @question_id = attributes['question_id']
        @user_id = attributes['user_id']
    end 
    
end 