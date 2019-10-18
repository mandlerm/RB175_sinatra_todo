require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = [
    {name: "Lunch Groceries",
      todos: []},
    {name: "Dinner Groceries",
      todos: []}
  ]
  erb :lists, layout: :layout
end
