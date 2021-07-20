FROM ruby:3.0.2
ADD . /app
WORKDIR /app
RUN bundle install

CMD ["bundle", "exec", "ruby", "app.rb", "-o", "0.0.0.0"]
