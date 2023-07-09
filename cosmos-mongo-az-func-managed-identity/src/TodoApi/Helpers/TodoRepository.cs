using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MongoDB.Driver;
using MongoDB.Bson;
using Todo.Api.Helpers.Interfaces;
using Todo.Api.Models;

namespace Todo.Api.Helpers
{
    public class TodoRepository : ITodoRepository
    {
        private readonly IConfiguration _config;
        private readonly MongoClient _mongoClient;
        private readonly ILogger<TodoRepository> _logger;

        public TodoRepository(MongoClient mongoClient, IConfiguration config, ILogger<TodoRepository> logger)
        {
            _mongoClient = mongoClient;
            _config = config;
            _logger = logger;
        }
        public async Task<(bool isSuccess, string ErrorMessage)> CreateTodoItem(TodoItem todoItem)
        {
            if (todoItem != null)
            {
                try
                {
                    Console.WriteLine($"Getting Database {_config["db"]}");
                    var todoItemDB = _mongoClient.GetDatabase(_config["db"]);

                    Console.WriteLine($"Getting Collection {_config["collection"]}");
                    var _todoItemCollection = todoItemDB.GetCollection<TodoItemEntity>(_config["collection"]);

                    Console.WriteLine($"Generating new Id for TodoItem");

                    // map to entity model
                    TodoItemEntity todoItemEntity = new TodoItemEntity();
                    todoItemEntity.Id = ObjectId.GenerateNewId();
                    todoItemEntity.Title = todoItem.Title;
                    todoItemEntity.IsComplete = todoItem.IsComplete;   
                    
                    Console.WriteLine($"Inserting TodoItem with Id: {todoItemEntity.Id}, Title: {todoItemEntity.Title}, IsComplete: {todoItemEntity.IsComplete}");
                    await _todoItemCollection.InsertOneAsync(todoItemEntity);
                    return (true, null);

                }
                catch (Exception ex)
                {
                    _logger.LogError($"Exception thrown in {nameof(CreateTodoItem)}: {ex.Message}");
                    return (false, ex.Message);
                }
            }
            _logger.LogError($"TodoItem is null in function: {nameof(CreateTodoItem)}");
            return (false, "'TodoItem' is null");
        }
    }
}