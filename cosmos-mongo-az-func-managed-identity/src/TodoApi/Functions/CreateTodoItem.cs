using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using MongoDB.Bson;
using Todo.Api.Helpers.Interfaces;
using Todo.Api.Models;

namespace Todo.Api.Functions
{
    public class CreateTodoItem
    {
        private readonly ITodoRepository _todoRepository;
        private readonly ILogger<CreateTodoItem> _logger;

        public CreateTodoItem(ITodoRepository todoRepository, ILogger<CreateTodoItem> logger)
        {
            _todoRepository = todoRepository;
            _logger = logger;
        }

        [FunctionName("CreateTodoItem")]
        public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "todo")] HttpRequest req, ILogger log)
        {
            try
            {
                Console.WriteLine($"C# HTTP trigger request starting for function: {nameof(CreateTodoItem)}");
                string message = await new StreamReader(req.Body).ReadToEndAsync();
                TodoItem todoItem = JsonConvert.DeserializeObject<TodoItem>(message);

                if (todoItem == null)
                {
                    Console.WriteLine($"TodoItem is null in function: {nameof(CreateTodoItem)}");
                    return new BadRequestObjectResult("Todo item is null");
                }

                Console.WriteLine($"calling '_todoRepository.CreateTodoItem' in function: {nameof(CreateTodoItem)}");
                var result = await _todoRepository.CreateTodoItem(todoItem);
                if (result.isSuccess)
                {
                    return new OkObjectResult(todoItem);
                }
                else
                {
                    return new BadRequestObjectResult(result.ErrorMessage);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Exception thrown in {nameof(CreateTodoItem)} Function: {ex.Message}");
                return new StatusCodeResult(StatusCodes.Status500InternalServerError);
            }
        }
    }
}