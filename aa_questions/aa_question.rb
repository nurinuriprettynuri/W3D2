require 'sqlite3'
require 'singleton'

class QuestionsDB < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Question
  attr_accessor :title, :body, :user_id

  def initialize(data)
    @id = data['id']
    @title = data['title']
    @body = data['body']
    @user_id = data['user_id']
  end


  def self.all
    data = QuestionsDB.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end


  def self.find_by_author_id(author_id)
    questions = QuestionsDB.instance.execute(<<-SQL, author_id)
        SELECT 
            *
        FROM
            questions    
        WHERE
            user_id = ?
    SQL
    questions.map{|question| Question.new(question)}        
  end

  def followers
      QuestionFollow.followers_for_question_id(id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

end

class User
    attr_accessor :fname, :lname
    attr_reader :id
  
    def initialize(data)
      @id = data['id']
      @fname = data['fname']
      @lname = data['lname']
    end

    def self.all
      data = QuestionsDB.instance.execute("SELECT * FROM users")
      data.map { |datum| User.new(datum) }
    end

    def self.find_by_name(fname, lname)
        user = QuestionsDB.instance.execute(<<-SQL, fname, lname)
            SELECT
                *
            FROM
                users
            WHERE
                fname = ? AND lname = ?
        SQL
        return nil unless user.length > 0
        User.new(user.first)
    end

    def authored_questions
        Question.find_by_author_id(id)
    end

    def follwed_questions
        QuestionFollow.followed_questions_for_user_id(id)
    end

end

class QuestionFollow
    attr_accessor :user_id, :question_id
  
    def initialize(data)
      @id = data['id']
      @user_id = data['user_id']
      @question_id = data['question_id']
    end

    def self.all
      data = QuestionsDB.instance.execute("SELECT * FROM question_follows")
      data.map { |datum| QuestionFollow.new(datum) }
    end

    def self.followers_for_question_id(question_id)
       users = QuestionsDB.instance.execute(<<-SQL, question_id)
            SELECT 
                u.*
            FROM
                users u
            JOIN
                question_follows q
            ON 
                u.id = q.user_id
            WHERE
                q.question_id = ?
        SQL
        # print users
        users.map { |user| User.new(user) }
    end

    def self.followed_questions_for_user_id(user_id)
        questions = QuestionsDB.instance.execute(<<-SQL, user_id)
            SELECT 
               q.*
            FROM
               questions q
            JOIN
                question_follows qf
            ON 
                q.id = qf.question_id
            WHERE
                qf.user_id = ?
        SQL
        questions.map { |question| Question.new(question) }
    end

    def self.most_followed_questions(n)
        questions = QuestionsDB.instance.execute(<<-SQL, n)
            SELECT 
               q.*
            FROM 
                question_follows qf
            JOIN 
                questions q
            ON 
                q.id = qf.question_id
            GROUP BY 
                q.id 
            ORDER BY COUNT(*)
            LIMIT ?
        SQL
        questions.map { |question| Question.new(question) }
    end
end

class Reply
    attr_accessor :question_id, :parent_reply_id, :user_id, :body
  
    def initialize(data)
      @id = data['id']
      @question_id = data['question_id']
      @parent_reply_id = data['parent_reply_id']
      @user_id = data['user_id']
      @body = data['body']
    end

    def self.all
      data = QuestionsDB.instance.execute("SELECT * FROM replies")
      data.map { |datum| Reply.new(datum) }
    end

    def self.find_by_user_id(user_id)
        replies = QuestionsDB.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                replies    
            WHERE
                user_id = ?
        SQL
        replies.map{|re|Reply.new(re)}
    end

    def self.find_by_question_id(question_id)
        replies = QuestionsDB.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                replies    
            WHERE
                question_id = ?
        SQL
        replies.map{|re|Reply.new(re)}
    end

end


# id INTEGER PRIMARY KEY,
#   question_id INTEGER NOT NULL,
#   parent_reply_id INTEGER,
#   user_id INTEGER NOT NULL,
# #   body TEXT NOT NULL,

