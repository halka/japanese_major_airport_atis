FROM ruby
ADD . /app
WORKDIR /app
RUN bundle install

CMD ["bundle", "exec", "ruby", "app.rb", "-o", "0.0.0.0"]
