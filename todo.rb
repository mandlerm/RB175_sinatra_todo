require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  #is_complete?  return boolean if entire list is done
  def is_complete?(list)
    # list_id = id.to_i
    # list = session[:lists].fetch(list_id)
    if list[:todos].size == 0
      false
    else
      list[:todos].all? do |item|
        item[:completed] == true
      end
    end
  end

  #tasks complete  return total tasks marked complete
  def tasks_complete(list)
    completed = list[:todos].select do |item|
      item[:completed] == true
    end.size
  end

  # determine proper class for display in view
  def list_class(list)
    "complete" if is_complete?(list)
  end

  # Sort display order of todo Lists
  def list_sort(lists, &block)
    incomplete_lists = {}
    complete_lists = {}

    complete_lists, incomplete_lists = lists.partition {|list| is_complete?(list)}

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def todo_sort(todos, &block)
    incomplete_todos = {}
    complete_todos = {}

    todos.each_with_index do |todo, index|
      if todo[:completed]
        complete_todos[index] = todo
      else
        incomplete_todos[index] = todo
      end
    end

    incomplete_todos.each { |id, todo| yield todo, id }
    complete_todos.each { |id, todo| yield todo, id }
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View all the lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Display a single ToDo
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists].fetch(@list_id)
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  @list_id = params[:id].to_i
  @list = session[:lists].fetch(@list_id)
  erb :edit_list, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Delete a todo list
post '/lists/:id/destroy' do
  @list_id = params[:id].to_i
  session[:lists].delete_at(@list_id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Add an item to a todo
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists].fetch(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
     session[:error] = error
     erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo added."
    redirect "/lists/#{@list_id}"
  end
end

# delete a specific todo item from a list
post '/lists/:list_id/todos/:id/destroy/' do
  @list_id = params[:list_id].to_i
  @list = session[:lists].fetch(@list_id)

  todo_id = params[:id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."

  redirect "/lists/#{@list_id}"
end

# Update status of a todo
post '/lists/:list_id/todos/:id/' do
  @list_id = params[:list_id].to_i
  @list = session[:lists].fetch(@list_id)

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated."

  redirect "/lists/#{@list_id}"
end

# Mark all todos for a specific list as complete
post '/lists/:list_id/complete_all' do
  @list_id = params[:list_id].to_i
  @list = session[:lists].fetch(@list_id)

  @list[:todos].each do |item|
    item[:completed] = true
  end

  session[:success] = "This list has been updated."

  redirect "/lists/#{@list_id}"
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = session[:lists].fetch(@list_id)

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@list_id}"
  end
end


# Return an error message if name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    session[:error] = "List name must be between 1 and 100 characters"
  elsif session[:lists].any? { |list| list[:name] == name }
    session[:error] = "List name must be unique"
  end
end

# Return an error message if new list item is invalid. Return nil if name is valid.
def error_for_todo(name)
  if !(1..100).cover?(name.size)
    "Todo must be between 1 and 100 characters"
  end
end
